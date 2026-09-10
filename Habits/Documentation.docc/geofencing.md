# Geofencing & Location — How It Works

> A plain-language guide to how this app reminds you about a habit when you
> arrive at a place. Read this first if you're coming back to the code after
> a while and need to remember what does what before changing anything.

---

## 1. The big idea in one paragraph

A habit can have a **location** attached to it (e.g. "workout" → your gym). The
app draws an invisible circle (a **geofence**, radius **100 m**) around that
place. When your phone crosses into that circle, iOS wakes the app — even if
it's closed — and the app fires a local notification: *"Don't forget to:
workout."* When you complete the habit and leave, the app stops watching that
circle for the rest of the day.

That's the whole product. Everything below is the plumbing that makes it work
reliably, including when the app is fully closed.

---

## 2. The cast of characters (which file does what)

| File | Role | One-line summary |
|------|------|------------------|
| `AppDelegate.swift` | **Background entry point** | Runs the moment the app launches (including when iOS relaunches it for a geofence). Kicks off monitoring. |
| `HabitsApp.swift` | **UI entry point** | The SwiftUI `@main`. When the UI appears, it runs `initHabits()`. |
| `AppEnvironment.swift` | **Wiring / DI** | Builds the three services once and holds them. Has `regionMonitoring()`. |
| `MainState.swift` | **UI brain** | View model. Loads habits, asks for permissions, and starts/stops monitoring when you add/edit/delete a habit. |
| `RegionServiceImpl.swift` | **The geofencing engine** | Owns `CLMonitor`. Adds/removes circles, listens for enter/exit events, decides whether to notify. This is the heart. |
| `LocationService.swift` | **Location + permissions** | Wraps `CLLocationManager`. Handles permission prompts and one-off location fixes, and forwards them to the engine. |
| `NotificationService.swift` | **Notifications** | Builds and schedules the actual local notifications. |
| `HabitsService(+Notifications)` | **Data** | Stores habits and remembers which habits were *already notified today* (so we don't spam). |

**Mental model:** `MainState` and the UI sit on top. `LocationService`
handles *permissions and where you are*. `RegionServiceImpl` handles *the
circles and the reminders*. `NotificationService` handles *the ping*.

---

## 3. The core engine: `RegionServiceImpl`

This is the one file to understand well. It holds three long-lived things:

- **`CLMonitor` (named `"MonitorID"`)** — Apple's modern geofence object
  (iOS 17+). It holds all the circles and produces a stream of enter/exit
  events. We keep a **single** monitor and reuse it (never create/discard it
  repeatedly — that corrupts its state).
- **`serviceSession` (`CLServiceSession`)** — the permission "keep-alive". On
  iOS 18+ the event stream goes silent when the app isn't in use *unless* a
  session asserts we still care. See quirks (§7).
- **`eventTask`** — a long-running `Task` that sits in a loop reading events
  from the monitor and reacting to them.

### What its methods do

- **`startMonitoringIfAuthorized()`** — the "turn everything on" method. It:
  1. creates the `CLServiceSession(.always)` if we don't have one,
  2. starts the `eventTask` loop (if not already running),
  3. calls `manageRegions()` to sync the circles.

- **`consumeEvents(_:)`** — the event loop. For every event from the monitor:
  - `.satisfied` → you **entered** a circle → `remindUser(id:)`.
  - `.unsatisfied` → you **exited** a circle → if the habit is already checked
    off today, stop monitoring it (`validateRegion` → `stopMonitoringRegion`).
  - If the loop ever ends, monitoring is effectively dead until the next app
    launch (there's a log line for this).

- **`monitorRegion(center:habitIdentifier:habitName:)`** — start watching one
  circle. It **removes first, then adds**, because `CLMonitor.add` won't update
  an existing condition. The circle's identifier is the **habit's UUID**.

- **`stopMonitoringRegion(...)`** — remove one circle by habit UUID.

- **`manageRegions()`** — the **reconciler**. Compares "circles currently being
  watched" against "habits that have a location and are active today", then
  adds what's missing and removes what's stale. Run on every launch so the set
  of circles always matches today's habits.

- **`checkAlreadyInsideRegion(currentLocation:)`** — the **safety net**. Given a
  fresh GPS fix, it manually measures distance to each habit's location and, if
  you're already inside a circle, reminds you directly — without waiting for an
  enter event. This exists because iOS sometimes doesn't deliver the enter
  event on a background relaunch (§7).

- **`remindUser(id:)`** — the **gatekeeper** before any notification. In order,
  it bails out if:
  1. the habit no longer exists → stop monitoring it,
  2. the habit's end date is in the past → it's finished, stop monitoring it,
  3. the habit is already checked off today → no reminder needed,
  4. the habit was already notified today → don't notify twice.
  Only if all four pass does it fire the notification and record that the habit
  was notified.

---

## 4. Flow A — App is CLOSED (the background entry point)

This is the important one: the app is not running, and iOS relaunches it
because you walked into a circle (or just because the app was started).

```
You cross into a geofence  (or the app is launched)
        │
        ▼
AppDelegate.didFinishLaunchingWithOptions          ← iOS starts the app here
        │
        ▼
AppEnvironment.shared.regionMonitoring()
        │
        ├─ 1. habitsService.load()                 ← get today's habits
        │
        ├─ 2. regionService.startMonitoringIfAuthorized()
        │        ├─ create CLServiceSession(.always)   ← keeps events alive
        │        ├─ start eventTask (listen for enter/exit)
        │        └─ manageRegions()                     ← re-add today's circles
        │
        └─ 3. locationService.requestOneTimeLocation()  ← ask "where am I?"
                    │
                    ▼
        LocationService.didUpdateLocations (fix arrives)
                    │
                    ▼
        regionService.checkAlreadyInsideRegion(fix)     ← safety net
                    │
                    ▼
        remindUser(id:) ──► NotificationService ──► 🔔
```

**Two ways a reminder can fire in this flow:**

1. **The normal path** — the geofence enter event arrives through `eventTask`
   → `consumeEvents` sees `.satisfied` → `remindUser`.
2. **The safety-net path** — the enter event *doesn't* arrive (an iOS quirk on
   relaunch), but the one-time location fix shows you're inside a circle →
   `checkAlreadyInsideRegion` → `remindUser`.

Both funnel through `remindUser`, so its four guards (§3) make sure you get
**at most one** reminder per habit per day regardless of which path fired.

---

## 5. Flow B — App is OPEN (the UI entry point)

This covers first launch, granting permissions, and creating/editing habits.

```
HabitsApp body → .task { state.initHabits() }
        │
        ▼
MainState.initHabits()
        ├─ load habits
        └─ requestLocationAuthorizationIfNeeded() → requestOneTimeLocation()

--- First run: permission prompts ---

UI asks for permission (MainState.requestLocation / requestAlwaysLocation)
        │
        ▼
LocationService.locationManagerDidChangeAuthorization
        ├─ .authorizedWhenInUse → wait 0.5s → ask for "Always"   ← escalation
        └─ .authorizedAlways    → allowsBackgroundLocationUpdates = true
                                 → requestOneTimeLocation()
                                 → startMonitoringIfAuthorized()  ← engine on

--- Creating / editing / deleting a habit with a location ---

MainState.addHabit / updateHabit / removeHabit
        │
        ▼
LocationService.startMonitoringRegion / stopMonitoringRegion
        │
        ▼
RegionServiceImpl.monitorRegion / stopMonitoringRegion
        │
        ▼
CLMonitor.add / remove   (the circle is now watched, or gone)
```

While the app is open and you physically cross a boundary, the same
`eventTask` → `consumeEvents` → `remindUser` path fires the reminder.

**Permission escalation is deliberate:** iOS won't let you ask for "Always"
directly in a good way, so the app asks for "When In Use" first, then bumps up
to "Always" shortly after. **Background geofencing only works with "Always."**

---

## 6. What happens when you complete a habit

- You check the habit off for the day.
- Next time you **exit** its circle, `consumeEvents` sees `.unsatisfied`,
  `validateRegion` confirms it's checked, and the circle is **removed** for now.
- `remindUser`'s guards also prevent a reminder if the habit is already checked
  or was already notified today — so a completed habit stays quiet.
- On the next app launch, `manageRegions()` re-adds circles for habits that are
  active again, so tomorrow it watches the right set.

---

## 7. iOS quirks to keep in mind (this is where the bugs hide)

These are the non-obvious platform behaviors this code is built around. If
something "randomly" breaks, start here.

1. **`CLServiceSession` is mandatory (iOS 18+, incl. iOS 26).**
   Without an active session, `CLMonitor.events` stops delivering the moment
   the app is "not in use". The session does **not** survive the app being
   killed, so we recreate it on *every* launch inside
   `startMonitoringIfAuthorized()`. If you ever remove that line, background
   reminders silently die.

2. **Enter events can be dropped on a background relaunch; exit events are
   reliable.** On current iOS, when the app is relaunched from a killed state,
   the "you entered" event is sometimes suppressed until the app is
   foregrounded, while "you exited" comes through fine. **This is why
   `checkAlreadyInsideRegion` exists** — it's the workaround, not redundant
   code. Don't delete it.

3. **"Always" permission is required for background.** "When In Use" is not
   enough once the app is closed. Hence the WhenInUse → Always escalation.

4. **`allowsBackgroundLocationUpdates = true` + Background Modes.** We set the
   flag when we get Always, and `Info.plist` declares the `location` background
   mode. Both are needed for the app to run location code in the background.

5. **20-geofence limit per app.** iOS won't monitor more than 20 regions for a
   single app at once. This app is fine today, but if you ever have more than
   20 location-habits active, you'll need a strategy (e.g. only monitor the 20
   nearest). `manageRegions()` is where you'd add that.

