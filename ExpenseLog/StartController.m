/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "StartController.h"
#import "ExpenseBrowserController.h"
#import "EditExpenseController.h"
#import "MonthSummaryController.h"
#import "UpgradeController.h"
#import "WaitOverlayView.h"

#import "ExpenseModel.h"
#import "ExpenseItemCell.h"
#import "DateHelper.h"
#import "Utils.h"
#import "Defaults.h"
#import "AdminUtil.h"

@interface StartController () <UITableViewDataSource, UITableViewDelegate, EditExpenseControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, copy, readonly) NSArray *commandCellTitles;
@property (nonatomic, copy, readonly) NSArray *expenseResults;
@property (nonatomic, strong, readwrite) WaitOverlayView *waitView;
@end

@implementation StartController
@synthesize commandCellTitles=_commandCellTitles;
@synthesize expenseResults=_expenseResults;

-(NSArray *)commandCellTitles {
    if (!_commandCellTitles) {
        _commandCellTitles = @[@"New Expense", @"Browse Expenses", @"Year To Date", @"Settings"];
    }
    
    return _commandCellTitles;
}

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

-(NSArray *)expenseResults {
    if (!_expenseResults) {
        // Get recent expenses. (Past 5 days.)
        NSDate *currentDate = dateStrippedTime([NSDate date]);
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = -9;    // One less day because current day is included.
        
        NSDate *startDate = [__getCal() dateByAddingComponents:components toDate:currentDate options:0];
        NSDate *endDate = currentDate;
        
        _expenseResults = [self.ledger queryExpensesFromMinDate:startDate inclMaxDate:endDate dateOrder:ExpenseDateDescending catId:-1];
    }
    return _expenseResults;
}

-(void)clearExpenseResults {
    _expenseResults = nil;
}

-(void)refreshRecentExpenses {
    [self clearExpenseResults];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [ExpenseItemCell registerCellForTableView:self.tableView];
    
    if ([AdminUtil isTestMode]) {
        [self configureTestButtons];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [self refreshRecentExpenses];

    if (self.waitView != nil) {
        [self.waitView removeFromSuperview];
        self.waitView = nil;
    }
    
    [super viewWillAppear:animated];
}

-(void)configureTestButtons {
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectTest:)];
    self.navigationItem.rightBarButtonItem = bbi;
}

-(void)selectTest:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Test Utility" message:@"" delegate:self cancelButtonTitle:@"Cancel"
        otherButtonTitles:@"Reset DB", @"Add test expenses", @"Add test expenses for past year only", @"Set to Lite Version", @"Set to Full Version",
                              nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    alertView.tag = 100;
    [alertView show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100) {
        [self handleAlertViewTestWithButtonIndex:buttonIndex];
    } else if (alertView.tag == 200) {
        [self handleAlertViewUpgradeWithButtonIndex:buttonIndex];
    }
}

-(void)handleAlertViewTestWithButtonIndex:(NSInteger)buttonIndex {
    static long ResetDBFileIndex = 1;
    static long AddTestExpensesIndex = 2;
    static long AddTestExpensesPastYearIndex = 3;
    static long SetToLiteVersionIndex = 4;
    static long SetToFullVersionIndex = 5;
    
    if (buttonIndex == ResetDBFileIndex) {
        [AdminUtil resetExpenseDB];
        [self refreshRecentExpenses];
    } else if (buttonIndex == AddTestExpensesIndex) {
        [AdminUtil addTestExpenses:1000 numPastYears:5];
        [self refreshRecentExpenses];
    } else if (buttonIndex == AddTestExpensesPastYearIndex) {
        [AdminUtil addTestExpenses:1000 numPastYears:1];
        [self refreshRecentExpenses];
    } else if (buttonIndex == SetToLiteVersionIndex) {
        [AdminUtil SetToLiteVersion];
        [self clearExpenseResults];
        [self.tableView reloadData];
    } else if (buttonIndex == SetToFullVersionIndex) {
        [AdminUtil SetToFullVersion];
        [self clearExpenseResults];
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    
    if (section == 0) {
        title = @"Select Action";
    } else {
        title = @"Recent Expenses";
    }
    
    return title;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 44;
    } else {
        return 44;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 22;
    } else {
        return 0;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 0;
    } else {
        return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.commandCellTitles.count;
    } else {
        return self.expenseResults.count;
    }
}

