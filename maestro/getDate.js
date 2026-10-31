// Gets current date
var currentdate = new Date();
output.day = currentdate.getDate() + ''
output.month = currentdate.getMonth()+1 + ''
output.year = currentdate.getFullYear() + ''

// Weekly habits pick only the day after today, as WeekDay raw value (1 is Sunday)
output.todayWeekDay = currentdate.getDay() + 1 + ''
output.tomorrowWeekDay = ((currentdate.getDay() + 1) % 7) + 1 + ''

// Accessibility label of the selected day in the week view header, e.g. "27 October 2026", 0 is today
var months = ["January", "February", "March", "April", "May", "June", "July",
              "August", "September", "October", "November", "December"];
for (var offset = 0; offset <= 3; offset++) {
    var date = new Date(currentdate.getFullYear(), currentdate.getMonth(), currentdate.getDate() + offset);
    output["dayLabel" + offset] = date.getDate() + " " + months[date.getMonth()] + " " + date.getFullYear()
}
