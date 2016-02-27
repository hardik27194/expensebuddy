/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "ExpenseBrowserController.h"
#import "EditExpenseController.h"
#import "RangeSelectController.h"
#import "BrowserDisplaySelectController.h"
#import "ExpenseResultsController.h"
#import "WaitOverlayView.h"

#import "ExpenseItemCell.h"
#import "CategorySummaryItemCell.h"
#import "ExpenseModel.h"
#import "DateHelper.h"
#import "Utils.h"
#import "Defaults.h"

@interface ExpenseBrowserController () <UITableViewDataSource, UITableViewDelegate, EditExpenseControllerDelegate, RangeSelectControllerDelegate,
    BrowserDisplaySelectControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate> {
}
@property (nonatomic, copy, readwrite) NSDate *startDate;
@property (nonatomic, copy, readwrite) NSDate *endDate;
@property (nonatomic, copy, readonly) NSArray *rangeSelectNames;

@property (nonatomic, weak, readonly) ExpenseLedger *ledger;
@property (nonatomic, copy, readonly) NSArray *expenseResults;
@property (nonatomic, copy, readonly) NSArray *categorySummariesResults;
@property (nonatomic, strong, readwrite) WaitOverlayView *waitView;

@end

@implementation ExpenseBrowserController
@synthesize displayType=_displayType;
@synthesize startDate=_startDate;
@synthesize endDate=_endDate;
@synthesize rangeSelectNames=_rangeSelectNames;
@synthesize expenseResults=_expenseResults;
@synthesize categorySummariesResults=_categorySummariesResults;

-(void)setDisplayType:(ExpenseBrowserDisplayType)displayType {
    _displayType = displayType;
    
    [self clearExpenseResults];
}

-(ExpenseBrowserDisplayType)displayType {
    return _displayType;
}

-(void)configureStartEndDateNMonthsAgo:(int)nMonthsAgo {
    NSDate *currentDate = dateStrippedTime([NSDate date]);
    
    self.startDate = datePrevNMonthFirstDay(currentDate, nMonthsAgo);
    self.endDate = currentDate;
}

-(void)configureStartEndDateNYearsAgo:(int)nYearsAgo {
    NSDate *currentDate = dateStrippedTime([NSDate date]);
    
    self.startDate = datePrevNYearFirstDay(currentDate, nYearsAgo);
    self.endDate = currentDate;
}

-(void)setExpenseRange:(ExpenseRange)expenseRange {
    _expenseRange = expenseRange;
    switch (_expenseRange) {
        case ExpenseRangePastWeek: {
            NSDate *currentDate = dateStrippedTime([NSDate date]);
            self.startDate = datePrevSunday(currentDate);
            self.endDate = currentDate;
            return;
        }
        case ExpenseRangePastMonth:
            [self configureStartEndDateNMonthsAgo:1];
            break;
        case ExpenseRangePast3Months:
            [self configureStartEndDateNMonthsAgo:3];
            break;
        case ExpenseRangePast6Months:
            [self configureStartEndDateNMonthsAgo:6];
            break;
        case ExpenseRangePast9Months:
            [self configureStartEndDateNMonthsAgo:9];
            break;
        case ExpenseRangePastYear:
            [self configureStartEndDateNYearsAgo:1];
            break;
        case ExpenseRangePast10Days: {
            NSDate *currentDate = dateStrippedTime([NSDate date]);
            NSDateComponents *components = [[NSDateComponents alloc] init];
            components.day = -9;    // One less day because current day is included.
            
            self.startDate = [__getCal() dateByAddingComponents:components toDate:currentDate options:0];
            self.endDate = currentDate;
            break;
        }
        case ExpenseRangeCustom:
            self.startDate = self.customStartDate;
            self.endDate = self.customEndDate;
        default:
            NSAssert(true, @"Invalid expenseRange %d set.", expenseRange);
            return;
    }
}

-(void)setStartDate:(NSDate *)startDate {
    _startDate = startDate;

    [self clearExpenseResults];
}

-(void)setEndDate:(NSDate *)endDate {
    _endDate = endDate;
    
    [self clearExpenseResults];
}

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

