/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "FlexiTableController.h"
#import "ExpenseModel.h"

@interface UITextFieldNoCursor : UITextField

@end

typedef enum EditExpenseControllerMode {
    EditExpenseControllerModeAdd=0,
    EditExpenseControllerModeRead,
    EditExpenseControllerModeEdit
} EditExpenseControllerMode;

@class EditExpenseController;
@protocol EditExpenseControllerDelegate <NSObject>
-(void)editExpenseController:(EditExpenseController *)sender doneExpense:(Expense *)expense;
@optional
-(void)deletedExpenseFromEditExpenseController:(EditExpenseController *)sender;
@end

@interface EditExpenseController : FlexiTableController
@property (nonatomic, weak, readwrite) id<EditExpenseControllerDelegate> delegate;
@property (nonatomic, strong, readwrite) Expense *expense;
@property (nonatomic, assign, readwrite) EditExpenseControllerMode mode;

@end
