/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "FlexiTableController.h"

typedef enum ExpenseRange {
    ExpenseRangePast10Days=0,
    ExpenseRangePastWeek,
    ExpenseRangePastMonth,
    ExpenseRangePast3Months,
    ExpenseRangePast6Months,
    ExpenseRangePast9Months,
    ExpenseRangePastYear,
    ExpenseRangeCustom
} ExpenseRange;

typedef enum ExpenseBrowserDisplayType {
    ExpenseBrowserDisplayExpenses=0,
    ExpenseBrowserDisplaySubtotals
} ExpenseBrowserDisplayType;

@interface ExpenseBrowserController : FlexiTableController

// Specify the range: n days/weeks/months/years ago.
@property (nonatomic, assign, readwrite) ExpenseRange expenseRange;
@property (nonatomic, copy, readwrite) NSDate *customStartDate;
@property (nonatomic, copy, readwrite) NSDate *customEndDate;
@property (nonatomic, assign, readwrite) BOOL hideSelectOptions;
@property (nonatomic, assign, readwrite) BOOL hideAddButton;

// Specify display to either Expenses or Subtotals.
@property (nonatomic, assign, readwrite) ExpenseBrowserDisplayType displayType;

@end
