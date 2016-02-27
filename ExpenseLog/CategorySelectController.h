/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "ExpenseModel.h"

@class CategorySelectController;

@protocol CategorySelectDelegate <NSObject>
-(void)categorySelectController:(CategorySelectController *)sender doneSelectCategory:(ExpenseCategory *)cat;
@end

@interface CategorySelectController : UITableViewController
@property (nonatomic, weak, readwrite) ExpenseCategory *cat;
@property (nonatomic, weak, readwrite) id<CategorySelectDelegate> delegate;
@end
