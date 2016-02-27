/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "FlexiTableController.h"

@class DateRangeSelectController;
@protocol DateRangeSelectControllerDelegate <NSObject>
-(void)dateRangeSelectController:(DateRangeSelectController *)sender doneStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;
@end

@interface DateRangeSelectController : FlexiTableController
@property (nonatomic, weak, readwrite) id<DateRangeSelectControllerDelegate> delegate;
@property (nonatomic, copy, readwrite) NSDate *startDate;
@property (nonatomic, copy, readwrite) NSDate *endDate;

@end
