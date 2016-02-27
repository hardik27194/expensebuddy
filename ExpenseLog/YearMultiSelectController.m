/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "YearMultiSelectController.h"
#import "ExpenseModel.h"
#import "DateHelper.h"
#import "Utils.h"

@interface YearMultiSelectController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (nonatomic, weak, readonly) ExpenseLedger *ledger;
@property (nonatomic, copy, readwrite) NSArray *years;
@property (nonatomic, strong, readwrite) NSMutableDictionary *yearNumExpenses;
@property (nonatomic, strong, readwrite) NSMutableDictionary *selYears;

@end

@implementation YearMultiSelectController
@synthesize years=_years;
@synthesize yearNumExpenses=_yearNumExpenses;
@synthesize navTitle=_navTitle;
@synthesize header1Title=_header1Title;
@synthesize header2Title=_header2Title;
@synthesize actionButtonTitle=_actionButtonTitle;
@synthesize alertPrompt=_alertPrompt;
@synthesize alertMessage=_alertMessage;

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

-(NSArray *)years {
    if (_years == nil) {
        NSArray *yearsTmp = [NSArray arrayWithObject:[NSNumber numberWithInt:0]];   // year '0' for 'All Years'
        _years = [yearsTmp arrayByAddingObjectsFromArray:[self.ledger queryYearsContainingExpenses]];
    }
    return _years;
}

-(NSMutableDictionary *)yearTotals {
    if (_yearNumExpenses == nil) {
        _yearNumExpenses = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return _yearNumExpenses;
}

-(NSMutableDictionary *)selYears {
    if (_selYears == nil) {
        _selYears = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return _selYears;
}

-(NSString *)actionButtonTitle {
    if (_actionButtonTitle == nil) {
        return @"Done";
    }
    return _actionButtonTitle;
}

-(NSString *)navTitle {
    if (_navTitle == nil) {
        return @"";
    }
    return _navTitle;
}

-(NSString *)header1Title {
    if (_header1Title == nil) {
        _header1Title = @"";
    }
    return _header1Title;
}

-(NSString *)header2Title {
    if (_header2Title == nil) {
        _header2Title = @"Select Range";
    }
    return _header2Title;
}

-(NSString *)alertPrompt {
    if (_alertPrompt == nil) {
        _alertPrompt = @"";
    }
    return _alertPrompt;
}

-(NSString *)alertMessage {
    if (_alertMessage == nil) {
        _alertMessage = @"Selected:";
    }
    return _alertMessage;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.navigationItem) {
        if (self.navTitle != nil) {
            self.navigationItem.title = self.navTitle;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSNumber *)yearKeyFromYear:(int)year {
    return [NSNumber numberWithInt:year];
}

-(int)yearNumTransactionsFromYear:(int)year {
    // Don't return a count for year 0 'All Years'.
    if (year == 0) {
        return 0;
    }
    
    NSNumber *yearKey = [self yearKeyFromYear:year];
    
    if (self.yearNumExpenses[yearKey] == nil) {
        TotalQtyAmount qtyAmount = [self.ledger queryTotalExpenseAmountForYear:year];
        self.yearNumExpenses[yearKey] = [NSNumber numberWithInt:qtyAmount.qty];
    }
    
    return [self.yearNumExpenses[yearKey] intValue];
}

-(long)rowFromYear:(int)year {
    return [self.years indexOfObject:[self yearKeyFromYear:year]];
}

-(int)yearFromRow:(long)row {
    NSNumber *yearNum = (NSNumber *)self.years[row];
    return yearNum.intValue;
}

-(BOOL)isYearChecked:(int)year {
    NSNumber *yearKey = [self yearKeyFromYear:year];
    id selYearVal = [self.selYears objectForKey:yearKey];
    if (selYearVal == nil) {
        return NO;
    } else {
        return YES;
    }
}

-(void)checkYear:(int)year {
    NSNumber *yearKey = [self yearKeyFromYear:year];
    self.selYears[yearKey] = yearKey;
}

-(void)uncheckYear:(int)year {
    NSNumber *yearKey = [self yearKeyFromYear:year];
    [self.selYears removeObjectForKey:yearKey];
}

-(void)uncheckAllIndividualYears {
    for (NSNumber *yearKey in self.years) {
        int year = yearKey.intValue;

        // Uncheck all years except 'All Years'.
        if (year != 0) {
            [self uncheckYear:year];
        }
    }
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return self.years.count;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    
    if (section == 0) {
        title = self.header1Title;
    } else {
        title = self.header2Title;
    }
    
    return title;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (self.header1Title == nil || self.header1Title.length == 0) {
            return 0;
        } else {
            return 44;
        }
    } else {
        return 44;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseYearItemCell = @"YearItemCell";
    
    UITableViewCell *cell;

    if (indexPath.section == 0) {
        return nil;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:reuseYearItemCell forIndexPath:indexPath];
        int year = [self yearFromRow:indexPath.row];
        int yearNumTransactions = [self yearNumTransactionsFromYear:year];
    
        if (year == 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"All Years"];
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"%d", year];
        }

        if (yearNumTransactions > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"(%d)", yearNumTransactions];
        } else {
            cell.detailTextLabel.text = @" ";
        }
    
        if ([self isYearChecked:year]) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
    
    return cell;
}

