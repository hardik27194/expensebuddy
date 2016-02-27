/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "EditExpenseController.h"
#import "DateHelper.h"
#import "Utils.h"

#import "CategorySelectController.h"

@implementation UITextFieldNoCursor

-(CGRect)caretRectForPosition:(UITextPosition *)position {
    return CGRectZero;
}

@end

static int _tagExpenseDateButton = 100;
static int _tagExpenseDatePicker = 200;
static int _tagExpenseName = 300;
static int _tagExpenseAmount = 400;

static int _expenseNameRow = 0;
static int _expenseAmountRow = 1;
static int _categoryRow = 2;
static int _dateButtonRow = 3;
static int _datePickerRow = 4;

@interface EditExpenseController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate, CategorySelectDelegate>
@property (nonatomic, strong, readonly) NSCharacterSet *digitSet;
@property (nonatomic, strong, readonly) NSCharacterSet *decimalPointSet;
@property (nonatomic, strong, readonly) ExpenseLedger *ledger;

@property (nonatomic, assign, readwrite) BOOL showDatePicker;
@property (nonatomic, strong, readwrite) Expense *prevExpense;
@property (nonatomic, strong, readonly) UIColor *highlightColor;

@property (nonatomic, strong, readwrite) NSMutableString *editedAmountStr;

@end

@implementation EditExpenseController
@synthesize digitSet=_digitSet;
@synthesize decimalPointSet=_decimalPointSet;
@synthesize expense=_expense;
@synthesize showDatePicker=_showDatePicker;
@synthesize editedAmountStr=_editedAmountStr;

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

-(void)setExpense:(Expense *)expense {
    _expense = [expense clone];
}

-(UIColor *)highlightColor {
    return [Utils defaultTextHighlightColor];
}

-(NSCharacterSet *)digitSet {
    if (!_digitSet) {
        _digitSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    }
    return _digitSet;
}

-(NSCharacterSet *)decimalPointSet {
    if (!_decimalPointSet) {
        _decimalPointSet = [NSCharacterSet characterSetWithCharactersInString:@"."];
    }
    return _decimalPointSet;
    
}

-(Expense *)expense {
    if (_expense == nil) {
        // Create default Expense record.
        _expense = [[Expense alloc] init];
        _expense.date = [NSDate date];
        _expense.cat = [self.ledger defaultCategory];
    }
    
    return _expense;
}

-(NSMutableString *)editedAmountStr {
    if (_editedAmountStr == nil) {
        _editedAmountStr = [[NSMutableString alloc] init];
        
        long amountNoFraction = (int)floor(self.expense.amount * 100.0f);
        _editedAmountStr = [NSMutableString stringWithFormat:@"%ld", amountNoFraction];
    }
    return _editedAmountStr;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    static NSString *s = @"    Expense Description";
    return s;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 54;
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

-(void)setShowDatePicker:(BOOL)showDatePicker {
    // No changes to table.
    if (showDatePicker == _showDatePicker) {
        return;
    }
    
    _showDatePicker = showDatePicker;
    
    // Clear keyboard when date picker is shown.
    if (_showDatePicker) {
        [self.view endEditing:YES];
    }
    
    NSIndexPath *pickerIndexPath = [NSIndexPath indexPathForRow:_datePickerRow inSection:0];
    NSArray *indexPaths = [NSArray arrayWithObject:pickerIndexPath];
    
    [self.tableView beginUpdates];
    if (_showDatePicker) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    } else {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.tableView endUpdates];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.navigationItem) {
        NSArray *actionButtons;
        UIBarButtonItem *bbiRight = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(selectRight:)];

        if (self.mode == EditExpenseControllerModeEdit || self.mode == EditExpenseControllerModeRead) {
            UIBarButtonItem *bbiDelete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(selectTrash:)];
            actionButtons = [NSArray arrayWithObjects:bbiRight, bbiDelete, nil];
        } else {
            actionButtons = [NSArray arrayWithObject:bbiRight];
        }

        self.navigationItem.rightBarButtonItems = actionButtons;
        [self updateRightButtonState];
        
        if (self.mode == EditExpenseControllerModeAdd) {
            self.navigationItem.title = @"New Expense";
        } else if (self.mode == EditExpenseControllerModeEdit) {
            self.navigationItem.title = @"Edit Expense";
        } else if (self.mode == EditExpenseControllerModeRead) {
            self.navigationItem.title = @"View Expense";
        }
        
    }
    
    // On initial display of expense edit screen, set up previous expense so it can be updated correctly.
    if (self.mode == EditExpenseControllerModeEdit) {
        if (self.expense == nil) {
            [self setMode:EditExpenseControllerModeAdd];
        } else {
            self.prevExpense = [self copyOfExpense];
        }
    }
}

