/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "ExpenseBrowserController.h"

@class RangeSelectController;
@protocol RangeSelectControllerDelegate <NSObject>
-(void)rangeSelectController:(RangeSelectController *)sender doneExpenseRange:(ExpenseRange)expenseRange customStartDate:(NSDate *)customStartDate customEndDate:(NSDate *)customEndDate;

@end

@interface RangeSelectController : UITableViewController
@property (nonatomic, weak, readwrite) id<RangeSelectControllerDelegate> delegate;
@property (nonatomic, assign, readwrite) ExpenseRange expenseRange;
@property (nonatomic, copy, readwrite) NSDate *customStartDate;
@property (nonatomic, copy, readwrite) NSDate *customEndDate;

@end
