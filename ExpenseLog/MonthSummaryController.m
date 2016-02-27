/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MonthSummaryController.h"
#import "ExpenseBrowserController.h"
#import "YearSelectController.h"
#import "WaitOverlayView.h"

#import "ExpenseModel.h"
#import "DateHelper.h"
#import "Utils.h"
#import "Defaults.h"

@interface MonthSummaryController () <UITableViewDataSource, UITableViewDelegate, YearSelectControllerDelegate, MFMailComposeViewControllerDelegate>
@property (nonatomic, weak, readonly) ExpenseLedger *ledger;
@property (nonatomic, strong, readwrite) NSMutableDictionary *monthTotals;
@property (nonatomic, copy, readonly) NSArray *yearsWithExpenses;
@property (nonatomic, strong, readwrite) WaitOverlayView *waitView;
@property (nonatomic, assign, readwrite) BOOL isInitialLoad;

@end

@implementation MonthSummaryController
@synthesize yearsWithExpenses=_yearsWithExpenses;
@synthesize monthTotals=_monthTotals;

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

-(int)year {
    if (_year == 0) {
        long currentYear = componentsFromDate([NSDate date]).year;
        _year = (int)currentYear;
    }
    
    return _year;
}

-(NSMutableDictionary *)monthTotals {
    if (_monthTotals == nil) {
        _monthTotals = [[NSMutableDictionary alloc] initWithCapacity:12];
    }
    
    return _monthTotals;
}

-(NSArray *)yearsWithExpenses {
    if (_yearsWithExpenses == nil) {
        _yearsWithExpenses = [self.ledger queryYearsContainingExpenses];
    }
    
    return _yearsWithExpenses;
}

-(void)resetTotals {
    _monthTotals = nil;
    _yearsWithExpenses = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.navigationItem) {
        [self configureNavButtons];
        [self updateNavTitle];
    }
    
    self.isInitialLoad = YES;
}
         
-(void)selectTapUpgrade:(id)sender {
    NSLog(@"Tap upgrade");
}

-(void)viewWillAppear:(BOOL)animated {
    // When returning from any child view controllers, always reload data because we don't know if an expense was modified in child controller.
    if (!self.isInitialLoad) {
        [self resetTotals];
        [self.tableView reloadData];
    }

    self.isInitialLoad = NO;
    
    if (self.waitView != nil) {
        [self.waitView removeFromSuperview];
        self.waitView = nil;
    }
    
    [super viewWillAppear:animated];
}

-(void)updateNavTitle {
    if (self.navigationItem) {
        self.navigationItem.title = [NSString stringWithFormat:@"%d Year To Date", self.year];
    }
}

-(void)configureNavButtons {
    UIBarButtonItem *bbiSelectYear = [[UIBarButtonItem alloc] initWithTitle:@"Select Year" style:UIBarButtonItemStylePlain target:self action:@selector(selectYear:)];
    if (self.yearsWithExpenses.count == 0) {
        bbiSelectYear.enabled = NO;
    }

    UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(selectAction:)];

    self.navigationItem.rightBarButtonItems = @[bbiSelectYear, exportButton];
}

-(void)selectYear:(id)sender {
    [self performSegueWithIdentifier:@"showYearSelect" sender:self];
}

-(void)selectAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Export" message:@"" delegate:self cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Export Year To Date to CSV", nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    [alertView show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    static long ExportYTDIndex = 1;
    
    if (buttonIndex == ExportYTDIndex) {
        [self startExport];
    }
}