-(NSArray *)expenseResults {
    if (!_expenseResults) {
        _expenseResults = [self.ledger queryExpensesFromMinDate:self.startDate inclMaxDate:self.endDate dateOrder:ExpenseDateDescending catId:-1];
    }
    return _expenseResults;
}

-(NSArray *)categorySummariesResults {
    if (!_categorySummariesResults) {
        _categorySummariesResults = [ExpenseUtils categorySummariesFromExpenses:self.expenseResults orderBy:CategorySummariesOrderByExpenseTotals];
    }
    return _categorySummariesResults;
}

-(void)clearExpenseResults {
    _expenseResults = nil;
    _categorySummariesResults = nil;
}

-(void)clearCategorySummariesResults {
    _categorySummariesResults = nil;
}

-(void)reloadResultsSection {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)refreshExpenseResults {
    [self clearExpenseResults];
    [self reloadResultsSection];
}

-(void)refreshCategorySummariesResults {
    [self clearCategorySummariesResults];
    [self reloadResultsSection];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _startDate = _endDate = [NSDate date];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureNavHeader];
    
    [ExpenseItemCell registerCellForTableView:self.tableView];
    [CategorySummaryItemCell registerCellForTableView:self.tableView];
    
    [self.ledger clearWasExpenseModified];
}

-(void)viewWillAppear:(BOOL)animated {
    // When returning from any child view controllers, see if an expense was modified and reload data.
    if (self.ledger.wasExpenseModified == YES) {
        [self reloadTableData];
        [self.ledger clearWasExpenseModified];
    }
    
    if (self.waitView != nil) {
        [self.waitView removeFromSuperview];
        self.waitView = nil;
    }
    
    [super viewWillAppear:animated];
}

-(void)configureNavHeader {
    if (self.navigationItem) {
        self.navigationItem.title = @"Browse Expenses";
        
        [self configureNavButtons];
    }
}

-(void)configureNavButtons {
    UIBarButtonItem *addButton = nil;
    if (self.hideAddButton == NO) {
        addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(selectAdd:)];
    }

    UIBarButtonItem *exportButton = nil;
    if (self.displayType == ExpenseBrowserDisplayExpenses && self.expenseResults.count > 0) {
        exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectAction:)];
    }

    NSMutableArray *rightButtons = [[NSMutableArray alloc] init];
    if (addButton != nil) {
        [rightButtons addObject:addButton];
    }
    if (exportButton != nil) {
        [rightButtons addObject:exportButton];
    }
    self.navigationItem.rightBarButtonItems = rightButtons;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return 30;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 22;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.hideSelectOptions == YES) {
            // Don't show any of the menu options.
            return 0;
        } else {
            // Settings: Range, Show-Expense/Subtotal
            return 2;
        }
    } else {
        // Expense items or Category summaries.
        if (self.displayType == ExpenseBrowserDisplayExpenses) {
            return self.expenseResults.count;
        } else {
            return self.categorySummariesResults.count;
        }
    }
}
/*
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"";
    } else {
        double totalExpensesCost = [ExpenseLedger totalCostFromExpenses:self.expenseResults excludedCategories:nil];
        return [NSString stringWithFormat:@"%@     Total: %@", [self currentDisplayTypeName], [Utils formattedCurrencyAmount:totalExpensesCost]];
    }
}
*/

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        UITableViewCell *cell;

        if (self.expenseResults.count > 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"HeaderSummaryCell"];
            cell.textLabel.text = [[self currentDisplayTypeName] uppercaseString];
            double totalExpensesCost = [ExpenseLedger totalCostFromExpenses:self.expenseResults excludedCategories:nil];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [Utils formattedCurrencyAmount:totalExpensesCost]];
        } else {
            static NSString *noExpensesMsg = @"No expenses in range";
            cell = [tableView dequeueReusableCellWithIdentifier:@"HeaderSummaryCellNoExpenses"];
            cell.textLabel.text = [noExpensesMsg uppercaseString];
        }

        cell.backgroundColor = [Utils defaultTableHeaderBgColor];
        return cell;
    } else {
        return [super tableView:tableView viewForHeaderInSection:section];
    }
}

