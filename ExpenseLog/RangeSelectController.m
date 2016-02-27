/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "RangeSelectController.h"
#import "DateRangeSelectController.h"
#import "WaitOverlayView.h"
#import "DateHelper.h"
#import "Utils.h"

@interface RangeSelectController () <UITableViewDataSource, UITableViewDelegate, DateRangeSelectControllerDelegate>

@end

@implementation RangeSelectController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *bbiDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(selectDone:)];
    self.navigationItem.rightBarButtonItem = bbiDone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 22;
    } else {
        return [super tableView:tableView heightForHeaderInSection:section];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return ExpenseRangePastYear + 1;
    } else {
        return 1;
    }
}

NSString *nameForExpenseRange(ExpenseRange expenseRange) {
    static NSString *past10 = @"Past 10 Days";
    static NSString *pastWeek = @"Past Week";
    static NSString *pastMonth = @"Past Month";
    static NSString *past3Months = @"Past 3 Months";
    static NSString *past6Months = @"Past 6 Months";
    static NSString *past9Months = @"Past 9 Months";
    static NSString *pastYear = @"Past Year";
    static NSString *custom = @"Custom";
    
    switch (expenseRange) {
        case ExpenseRangePast10Days:
            return past10;
        case ExpenseRangePastWeek:
            return pastWeek;
        case ExpenseRangePastMonth:
            return pastMonth;
        case ExpenseRangePast3Months:
            return past3Months;
        case ExpenseRangePast6Months:
            return past6Months;
        case ExpenseRangePast9Months:
            return past9Months;
        case ExpenseRangePastYear:
            return pastYear;
        case ExpenseRangeCustom:
        default:
            return custom;
    }
}

ExpenseRange expenseRangeFromIndexPath(NSIndexPath *indexPath) {
    if (indexPath.section == 0) {
        return (ExpenseRange) indexPath.row;
    } else {
        return ExpenseRangeCustom;
    }
}

NSIndexPath *indexPathFromExpenseRange(ExpenseRange expenseRange) {
    if (expenseRange == ExpenseRangeCustom) {
        return [NSIndexPath indexPathForRow:0 inSection:1];
    } else {
        return [NSIndexPath indexPathForRow:(NSInteger)expenseRange inSection:0];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    ExpenseRange expenseRangeItem = expenseRangeFromIndexPath(indexPath);
        
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ExpenseRangeItemCell" forIndexPath:indexPath];
        cell.textLabel.text = nameForExpenseRange(expenseRangeItem);

    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ExpenseCustomRangeItemCell" forIndexPath:indexPath];
        cell.textLabel.text = nameForExpenseRange(expenseRangeItem);

        NSString *rangeStr = [Utils formattedDateRangeWithStartDate:self.customStartDate endDate:self.customEndDate];
        if (rangeStr != nil) {
            cell.detailTextLabel.text = rangeStr;    // Ex. '1/1/2015 - 1/31/2015'.
        } else {
            cell.detailTextLabel.text = @" ";
        }
    }

    if (expenseRangeItem == self.expenseRange) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        if (expenseRangeItem != ExpenseRangeCustom) {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *prevSelIndexPath = indexPathFromExpenseRange(self.expenseRange);
    
    ExpenseRange expenseRangeItem = expenseRangeFromIndexPath(indexPath);
    self.expenseRange = expenseRangeItem;

    // Reload the previously selection and new selection to refresh the check marks.
    if (prevSelIndexPath.section == indexPath.section && prevSelIndexPath.row == indexPath.row) {
        prevSelIndexPath = nil;     // Avoid reloading the same row when same row selected which causes a crash.
    }
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, prevSelIndexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if (expenseRangeItem == ExpenseRangeCustom) {
        [self performSegueWithIdentifier:@"showDateRangeSelect" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDateRangeSelect"]) {
        DateRangeSelectController *dateRangeSelectVC = (DateRangeSelectController *)segue.destinationViewController;
        dateRangeSelectVC.delegate = self;
        dateRangeSelectVC.startDate = self.customStartDate;
        dateRangeSelectVC.endDate = self.customEndDate;
    }
    
}

-(void)dateRangeSelectController:(DateRangeSelectController *)sender doneStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    self.customStartDate = startDate;
    self.customEndDate = endDate;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)selectDone:(id)sender {
    if (self.delegate) {
        [WaitOverlayView waitOverlayViewInView:self.view];
        [self performSelector:@selector(callDelegate:) withObject:nil afterDelay:0];
    }
}

-(void)callDelegate:(id)sender {
    [self.delegate rangeSelectController:self doneExpenseRange:self.expenseRange customStartDate:self.customStartDate customEndDate:self.customEndDate];
}

@end