-(void)updateNav {
    if (self.navigationItem) {
        if (self.selYears.count > 0) {
            if (self.navigationItem.rightBarButtonItem == nil) {
                UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithTitle:self.actionButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(selectDone:)];
                self.navigationItem.rightBarButtonItem = bbi;
            }
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
}

-(NSString *)selectedYearsText {
    NSMutableString *yearsText = [NSMutableString stringWithFormat:@"%@\n", self.alertMessage];
    
    long numYearRows = [self.tableView numberOfRowsInSection:1];
    for (long row=0; row < numYearRows; row++) {
        int year = [self yearFromRow:row];
        if ([self isYearChecked:year]) {
            if (year == 0) {
                [yearsText appendString:@"All Years"];
            } else {
                [yearsText appendFormat:@"%d", year];
            }
            
            if (row < numYearRows-1) {
                [yearsText appendString:@"\n"];
            }
        }
    }
    
    if (self.alertWarningPrompt != nil) {
        [yearsText appendFormat:@"\n\n%@", self.alertWarningPrompt];
    }
    
    return yearsText;
}

-(void)selectDone:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.alertPrompt message:[self selectedYearsText]
                                                       delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    [alertView show];

}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    static long OKIndex = 1;

    if (buttonIndex == OKIndex) {
        if (self.delegate != nil) {
            NSArray *sortedSelectedYears = [self.selYears.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSNumber *yearKeyA, NSNumber *yearKeyB) {
                int yearA = yearKeyA.intValue;
                int yearB = yearKeyB.intValue;
                if (yearA > yearB) {
                    return NSOrderedDescending;
                } else if (yearA < yearB) {
                    return NSOrderedAscending;
                }
                
                return NSOrderedSame;
            }];
            
            // If 'All Years' selected, use array containing every year with at least one transaction.
            if (sortedSelectedYears.count > 0 && ((NSNumber *)sortedSelectedYears[0]).intValue == 0) {
                sortedSelectedYears = self.years;
            }
            
            [self.delegate yearMultiSelectController:self selectedYears:sortedSelectedYears];
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
    
    if (indexPath.section == 0) {
        return;
    }
    
    int year = [self yearFromRow:indexPath.row];
    if ([self isYearChecked:year]) {
        [self uncheckYear:year];
    } else {
        [self checkYear:year];
    }
    
    if (year == 0 && [self isYearChecked:year]) {
        [self uncheckAllIndividualYears];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    } else if (year != 0 && [self isYearChecked:year]) {
        [self uncheckYear:0];
        NSIndexPath *indexPathAllYearsRow = [NSIndexPath indexPathForRow:0 inSection:1];
        [tableView reloadRowsAtIndexPaths:@[indexPath, indexPathAllYearsRow] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [self updateNav];
}


@end
