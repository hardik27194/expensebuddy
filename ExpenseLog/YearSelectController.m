/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "YearSelectController.h"
#import "ExpenseModel.h"
#import "Utils.h"
#import "DateHelper.h"

@interface YearSelectController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak, readonly) ExpenseLedger *ledger;
@property (nonatomic, strong, readwrite) NSMutableDictionary *yearTotals;

@end

@implementation YearSelectController
@synthesize yearTotals=_yearTotals;

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

-(NSArray *)years {
    if (_years == nil) {
        _years = [self.ledger queryYearsContainingExpenses];
    }
    return _years;
}

-(NSMutableDictionary *)yearTotals {
    if (_yearTotals == nil) {
        _yearTotals = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    
    return _yearTotals;
}

-(int)selYear {
    if (_selYear == 0) {
        NSDateComponents *components = componentsFromDate([NSDate date]);
        int currentYear = (int)components.year;
        
        // If no selected year on init, use current year as selected as long as current year has expenses.
        if ([self.years containsObject:[NSNumber numberWithInt:currentYear]]) {
            _selYear = currentYear;
        } else if (self.years.count > 0) {
            _selYear = [self yearFromRow:0];
        }
    }
    
    return _selYear;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.navigationItem) {
        self.navigationItem.title = @"Select Year";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.years.count;
}

-(NSNumber *)yearKeyFromYear:(int)year {
    return [NSNumber numberWithInt:year];
}

-(double)yearTotalsFromYear:(int)year {
    NSNumber *yearKey = [self yearKeyFromYear:year];
    
    if (self.yearTotals[yearKey] == nil) {
        TotalQtyAmount qtyAmount = [self.ledger queryTotalExpenseAmountForYear:year];
        self.yearTotals[yearKey] = [NSNumber numberWithDouble:qtyAmount.amount];
    }
    
    return [self.yearTotals[yearKey] doubleValue];
}

-(long)rowFromYear:(int)year {
    return [self.years indexOfObject:[self yearKeyFromYear:year]];
}

-(int)yearFromRow:(long)row {
    NSNumber *yearNum = (NSNumber *)self.years[row];
    return yearNum.intValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseYearItemCell = @"YearItemCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseYearItemCell forIndexPath:indexPath];
    int year = [self yearFromRow:indexPath.row];
    double yearTotalAmount = [self yearTotalsFromYear:year];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d", year];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [Utils formattedCurrencyAmount:yearTotalAmount]];

    if (year == self.selYear) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    long prevSelRow = [self rowFromYear:self.selYear];
    NSIndexPath *prevSelIndexPath = [NSIndexPath indexPathForRow:prevSelRow inSection:0];
    
    int year = [self yearFromRow:indexPath.row];

    if (year != self.selYear) {
        self.selYear = year;
        [tableView reloadRowsAtIndexPaths:@[indexPath, prevSelIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

// Back button pressed. Send selected year to delegate.
-(void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        if (self.delegate) {
            [self.delegate yearSelectController:self doneSelectYear:self.selYear];
        }
    }
    
    [super viewWillDisappear:animated];
}

@end
