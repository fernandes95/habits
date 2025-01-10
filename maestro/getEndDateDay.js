Date.prototype.addDays = function(days) {
    var date = new Date(this.valueOf());
    date.setDate(date.getDate() + days);
    return date;
}

// Maestro Env parameter must be parsed if not string
const counter = Number(endDayCounter);

var date = new Date();
var currentMonth = date.getMonth()+1;
var newDate = date.addDays(counter);
var updatedMonth = newDate.getMonth()+1;

output.newHabitEndDay = newDate.getDate() + ''
output.isNewHabitEndDaySameMonth = currentMonth == updatedMonth
 