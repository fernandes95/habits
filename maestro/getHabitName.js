// Creates habit name based on current date & time
var currentdate = new Date(); 
var name = "Habit " + currentdate.getDate() + "/"
                + (currentdate.getMonth()+1)  + "/" 
                + currentdate.getFullYear() + "-"  
                + currentdate.getHours() + ":"  
                + currentdate.getMinutes() + ":" 
                + currentdate.getSeconds();
output.habitName = this.name