/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

@class YearSelectController;

@protocol YearSelectControllerDelegate <NSObject>
-(void)yearSelectController:(YearSelectController *)sender doneSelectYear:(int)year;
@end

@interface YearSelectController : UITableViewController
@property (nonatomic, weak, readwrite) id<YearSelectControllerDelegate> delegate;
@property (nonatomic, copy, readwrite) NSArray *years;
@property (nonatomic, assign, readwrite) int selYear;

@end