-(BOOL)isFullVersion {
    return [Defaults inst].isFullVersion;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseStartCommandCell = @"StartCommandCell";
    static NSString *reuseNotAvailableCell = @"NotAvailableCell";
    
    UITableViewCell *cell;
    
    long row = indexPath.row;
    if (indexPath.section == 0) {
        if (indexPath.row == 2 && ![self isFullVersion]) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:reuseNotAvailableCell forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell = [self.tableView dequeueReusableCellWithIdentifier:reuseStartCommandCell forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        cell.textLabel.text = self.commandCellTitles[row];
    } else {
        cell = [ExpenseItemCell expenseItemCellForTableView:tableView indexPath:indexPath expenses:self.expenseResults];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self performSegueWithIdentifier:@"showAddExpense" sender:self];
        } else if (indexPath.row == 1) {
            self.waitView = [WaitOverlayView waitOverlayViewInView:self.view];
            [self performSelector:@selector(showExpenseBrowser:) withObject:nil afterDelay:0];
        } else if (indexPath.row == 2 && [self isFullVersion]) {
            self.waitView = [WaitOverlayView waitOverlayViewInView:self.view];
            [self performSelector:@selector(showMonthSummary:) withObject:nil afterDelay:0];
        } else if (indexPath.row == 3) {
            [self performSegueWithIdentifier:@"showSettings" sender:self];
        }
    } else if (indexPath.section == 1) {
        [self performSegueWithIdentifier:@"showEditExpense" sender:self];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 2) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Year To Date" message:@"Available in the Full Version." delegate:self cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Take me to Upgrade Screen", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        alertView.tag = 200;
        [alertView show];
    }
}

-(void)handleAlertViewUpgradeWithButtonIndex:(NSInteger)buttonIndex {
    static long UpgradeToFullVersionIndex = 1;
    
    if (buttonIndex == UpgradeToFullVersionIndex) {
        [Utils pushStoryboardViewID:@"UpgradeController" storyboard:self.storyboard navController:self.navigationController];
    }
}

-(void)showExpenseBrowser:(id)sender {
    [self performSegueWithIdentifier:@"showExpenseBrowser" sender:self];
}

-(void)showMonthSummary:(id)sender {
    [self performSegueWithIdentifier:@"showMonthSummary" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    long selectedRow = self.tableView.indexPathForSelectedRow.row;
    
    if ([segue.identifier isEqualToString:@"showAddExpense"]) {
        EditExpenseController *editExpenseVC = (EditExpenseController *) segue.destinationViewController;
        editExpenseVC.delegate = self;
        editExpenseVC.mode = EditExpenseControllerModeAdd;
    } else if ([segue.identifier isEqualToString:@"showEditExpense"]) {
        EditExpenseController *editExpenseVC = (EditExpenseController *) segue.destinationViewController;
        editExpenseVC.delegate = self;
        Expense *expense = self.expenseResults[selectedRow];
        editExpenseVC.expense = expense;
        editExpenseVC.mode = EditExpenseControllerModeEdit;
    } else if ([segue.identifier isEqualToString:@"showExpenseBrowser"]) {
        ExpenseBrowserController *expenseBrowserVC = (ExpenseBrowserController *) segue.destinationViewController;
        expenseBrowserVC.displayType = [Defaults inst].expenseBrowserDisplayType;
        expenseBrowserVC.customStartDate = [Defaults inst].customStartDate;
        expenseBrowserVC.customEndDate = [Defaults inst].customEndDate;
        expenseBrowserVC.expenseRange = [Defaults inst].expenseRange;
    } else if ([segue.identifier isEqualToString:@"showMonthSummary"]) {
        MonthSummaryController *monthSummaryVC = (MonthSummaryController *)segue.destinationViewController;
        monthSummaryVC.year = [Defaults inst].ytdYear;
    }
}

-(void)popChildControllerAndReload {
    if (self.navigationItem) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self refreshRecentExpenses];
}

-(void)editExpenseController:(EditExpenseController *)sender doneExpense:(Expense *)expense {
    [self popChildControllerAndReload];
}

-(void)deletedExpenseFromEditExpenseController:(EditExpenseController *)sender {
    [self popChildControllerAndReload];
}


@end
