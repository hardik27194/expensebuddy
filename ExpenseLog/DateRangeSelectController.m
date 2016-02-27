/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DateRangeSelectController.h"
#import "DateHelper.h"

static int _tagDateButton = 100;
static int _tagDatePicker = 200;

@interface DateRangeSelectController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign, readwrite) BOOL showStartDatePicker;
@property (nonatomic, assign, readwrite) BOOL showEndDatePicker;

@end

@implementation DateRangeSelectController
@synthesize showStartDatePicker=_showStartDatePicker;
@synthesize showEndDatePicker=_showEndDatePicker;

-(NSDate *)startDate {
    if (!_startDate) {
        _startDate = dateStrippedTime([NSDate date]);
    }
    return _startDate;
}

-(NSDate *)endDate {
    if (!_endDate) {
        _endDate = dateStrippedTime([NSDate date]);
    }
    return _endDate;
}

-(void)setShowStartDatePicker:(BOOL)showStartDatePicker {
    if (_showStartDatePicker == showStartDatePicker) {
        return;
    }
    
    _showStartDatePicker = showStartDatePicker;

    [self.tableView beginUpdates];
    NSArray *indexPathOfStartDatePicker = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]];
    if (showStartDatePicker) {
        self.showEndDatePicker = NO;
        [self.tableView insertRowsAtIndexPaths:indexPathOfStartDatePicker withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView deleteRowsAtIndexPaths:indexPathOfStartDatePicker withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.tableView endUpdates];
}

-(void)setShowEndDatePicker:(BOOL)showEndDatePicker {
    if (_showEndDatePicker == showEndDatePicker) {
        return;
    }
    
    _showEndDatePicker = showEndDatePicker;

    [self.tableView beginUpdates];
    NSArray *indexPathOfEndDatePicker = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:1]];
    if (showEndDatePicker) {
        self.showStartDatePicker = NO;
        [self.tableView insertRowsAtIndexPaths:indexPathOfEndDatePicker withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView deleteRowsAtIndexPaths:indexPathOfEndDatePicker withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.tableView endUpdates];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.showStartDatePicker) {
            return 2;
        } else {
            return 1;
        }
    } else {
        if (self.showEndDatePicker) {
            return 2;
        } else {
            return 1;
        }
    }
}

NSString *dateButtonStringFromDate(NSDate *date) {
    return dateStringFromDateWithStyle(date, NSDateFormatterMediumStyle, NSDateFormatterNoStyle);
}

-(void)setupDateButtonInCell:(UITableViewCell *)cell action:(SEL)selectButtonSelector date:(NSDate *)date btnPrefix:(NSString *)btnPrefix {
    UIButton *dateBtn = (UIButton *)[cell viewWithTag:_tagDateButton];
    [dateBtn removeTarget:self action:selectButtonSelector forControlEvents:UIControlEventTouchUpInside];
    [dateBtn addTarget:self action:selectButtonSelector forControlEvents:UIControlEventTouchUpInside];
    [dateBtn setTitle:[NSString stringWithFormat:@"%@%@",btnPrefix, dateButtonStringFromDate(date)] forState:UIControlStateNormal];
}

-(void)setupDatePickerInCell:(UITableViewCell *)cell action:(SEL)changedDatePickerSelector date:(NSDate *)date {
    UIDatePicker *datePicker = (UIDatePicker *)[cell viewWithTag:_tagDatePicker];
    [datePicker removeTarget:self action:changedDatePickerSelector forControlEvents:UIControlEventValueChanged];
    [datePicker addTarget:self action:changedDatePickerSelector forControlEvents:UIControlEventValueChanged];
    [datePicker setDate:date animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseDateButtonCell = @"DateButtonCell";
    static NSString *reuseDatePickerCell = @"DatePickerCell";
    
    UITableViewCell *cell;

    if (indexPath.section == 0) {
        // Start date section.
        if (indexPath.row == 0) {
            // Start date button.
            cell = [tableView dequeueReusableCellWithIdentifier:reuseDateButtonCell forIndexPath:indexPath];
            [self setupDateButtonInCell:cell action:@selector(selectStartDateBtn:) date:self.startDate btnPrefix:@"Starts:     "];
        } else {
            // Start date picker.
            cell = [tableView dequeueReusableCellWithIdentifier:reuseDatePickerCell forIndexPath:indexPath];
            [self setupDatePickerInCell:cell action:@selector(changedStartDatePicker:) date:self.startDate];
        }
    } else {
        // End date section.
        if (indexPath.row == 0) {
            // End date button.
            cell = [tableView dequeueReusableCellWithIdentifier:reuseDateButtonCell forIndexPath:indexPath];
            [self setupDateButtonInCell:cell action:@selector(selectEndDateBtn:) date:self.endDate btnPrefix:@"Ends:     "];
        } else {
            // End date picker.
            cell = [tableView dequeueReusableCellWithIdentifier:reuseDatePickerCell forIndexPath:indexPath];
            [self setupDatePickerInCell:cell action:@selector(changedEndDatePicker:) date:self.endDate];
        }
    }
    
    return cell;
}

-(void)selectStartDateBtn:(id)sender {
    self.showStartDatePicker = !self.showStartDatePicker;
}
-(void)selectEndDateBtn:(id)sender {
    self.showEndDatePicker = !self.showEndDatePicker;
}
-(void)changedStartDatePicker:(UIDatePicker *)sender {
    self.startDate = sender.date;
    
    [self.tableView beginUpdates];
    NSArray *indexPathOfStartDateButton = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:indexPathOfStartDateButton withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}
-(void)changedEndDatePicker:(UIDatePicker *)sender {
    self.endDate = sender.date;

    [self.tableView beginUpdates];
    NSArray *indexPathOfEndDateButton = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]];
    [self.tableView reloadRowsAtIndexPaths:indexPathOfEndDateButton withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

// Back button pressed. Send date range to delegate.
-(void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        if (self.delegate) {
            [self.delegate dateRangeSelectController:self doneStartDate:self.startDate endDate:self.endDate];
        }
    }
    
    [super viewWillDisappear:animated];
}

@end