-(void)startExport {
    NSMutableString *ytdCsv = [[NSMutableString alloc] init];
    
    NSString *csvHeaderLine = @"Month,Amount\n";
    [ytdCsv appendString:csvHeaderLine];

    for (int i=0; i < 12; i++) {
        NSDate *monthDate = monthDateFromRow(i, self.year);
        NSString *monthName = dateStringFromDateWithFormat(monthDate, @"MMMM");
        double monthAmountTotal = [self monthTotalsFromMonthDate:monthDate];

        NSString *csvMonthLine = [NSString stringWithFormat:@"%@,%.2f\n", monthName, monthAmountTotal];
        [ytdCsv appendString:csvMonthLine];
    }
    
    NSLog(@"ytdCsv:\n%@", ytdCsv);
    
    NSData *ytdCsvData = [Utils dataFromString:ytdCsv];
    
    NSString *subject = [NSString stringWithFormat:@"Expenses Year to Date for %d", self.year];
    NSString *filename = [NSString stringWithFormat:@"expenses_ytd_%d_export.csv", self.year];
    [Utils presentSendMailUI:self.navigationController delegate:self subject:subject body:@"Attached file is in comma-separated (csv) format."
                  attachment:ytdCsvData mimeType:@"text/plain" filename:filename];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [Utils handleSendMailResult:self.navigationController successSentMsg:@"Expenses YTD export sent." cancelMsg:@"Export cancelled"
                       errorMsg:@"Error sending export file. Check email and connectivity." result:result error:error];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        TotalQtyAmount qtyAmount = [self.ledger queryTotalExpenseAmountForYear:self.year];
        return [NSString stringWithFormat:@"Total Expenses: %@", [Utils formattedCurrencyAmount:qtyAmount.amount]];
    } else {
        return @"";
    }
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 12;
}

-(double)monthTotalsFromMonthDate:(NSDate *)monthDate {
    if (self.monthTotals[monthDate] == nil) {
        TotalQtyAmount qtyAmount = [self.ledger queryTotalExpenseForMonthDate:monthDate];
        self.monthTotals[monthDate] = [NSNumber numberWithDouble:qtyAmount.amount];
    }
    
    return [self.monthTotals[monthDate] doubleValue];
}

NSDate *monthDateFromRow(long row, long year) {
    long monthNo = row + 1;    // 1 =   Jan, 2 = Feb, ... 12 = Dec.
    NSDate *monthDate = dateFromComponents((int) monthNo, 1, (int) year);
    return monthDate;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseMonthSummaryCell = @"MonthSummaryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseMonthSummaryCell forIndexPath:indexPath];
    NSDate *monthDate = monthDateFromRow(indexPath.row, self.year);
    NSString *monthName = dateStringFromDateWithFormat(monthDate, @"MMMM");

    cell.textLabel.text = [NSString stringWithFormat:@"%@", monthName];
    double monthAmountTotal = [self monthTotalsFromMonthDate:monthDate];
    
    if (monthAmountTotal == 0.0f) {
        cell.userInteractionEnabled = NO;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = @" ";
    } else {
        cell.userInteractionEnabled = YES;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text =  [Utils formattedCurrencyAmount:monthAmountTotal];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.waitView = [WaitOverlayView waitOverlayViewInView:self.view];
    [self performSelector:@selector(showExpenseBrowser:) withObject:nil afterDelay:0];
}

-(void)showExpenseBrowser:(id)sender {
    [self performSegueWithIdentifier:@"showExpenseBrowser" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    long row = self.tableView.indexPathForSelectedRow.row;

    if ([segue.identifier isEqualToString:@"showExpenseBrowser"]) {
        NSDate *monthStartDate = monthDateFromRow(row, self.year);
        NSDate *monthEndDate = dateMonthLastDay(monthStartDate);
        
        ExpenseBrowserController *expenseBrowserVC = (ExpenseBrowserController *)segue.destinationViewController;
        expenseBrowserVC.hideSelectOptions = YES;
        expenseBrowserVC.hideAddButton = YES;
        expenseBrowserVC.displayType = ExpenseBrowserDisplaySubtotals;
        expenseBrowserVC.customStartDate = monthStartDate;
        expenseBrowserVC.customEndDate = monthEndDate;
        expenseBrowserVC.expenseRange = ExpenseRangeCustom;
    } else if ([segue.identifier isEqualToString:@"showYearSelect"]) {
        YearSelectController *yearSelectVC = (YearSelectController *)segue.destinationViewController;
        yearSelectVC.delegate = self;
        yearSelectVC.selYear = self.year;
        yearSelectVC.years = self.yearsWithExpenses;
    }
}

-(void)yearSelectController:(YearSelectController *)sender doneSelectYear:(int)year {
    if (year == 0) {
        return;
    }
    
    self.year = year;
    [Defaults inst].ytdYear = year;

    [self resetTotals];
    [self.tableView reloadData];
    [self updateNavTitle];
}

@end
