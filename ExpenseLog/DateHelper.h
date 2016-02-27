//
//  DateHelper.h
//  RecordIt
//
//  Created by rob on 4/15/15.
//  Copyright (c) 2015 CAKEsoft. All rights reserved.
//

#ifndef RecordIt_DateHelper_h
#define RecordIt_DateHelper_h

typedef enum {DateRangeTypeDay=0, DateRangeTypeMonth, DateRangeTypeYear} DateRangeType;

NSCalendar *__getCal();

NSString *dateStringFromDateWithFormat(NSDate *date, NSString *dateFormat);
NSString *dateStringFromDateWithStyle(NSDate *date, NSDateFormatterStyle dateStyle, NSDateFormatterStyle timeStyle);
NSDate *dateFromDateStringWithFormat(NSString *dateStr, NSString *dateFormat);

NSDate *dateFromSqlDatetimeString(NSString *dateStr);
NSString *sqlDatetimeStringFromDate(NSDate *date);
NSDate *dateFromSqlDateString(NSString *dateStr);
NSString *sqlDateStringFromDate(NSDate *date);

NSDate *dateFromComponents(int month, int day, int year);
NSDate *datetimeFromComponents(int month, int day, int year, int hour, int minutes);
NSDateComponents *componentsFromDate(NSDate *date);

NSDate *dateStrippedTime(NSDate *date);
NSDate *dateNextDay(NSDate *date);

NSDate *dateMonthFirstDay(NSDate *date);
NSDate *dateMonthLastDay(NSDate *date);
NSDate *datePrevNMonthFirstDay(NSDate *date, int numPrevMonths);

NSDate *dateYearFirstDay(NSDate *date);
NSDate *dateYearLastDay(NSDate *date);
NSDate *datePrevNYearFirstDay(NSDate *date, int numPrevYears);

int daysInMonthDate(NSDate *date);
BOOL isWeekend(NSDate *date);
int dayOfWeekFromDate(NSDate *date);   // 1=Sunday, 2=Monday,... 7=Saturday
NSDate *datePrevSunday(NSDate *date);

NSDate* randomDatetime(int numPastYearsRange);
NSDate *randomDate(int numPastYearsRange);

#endif