-(BOOL)isExpenseValid {
    if (!self.expense) {
        return false;
    }
    
    if (!self.expense.cat) {
        return false;
    }
    
    if (self.expense.amount <= 0.0f) {
        return false;
    }
    
//    if (self.expense.name.length == 0) {
//        return false;
//    }
    
    return true;
}

-(Expense *)copyOfExpense {
    Expense *newExpense = [[Expense alloc] init];
    newExpense.date = self.expense.date;
    newExpense.name = [self.expense.name copy];
    newExpense.amount = self.expense.amount;
    newExpense.note = self.expense.note? [self.expense.note copy] : @"";
    newExpense.cat = self.expense.cat;
    
    return newExpense;
}

-(void)setMode:(EditExpenseControllerMode)mode {
    if (_mode != mode) {
        // Keep a copy of the old expense when switching from Read to Edit.
        // This is needed in order to do the db record update.
        if (_mode == EditExpenseControllerModeRead && mode == EditExpenseControllerModeEdit && self.expense != nil) {
            self.prevExpense = [self copyOfExpense];
        } else {
            self.prevExpense = nil;
        }
        
        _mode = mode;
        
        self.showDatePicker = NO;
        [self updateRightButtonState];
        [self.tableView reloadData];
    }
}

-(void)selectTrash:(id)sender {
    NSAssert(self.mode != EditExpenseControllerModeAdd, @"Assertion failed: Attempting to delete expense in add mode.");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete this Expense?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    [alertView show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    static long OKIndex = 1;
    
    if (buttonIndex == OKIndex) {
        [self.ledger deleteExpense:self.expense];
        self.expense = nil;
        
        if (self.delegate) {
            [self.delegate deletedExpenseFromEditExpenseController:self];
        }
        
        [self setMode:EditExpenseControllerModeAdd];
    }
}

-(void)selectRight:(id)sender {
    [self.view endEditing:YES];
    
    if (self.mode == EditExpenseControllerModeAdd || self.mode == EditExpenseControllerModeEdit) {
        // Save only when there's a valid expense.
        // If invalid, the button shouldn't have been enabled in the first place so set it right.
        if (![self isExpenseValid]) {
            [self updateRightButtonState];
            return;
        }

        if ([self saveExpenseRecord]) {
            [self.delegate editExpenseController:self doneExpense:self.expense];
            [self setMode:EditExpenseControllerModeRead];
        }
    } else if (self.mode == EditExpenseControllerModeRead) {
        [self setMode:EditExpenseControllerModeEdit];
    }
}

-(void)updateRightButtonState {
    if (!self.navigationItem || !self.navigationItem.rightBarButtonItem) {
        return;
    }
    
    if (self.mode == EditExpenseControllerModeAdd || self.mode == EditExpenseControllerModeEdit) {
        self.navigationItem.rightBarButtonItem.enabled = [self isExpenseValid];
        self.navigationItem.rightBarButtonItem.title = @"Done";
    } else if (self.mode == EditExpenseControllerModeRead) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.rightBarButtonItem.title = @"Edit";
    }
}

