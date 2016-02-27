/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "FlexiTableController.h"
#import "ExpenseModel.h"

@class ExpenseResultsController;
@interface ExpenseResultsController : FlexiTableController
@property (nonatomic, copy, readwrite) NSDate *startDate;
@property (nonatomic, copy, readwrite) NSDate *endDate;
@property (nonatomic, weak, readwrite) ExpenseCategory *cat;

@end
