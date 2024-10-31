/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

var _month = 12;
var _day = 19;
var _year = 2012;
var _hour = 9;
var _dateObject = new Date(_year,_month,_day,0,0,0,0);

var _difference = new Date();

// Simply return todays date.
var _todaysDate = new Date();

function StartTimer()
{
    // Find the difference in time and then output the difference.
    _difference = (_dateObject - _todaysDate);
    
    setTimeout('StartTimer',1000);
}