-(BOOL)saveExpenseRecord {
    if (self.mode == EditExpenseControllerModeAdd) {
        [self.ledger insertExpense:self.expense];
        return true;
    } else if (self.mode == EditExpenseControllerModeEdit) {
        if (self.prevExpense == nil) {
            NSLog(@"Error: Updating an Expense without prevExpense.");
            return false;
        }
        [self.ledger updatePrevExpense:self.prevExpense withNewExpense:self.expense];
        return true;
    }
    
    return false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    long numRowsWithPicker = _datePickerRow + 1;
    if (self.showDatePicker) {
        return numRowsWithPicker;
    } else {
        return numRowsWithPicker - 1;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseExpenseNameCell = @"ExpenseNameCell";
    static NSString *reuseExpenseAmountCell = @"ExpenseAmountCell";
    static NSString *reuseExpenseCategoryCell = @"ExpenseCategoryCell";
    static NSString *reuseExpenseDateButtonCell = @"ExpenseDateButtonCell";
    static NSString *reuseExpenseDatePickerCell = @"ExpenseDatePickerCell";
    
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        BOOL isEditMode = (self.mode == EditExpenseControllerModeAdd || self.mode == EditExpenseControllerModeEdit);
        
        if (indexPath.row == _expenseNameRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:reuseExpenseNameCell forIndexPath:indexPath];
            
            UITextView *expenseNameTextView = (UITextView *)[cell viewWithTag:_tagExpenseName];
            expenseNameTextView.delegate = self;

            expenseNameTextView.editable = isEditMode;
            if (self.mode != EditExpenseControllerModeAdd) {
                expenseNameTextView.text = self.expense.name;
            }
            
            if (self.mode == EditExpenseControllerModeAdd) {
                [expenseNameTextView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.2f];
            }
        } else if (indexPath.row == _expenseAmountRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:reuseExpenseAmountCell forIndexPath:indexPath];
            
            UITextField *expenseAmountField = (UITextField *)[cell viewWithTag:_tagExpenseAmount];
            expenseAmountField.delegate = self;
            expenseAmountField.enabled = isEditMode;

            [self updateAmountTextField:expenseAmountField];
        } else if (indexPath.row == _categoryRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:reuseExpenseCategoryCell forIndexPath:indexPath];

            if (self.expense.cat) {
                cell.textLabel.font = [UIFont fontWithName:@"System" size:16.0f];
                cell.textLabel.textColor = [UIColor blackColor];
                cell.textLabel.text = [NSString stringWithFormat:@"%@", self.expense.cat.name];
                cell.detailTextLabel.text = @"Select";
                cell.imageView.image = self.expense.cat.icon32;
            } else {
                cell.textLabel.font = [UIFont fontWithName:@"System Italic 16.0" size:14.0f];
                cell.textLabel.textColor = [UIColor grayColor];
                cell.textLabel.text = @"Select Category";
                cell.detailTextLabel.text = @" ";
                cell.imageView.image = nil;
            }
            
            if (isEditMode) {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.detailTextLabel.text = @"";    // No prompt in read mode.
            }
        } else if (indexPath.row == _dateButtonRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:reuseExpenseDateButtonCell forIndexPath:indexPath];
            
            UIButton *expenseDateBtn = (UIButton *)[cell viewWithTag:_tagExpenseDateButton];
            [expenseDateBtn removeTarget:self action:@selector(selectExpenseDateBtn:) forControlEvents:UIControlEventTouchUpInside];
            [expenseDateBtn addTarget:self action:@selector(selectExpenseDateBtn:) forControlEvents:UIControlEventTouchUpInside];

            // Format: E MMM d, yyyy hh:mm aa
            NSString *dateButtonText = [NSString stringWithFormat:@"%@ %@",
                                            dateStringFromDateWithFormat(self.expense.date, @"E"),
                                            dateStringFromDateWithStyle(self.expense.date, NSDateFormatterMediumStyle, NSDateFormatterShortStyle)];
            [expenseDateBtn setTitle:dateButtonText forState:UIControlStateNormal];
        } else if (indexPath.row == _datePickerRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:reuseExpenseDatePickerCell forIndexPath:indexPath];
            UIButton *dateOnlyToggleBtn = (UIButton *)[cell viewWithTag:201];
            [dateOnlyToggleBtn removeTarget:self action:@selector(toggleDateOnlyBtn:) forControlEvents:UIControlEventTouchUpInside];
            [dateOnlyToggleBtn addTarget:self action:@selector(toggleDateOnlyBtn:) forControlEvents:UIControlEventTouchUpInside];
            
            UIDatePicker *expenseDatePicker = (UIDatePicker *)[cell viewWithTag:_tagExpenseDatePicker];
            [expenseDatePicker removeTarget:self action:@selector(changedExpenseDatePicker:) forControlEvents:UIControlEventValueChanged];
            [expenseDatePicker addTarget:self action:@selector(changedExpenseDatePicker:) forControlEvents:UIControlEventValueChanged];
            expenseDatePicker.date = self.expense.date;
            
            expenseDatePicker.enabled = isEditMode;
        }
    }
    
    return cell;
}

-(void)toggleDateOnlyBtn:(UIButton *)sender {
    static NSString *dateOnlyTitle = @"Date Only";
    static NSString *dateAndTimeTitle = @"Date and Time";
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_datePickerRow inSection:0]];
    UIDatePicker *expenseDatePicker = (UIDatePicker *)[cell viewWithTag:_tagExpenseDatePicker];

    if (expenseDatePicker.datePickerMode == UIDatePickerModeDateAndTime) {
        expenseDatePicker.datePickerMode = UIDatePickerModeDate;
        [sender setTitle:dateAndTimeTitle forState:UIControlStateNormal];
    } else {
        expenseDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
        [sender setTitle:dateOnlyTitle forState:UIControlStateNormal];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:true];
    
    self.showDatePicker = false;
    
    if (indexPath.row == _categoryRow) {
        if (self.mode == EditExpenseControllerModeAdd || self.mode == EditExpenseControllerModeEdit) {
            [self performSegueWithIdentifier:@"showCategorySelect" sender:self];
        }
    }
}

