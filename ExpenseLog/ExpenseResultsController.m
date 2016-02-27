/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "ExpenseResultsController.h"
#import "ExpenseItemCell.h"
#import "EditExpenseController.h"
#import "WaitOverlayView.h"

#import "ExpenseModel.h"
#import "Utils.h"
#import "DateHelper.h"

@interface ExpenseResultsController () <UITableViewDataSource, UITableViewDelegate, EditExpenseControllerDelegate>
@property (nonatomic, copy, readonly) NSArray *expenseResults;
@property (nonatomic, weak, readonly) ExpenseLedger *ledger;
@property (nonatomic, strong, readwrite) WaitOverlayView *waitView;

@end

@implementation ExpenseResultsController
@synthesize expenseResults=_expenseResults;

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

-(NSArray *)expenseResults {
    if (!_expenseResults) {
        _expenseResults = [self.ledger queryExpensesFromMinDate:self.startDate inclMaxDate:self.endDate dateOrder:ExpenseDateDescending catId:self.cat.id];
    }
    return _expenseResults;
}

-(void)clearExpenseResults {
    _expenseResults = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [ExpenseItemCell registerCellForTableView:self.tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *catName;
    if (self.cat != nil) {
        catName = self.cat.name;
    } else {
        catName = @"Expenses";
    }
    
    NSString *s = [NSString stringWithFormat:@"%@: %@ to %@", catName,
                          dateStringFromDateWithStyle(self.startDate, NSDateFormatterShortStyle, NSDateFormatterNoStyle),
                          dateStringFromDateWithStyle(self.endDate, NSDateFormatterShortStyle, NSDateFormatterNoStyle)];
    return s;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 54;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 50;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    TotalQtyAmount qtyAmount = [self.ledger queryTotalExpenseAmountForStartDate:self.startDate inclEndDate:self.endDate catId:self.cat.id];
    return [NSString stringWithFormat:@"Total Expenses: %@", [Utils formattedCurrencyAmount:qtyAmount.amount]];
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

-(NSArray *)expenseResultsShownForCategory:(ExpenseCategory *)cat {
    NSArray *expensesForCategory = [self.ledger queryExpensesFromMinDate:self.startDate inclMaxDate:self.endDate dateOrder:ExpenseDateDescending catId:cat.id];
    return expensesForCategory;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.expenseResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExpenseItemCell *cell = [ExpenseItemCell expenseItemCellForTableView:tableView indexPath:indexPath expenses:self.expenseResults];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    long selectedRow = self.tableView.indexPathForSelectedRow.row;
    
    if ([segue.identifier isEqualToString:@"showEditExpense"]) {
        EditExpenseController *editExpenseVC = segue.destinationViewController;
        Expense *expense = self.expenseResults[selectedRow];
    
        editExpenseVC.delegate = self;
        editExpenseVC.expense = expense;
        editExpenseVC.mode = EditExpenseControllerModeEdit;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showEditExpense" sender:self];
}

-(void)popChildControllerAndReload {
    if (self.navigationItem) {
        [self.navigationController popViewControllerAnimated:YES];
    }

    [self clearExpenseResults];
    [self.tableView reloadData];
}

-(void)editExpenseController:(EditExpenseController *)sender doneExpense:(Expense *)expense {
    [self popChildControllerAndReload];
}

-(void)deletedExpenseFromEditExpenseController:(EditExpenseController *)sender {
    [self popChildControllerAndReload];
}

-(void)viewWillAppear:(BOOL)animated {
    if (self.waitView != nil) {
        [self.waitView removeFromSuperview];
        self.waitView = nil;
    }
    
    [super viewWillAppear:animated];
}

@end