-(NSArray *)rangeSelectNames {
    if (!_rangeSelectNames) {
        _rangeSelectNames = @[
            @"Past 10 days",
            @"Past week",
            @"Past month",
            @"Past 3 months",
            @"Past 6 months",
            @"Past 9 months",
            @"Past year",
            @"Custom"
        ];
    }
    
    return _rangeSelectNames;
}

-(NSString *)currentRangeSelectName {
    if (self.expenseRange != ExpenseRangeCustom) {
        return self.rangeSelectNames[self.expenseRange];
    } else {
        NSString *rangeStr = [Utils formattedDateRangeWithStartDate:self.customStartDate endDate:self.customEndDate];
        if (rangeStr != nil) {
            return rangeStr;    // Ex. '1/1/2015 - 1/31/2015'.
        } else {
            return self.rangeSelectNames[self.expenseRange];    // 'Custom'
        }
    }
}

-(NSString *)currentDisplayTypeName {
    static NSString *displayExpensesName = @"Expenses";
    static NSString *displaySubtotalsName = @"Category Subtotals";
    
    if (self.displayType == ExpenseBrowserDisplayExpenses) {
        return displayExpensesName;
    } else {
        return displaySubtotalsName;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    long row = indexPath.row;
    
    if (indexPath.section == 0) {
        static NSString *reuseRangeSelectCell = @"RangeSelectCell";
        static NSString *reuseDisplaySelectCell = @"DisplaySelectCell";
        
        UITableViewCell *cell;
        if (row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseRangeSelectCell forIndexPath:indexPath];
            cell.textLabel.text = @"Range";
            cell.detailTextLabel.text = [self currentRangeSelectName];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseDisplaySelectCell forIndexPath:indexPath];
            cell.textLabel.text = @"Show";
            cell.detailTextLabel.text = [self currentDisplayTypeName];
        }
        
        return cell;
    }
    else {
        if (self.displayType == ExpenseBrowserDisplayExpenses) {
            ExpenseItemCell *expenseItemCell = [ExpenseItemCell expenseItemCellForTableView:tableView indexPath:indexPath expenses:self.expenseResults];
            return expenseItemCell;
        } else {
            CategorySummaryItemCell *categorySummaryItemCell = [CategorySummaryItemCell categorySummaryCellForTableView:tableView indexPath:indexPath
                                                                                                      categorySummaries:self.categorySummariesResults];
            return categorySummaryItemCell;
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self performSegueWithIdentifier:@"showRangeSelect" sender:self];
        } else if (indexPath.row == 1) {
            [self performSegueWithIdentifier:@"showBrowserDisplaySelect" sender:self];
        }
    } else if (indexPath.section == 1) {
        if (self.displayType == ExpenseBrowserDisplayExpenses) {
            [self performSegueWithIdentifier:@"showEditExpense" sender:self];
        } else if (self.displayType == ExpenseBrowserDisplaySubtotals) {
            self.waitView = [WaitOverlayView waitOverlayViewInView:self.view];
            [self performSelector:@selector(showExpenseResults:) withObject:nil afterDelay:0];
        }
    }
}