6. **`assuming: .unsatisfied` when adding a circle.** This tells the monitor to
   assume you start *outside*, so you don't get a fake "entered" event the
   instant a circle is added while you happen to be standing inside it.

7. **`CLMonitor.add` does not update an existing condition.** That's why
   `monitorRegion` removes before it adds. If you skip the remove, edits to a
   habit's location won't take effect.

8. **Never create/discard the monitor repeatedly.** We cache one `CLMonitor`
   under the name `"MonitorID"` via `monitorTask`. Re-creating monitors with
   the same name can corrupt their state.

9. **Delivery is not instant.** Geofence crossings can take up to a couple of
   minutes to register, and can be flaky in poor signal. Don't treat a missed
   ping in testing as necessarily a code bug — test with real movement on a
   real device.

10. **The "instant" notification isn't truly instant.** `requestInstantNotification`
    schedules a notification 5 seconds out via a time-interval trigger. That's
    normal and fine; just don't expect a zero-delay ping.

11. **`NSLocationRequireExplicitServiceSession = true` in `Info.plist`.** This
    makes the session requirement explicit so a missing session fails loudly in
    testing instead of silently dropping events in production.

---

## 8. Minor things worth a note (not bugs, just "huh?")

- In `manageRegions()`, the line
  `guard !allHabits.isEmpty || habits.isEmpty else { return }` describes a
  state that can't actually happen (a filtered subset can't be non-empty when
  the full list is empty), so it never returns early. Harmless, but confusing —
  simplify it if you touch that method.