-(void)setTableRowBackgroundColor:(UIColor *)color atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = color;
    cell.contentView.backgroundColor = color;
}

-(void)updateExpenseFromTextView:(UITextView *)textView {
    if (textView.tag == _tagExpenseName) {
        self.expense.name = textView.text;
        [self updateRightButtonState];
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView.tag == _tagExpenseName) {
        textView.backgroundColor = [self highlightColor];
        [self setTableRowBackgroundColor:[self highlightColor] atIndexPath:[NSIndexPath indexPathForRow:_expenseNameRow inSection:0]];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    [self updateExpenseFromTextView:textView];

    if (textView.tag == _tagExpenseName) {
        UIColor *bgColor = [UIColor whiteColor];
        textView.backgroundColor = bgColor;
        [self setTableRowBackgroundColor:bgColor atIndexPath:[NSIndexPath indexPathForRow:_expenseNameRow inSection:0]];
    }
}

-(void)textViewDidChange:(UITextView *)textView {
    [self updateExpenseFromTextView:textView];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.showDatePicker = false;

    if (textField.tag == _tagExpenseAmount) {
        textField.backgroundColor = [self highlightColor];
        [self setTableRowBackgroundColor:[self highlightColor] atIndexPath:[NSIndexPath indexPathForRow:_expenseAmountRow inSection:0]];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag == _tagExpenseAmount) {
        [self updateRightButtonState];
        UIColor *bgColor = [UIColor whiteColor];
        textField.backgroundColor = bgColor;
        [self setTableRowBackgroundColor:bgColor atIndexPath:[NSIndexPath indexPathForRow:_expenseAmountRow inSection:0]];
    }
}

-(BOOL)stringHasNonNumericEntry:(NSString *)s {
    if ([s rangeOfCharacterFromSet:self.digitSet].location == NSNotFound) {
        return YES;
    }
    return NO;
}

-(BOOL)stringDigitEntry:(NSString *)s {
    return ![self stringHasNonNumericEntry:s];
}

-(void)updateExpenseAmount {
    double amountVal = [self.editedAmountStr doubleValue];
    amountVal = amountVal / 100.0f;
    self.expense.amount = amountVal;
}

-(void)updateAmountTextField:(UITextField *)amountTextField {
    double amountVal = [self.editedAmountStr doubleValue];
    amountVal = amountVal / 100.0f;
    amountTextField.text = [Utils formattedCurrencyAmount:amountVal];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementStr {
    if (textField.tag == _tagExpenseAmount) {
        // Backspace key.
        if (replacementStr.length == 0 && self.editedAmountStr.length > 0) {
            [self.editedAmountStr deleteCharactersInRange:NSMakeRange(self.editedAmountStr.length-1, 1)];
            
            [self updateAmountTextField:textField];
            [self updateExpenseAmount];
            [self updateRightButtonState];
        }
        
        // Digit entry.
        if ([self stringDigitEntry:replacementStr]) {
            [self.editedAmountStr appendString:replacementStr];

            [self updateAmountTextField:textField];
            [self updateExpenseAmount];
            [self updateRightButtonState];
        }

        return NO;
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showCategorySelect"]) {
        CategorySelectController *categorySelectVC = (CategorySelectController *)segue.destinationViewController;
        categorySelectVC.cat = self.expense.cat;
        categorySelectVC.delegate = self;
        
        NSLog(@"categorySelectVC.delegate = %@", categorySelectVC.delegate);
    }

}

-(void)selectExpenseDateBtn:(id)sender {
    if (self.mode == EditExpenseControllerModeRead) {
        return;
    }
    
    self.showDatePicker = !self.showDatePicker;
}

-(void)changedExpenseDatePicker:(UIDatePicker *)sender {
    self.expense.date = sender.date;
    
    [self updateExpenseDateBtn];
    
}

-(void)updateExpenseDateBtn {
    [self.tableView beginUpdates];
    NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:_dateButtonRow inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

-(void)categorySelectController:(CategorySelectController *)sender doneSelectCategory:(ExpenseCategory *)cat {
    self.expense.cat = cat;
    
    [self.navigationController popViewControllerAnimated:YES];
    
    [self.tableView beginUpdates];
    NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:_categoryRow inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    [self updateRightButtonState];
}

@end