-(void)showExpenseResults:(id)sender {
    [self performSegueWithIdentifier:@"showExpenseResults" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    long selectedRow = self.tableView.indexPathForSelectedRow.row;
    
    if ([segue.identifier isEqualToString:@"showRangeSelect"]) {
        RangeSelectController *rangeSelectVC = segue.destinationViewController;
        rangeSelectVC.delegate = self;
        rangeSelectVC.expenseRange = self.expenseRange;
        rangeSelectVC.customStartDate = self.customStartDate;
        rangeSelectVC.customEndDate = self.customEndDate;
    } else if ([segue.identifier isEqualToString:@"showBrowserDisplaySelect"]) {
        BrowserDisplaySelectController *displaySelectVC = segue.destinationViewController;
        displaySelectVC.delegate = self;
        displaySelectVC.expenseBrowserDisplayType = self.displayType;
    } else if ([segue.identifier isEqualToString:@"showEditExpense"]) {
        EditExpenseController *editExpenseVC = segue.destinationViewController;
        Expense *expense = self.expenseResults[selectedRow];
        editExpenseVC.delegate = self;
        editExpenseVC.expense = expense;
        editExpenseVC.mode = EditExpenseControllerModeEdit;
    } else if ([segue.identifier isEqualToString:@"showAddExpense"]) {
        EditExpenseController *editExpenseVC = segue.destinationViewController;
        editExpenseVC.delegate = self;
        editExpenseVC.mode = EditExpenseControllerModeAdd;
    } else if ([segue.identifier isEqualToString:@"showExpenseResults"]) {
        ExpenseResultsController *expenseResultsVC = segue.destinationViewController;
        expenseResultsVC.startDate = self.startDate;
        expenseResultsVC.endDate = self.endDate;
        CategorySummary *categorySummary = self.categorySummariesResults[selectedRow];
        expenseResultsVC.cat = categorySummary.cat;
    }
}

-(void)reloadTableData {
    [self clearExpenseResults];
    [self.tableView reloadData];
    [self configureNavButtons];
}

-(void)popChildControllerAndReload {
    if (self.navigationItem) {
        [self.navigationController popViewControllerAnimated:YES];
    }

    [self reloadTableData];
}

-(void)editExpenseController:(EditExpenseController *)sender doneExpense:(Expense *)expense {
    [self popChildControllerAndReload];
}

-(void)deletedExpenseFromEditExpenseController:(EditExpenseController *)sender {
    [self popChildControllerAndReload];
}

-(void)rangeSelectController:(RangeSelectController *)sender doneExpenseRange:(ExpenseRange)expenseRange customStartDate:(NSDate *)customStartDate customEndDate:(NSDate *)customEndDate {
    if (self.navigationItem) {
        [self.navigationController popViewControllerAnimated:YES];
        
        self.customStartDate = customStartDate;
        self.customEndDate = customEndDate;
        [self setExpenseRange:expenseRange];
        
        [Defaults inst].customStartDate = customStartDate;
        [Defaults inst].customEndDate = customEndDate;
        [Defaults inst].expenseRange = expenseRange;

        [self reloadTableData];
    }
}

-(void)selectAdd:(id)sender {
    [self performSegueWithIdentifier:@"showAddExpense" sender:self];
}

-(void)browserDisplaySelectController:(BrowserDisplaySelectController *)sender doneBrowserDisplayType:(ExpenseBrowserDisplayType)expenseBrowserDisplayType {
    if (self.navigationItem) {
        [self.navigationController popViewControllerAnimated:YES];
    }

    self.displayType = expenseBrowserDisplayType;
    [Defaults inst].expenseBrowserDisplayType = expenseBrowserDisplayType;  // Remember this selection for future display.

    [self reloadTableData];
}

-(void)selectAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Export" message:@"" delegate:self cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Export Expenses to CSV", nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    [alertView show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    static long ExportExpensesIndex = 1;
    
    if (buttonIndex == ExportExpensesIndex) {
        [self startExport];
    }
}

-(void)startExport {
    NSMutableString *expensesCsv = [[NSMutableString alloc] init];
    
    NSString *csvHeaderLine = @"Date,Description,Amount,Category\n";
    [expensesCsv appendString:csvHeaderLine];
    [expensesCsv appendString:[ExpenseLedger csvFromExpenses:self.expenseResults]];
    NSData *expensesCsvData = [Utils dataFromString:expensesCsv];

    [Utils presentSendMailUI:self.navigationController delegate:self subject:@"Expenses export" body:@"Attached file is in comma-separated (csv) format."
                  attachment:expensesCsvData mimeType:@"text/plain" filename:@"expenses_export.csv"];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [Utils handleSendMailResult:self.navigationController successSentMsg:@"Expenses export sent." cancelMsg:@"Export cancelled"
                       errorMsg:@"Error sending export file. Check email and connectivity." result:result error:error];
}



@end
