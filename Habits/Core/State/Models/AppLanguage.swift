//
//  AppLanguage.swift
//  Habits
//
//  Created by Tiago Fernandes on 26/10/2026.
//

import SwiftUI

/// Language the app is shown in, picked in the settings
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english, portuguese, portugueseBrazil
    var id: String { rawValue }

    /// Locale applied to the whole app, it keeps the device region so only the language changes
    var locale: Locale {
        switch self {
        case .system: return .autoupdatingCurrent
        case .english: return Locale(languageCode: .english, languageRegion: Locale.current.region)
        case .portuguese: return Locale(languageCode: .portuguese, languageRegion: .portugal)
        case .portugueseBrazil: return Locale(languageCode: .portuguese, languageRegion: .brazil)
        }
    }

    /// Each language is named in itself, so it can be found whatever language the app is in
    var name: Text {
        switch self {
        case .system: return Text("settings_language_system_title")
        case .english: return Text(verbatim: "English")
        case .portuguese: return Text(verbatim: "Português (Portugal)")
        case .portugueseBrazil: return Text(verbatim: "Português (Brasil)")
        }
    }
}
