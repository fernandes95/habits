// Gets current date
var currentdate = new Date();
output.day = currentdate.getDate() + ''
output.month = currentdate.getMonth()+1 + ''
output.year = currentdate.getFullYear() + ''

// Weekly habits pick the day after today, as WeekDay raw value (1 is Sunday)
output.tomorrowWeekDay = ((currentdate.getDay() + 1) % 7) + 1 + ''

// Accessibility label of the selected day in the home header, e.g. "27 October 2026"
var months = ["January", "February", "March", "April", "May", "June", "July",
              "August", "September", "October", "November", "December"];
for (var offset = 1; offset <= 3; offset++) {
    var date = new Date(currentdate.getFullYear(), currentdate.getMonth(), currentdate.getDate() + offset);
    output["dayLabel" + offset] = date.getDate() + " " + months[date.getMonth()] + " " + date.getFullYear()
}
