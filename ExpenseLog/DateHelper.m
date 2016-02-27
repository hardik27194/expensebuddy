//
//  DateHelper.m
//  RecordIt
//
//  Created by rob on 4/15/15.
//  Copyright (c) 2015 CAKEsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSCalendar *__cal = nil;
NSCalendar *__getCal() {
    return [NSCalendar currentCalendar];
}

NSDateFormatter *__getDateFormatter() {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    return dateFormatter;
}

NSDate *dateFromDateStringWithFormat(NSString *dateStr, NSString *dateFormat) {
    NSDateFormatter *dateFormatter = __getDateFormatter();
    dateFormatter.dateFormat = dateFormat;
    return [dateFormatter dateFromString:dateStr];
}

NSString *dateStringFromDateWithFormat(NSDate *date, NSString *dateFormat) {
    NSDateFormatter *dateFormatter = __getDateFormatter();
    dateFormatter.dateFormat = dateFormat;
    return [dateFormatter stringFromDate:date];
}

NSDate *dateFromSqlDatetimeString(NSString *dateStr) {
    return dateFromDateStringWithFormat(dateStr, @"yyyy-MM-dd HH:mm:ss");
}

NSString *sqlDatetimeStringFromDate(NSDate *date) {
    return dateStringFromDateWithFormat(date, @"yyyy-MM-dd HH:mm:ss");
}

NSDate *dateFromSqlDateString(NSString *dateStr) {
    return dateFromDateStringWithFormat(dateStr, @"yyyy-MM-dd");
}

NSString *sqlDateStringFromDate(NSDate *date) {
    return dateStringFromDateWithFormat(date, @"yyyy-MM-dd");
}

NSDate *dateFromComponents(int month, int day, int year) {
    return dateFromSqlDateString([NSString stringWithFormat:@"%04d-%02d-%02d", year, month, day]);
}

NSDate *datetimeFromComponents(int month, int day, int year, int hour, int minutes) {
    return dateFromSqlDatetimeString([NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:00", year, month, day, hour, minutes]);
}

NSString *dateStringFromDateWithStyle(NSDate *date, NSDateFormatterStyle dateStyle, NSDateFormatterStyle timeStyle) {
    NSDateFormatter *dateFormatter = __getDateFormatter();
    dateFormatter.locale = [NSLocale currentLocale];
    dateFormatter.dateStyle = dateStyle;
    dateFormatter.timeStyle = timeStyle;
    return [dateFormatter stringFromDate:date];
}

NSDateComponents *componentsFromDate(NSDate *date) {
    NSDateComponents *components = [__getCal() components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                 fromDate:date];
    return components;
}

// Return date with time components stripped out. Useful for queries involving dates.
NSDate *dateStrippedTime(NSDate *date) {
    NSCalendar *cal = __getCal();
    NSDateComponents *components = [cal components:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear fromDate:date];
    return [cal dateFromComponents:components];

//    NSDateComponents *components = componentsFromDate(date);
//    return dateFromComponents((int)components.month, (int)components.day, (int)components.year);
}

// Return date + 1 day. Useful for queries involving date ranges.
NSDate *dateNextDay(NSDate *date) {
    date = dateStrippedTime(date);

    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    
    NSDate *nextDayDate = [__getCal() dateByAddingComponents:dayComponent toDate:date options:0];
    return nextDayDate;
}

NSDate *dateMonthFirstDay(NSDate *date) {
    date = dateStrippedTime(date);
    
    NSCalendar *cal = __getCal();
    NSDateComponents *components = [cal components:NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    return [cal dateFromComponents:components];
}

NSDate *dateMonthLastDay(NSDate *date) {
    NSCalendar *cal = __getCal();
    
    NSDateComponents *monthComponent = [[NSDateComponents alloc] init];
    monthComponent.month = 1;
    NSDate *firstDayOfNextMonth = [cal dateByAddingComponents:monthComponent toDate:dateMonthFirstDay(date) options:0];
    
    NSDateComponents *prevDayComponent = [[NSDateComponents alloc] init];
    prevDayComponent.day = -1;
    NSDate *lastDayOfMonth = [cal dateByAddingComponents:prevDayComponent toDate:firstDayOfNextMonth options:0];
    
    return lastDayOfMonth;
}

NSDate *datePrevNMonthFirstDay(NSDate *date, int numPrevMonths) {
    date = dateMonthFirstDay(date);
    numPrevMonths--;    // Less 1 because the current month is included in the count.
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.month = -numPrevMonths;
    
    NSDate *retDate = [__getCal() dateByAddingComponents:components toDate:date options:0];
    return retDate;
}

NSDate *dateYearFirstDay(NSDate *date) {
    NSDateComponents *components = componentsFromDate(date);
    return dateFromComponents(1, 1, (int)components.year);
}

NSDate *dateYearLastDay(NSDate *date) {
    NSDateComponents *components = componentsFromDate(date);
    return dateFromComponents(12, 31, (int)components.year);
}

NSDate *datePrevNYearFirstDay(NSDate *date, int numPrevYears) {
    numPrevYears--;     // Less 1 because current year is already included.
    
    NSDateComponents *components = componentsFromDate(date);
    return dateFromComponents(1, 1, (int)components.year - numPrevYears);
}

int daysInMonthDate(NSDate *date) {
    NSRange range = [__getCal() rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    return (int) range.length;
}

BOOL isWeekend(NSDate *date) {
    NSCalendar *cal = __getCal();
    NSRange weekRange = [cal maximumRangeOfUnit:NSCalendarUnitWeekday];
    long weekdayNum = [cal component:NSCalendarUnitWeekday fromDate:date];
    
    // Check if Sunday (first day) or Saturday (last day).
    if (weekdayNum == weekRange.location || weekdayNum == weekRange.length) {
        return true;
    } else {
        return false;
    }
}

int dayOfWeekFromDate(NSDate *date) {
    return (int)[__getCal() component:NSCalendarUnitWeekday fromDate:date];
}

NSDate *datePrevSunday(NSDate *date) {
    date = dateStrippedTime(date);
    int currentDayOfWeek = dayOfWeekFromDate(date);
    int daysFromSunday = currentDayOfWeek-1;    // Ex. if today is Sunday (currentDayOfWeek==1), there are 0 days from Sunday.
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = -daysFromSunday;
    return [__getCal() dateByAddingComponents:components toDate:date options:0];
}

int _randN(int min, int max) {
    return arc4random_uniform(max - min + 1) + min;
}

NSDate* randomDatetime(int numPastYearsRange) {
    // Generate any random date within the past numPastYearsRange.
    int maxPrevYears = numPastYearsRange;

    int numPrevDays = _randN(0, maxPrevYears * 365);
    int numPrevMinutes = _randN(0, 60*24);
    NSDateComponents *deltaDateComponent = [[NSDateComponents alloc] init];
    deltaDateComponent.day = -numPrevDays;
    deltaDateComponent.minute = -numPrevMinutes;
    
    return [__getCal() dateByAddingComponents:deltaDateComponent toDate:[NSDate date] options:0];
}

NSDate *randomDate(int numPastYearsRange) {
    return dateStrippedTime(randomDatetime(numPastYearsRange));
}