- `didRunInitialInsideCheck` is a per-launch flag: the safety-net inside-check
  runs **once per app process**. Because each background relaunch is a fresh
  process, this is the intended behavior — it re-arms on every launch.

- `didUpdateLocations` deliberately ignores unusable fixes (accuracy worse than
  200 m, or older than 60 s) so the one-shot inside-check isn't "spent" on a
  garbage location.

- `BackgroundTaskService` / the `fetch` background mode /
  `BGTaskSchedulerPermittedIdentifiers` are not part of geofencing. Background
  tasks don't help geofence delivery and can interfere with the session — the
  `CLServiceSession` is the correct mechanism.

---

## 9. Quick "where do I change X?" cheat sheet

| I want to… | Go to |
|------------|-------|
| Change the circle size (currently 100 m) | `AppEnvironment` (`regionRadius: 100`) and `LocationService.regionRadius` |
| Change what the reminder says | `RegionServiceImpl.remindUser` → `requestInstantNotification` |
| Change *when* we suppress a reminder | `RegionServiceImpl.remindUser` (the four guards) |
| Change which habits get watched | `RegionServiceImpl.manageRegions` |
| Change permission behavior | `LocationService.locationManagerDidChangeAuthorization` |
| Add the >20 geofence strategy | `RegionServiceImpl.manageRegions` |
| Start/stop watching on habit changes | `MainState.addHabit / updateHabit / removeHabit` |
