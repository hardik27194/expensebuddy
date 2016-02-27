/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "BrowserDisplaySelectController.h"
#import "WaitOverlayView.h"

@interface BrowserDisplaySelectController () <UITableViewDataSource, UITableViewDataSource>

@end

@implementation BrowserDisplaySelectController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *bbiDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(selectDone:)];
    self.navigationItem.rightBarButtonItem = bbiDone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

NSString *nameForBrowserDisplayType(ExpenseBrowserDisplayType browserDisplayType) {
    if (browserDisplayType == ExpenseBrowserDisplayExpenses) {
        return @"Expenses";
    } else if (browserDisplayType == ExpenseBrowserDisplaySubtotals) {
        return @"Category Subtotals";
    } else {
        return @"";
    }
}

NSString *descriptionForBrowserDisplayType(ExpenseBrowserDisplayType browserDisplayType) {
    if (browserDisplayType == ExpenseBrowserDisplayExpenses) {
        return @"Show individual expense transactions.";
    } else if (browserDisplayType == ExpenseBrowserDisplaySubtotals) {
        return @"Show totals for each category.";
    } else {
        return @"";
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BrowserDisplayItemCell" forIndexPath:indexPath];
    ExpenseBrowserDisplayType browserDisplayType;
    if (indexPath.row == 0) {
        browserDisplayType = ExpenseBrowserDisplayExpenses;
    } else {
        browserDisplayType = ExpenseBrowserDisplaySubtotals;
    }
    
    cell.textLabel.text = nameForBrowserDisplayType(browserDisplayType);
    cell.detailTextLabel.text = descriptionForBrowserDisplayType(browserDisplayType);

    if (browserDisplayType == self.expenseBrowserDisplayType) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}

ExpenseBrowserDisplayType displayTypeFromIndexPath(NSIndexPath *indexPath) {
    if (indexPath.row == 0) {
        return ExpenseBrowserDisplayExpenses;
    } else {
        return ExpenseBrowserDisplaySubtotals;
    }
}

NSIndexPath *indexPathFromDisplayType(ExpenseBrowserDisplayType displayType) {
    if (displayType == ExpenseBrowserDisplayExpenses) {
        return [NSIndexPath indexPathForRow:0 inSection:0];
    } else {
        return [NSIndexPath indexPathForRow:1 inSection:0];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *prevSelIndexPath = indexPathFromDisplayType(self.expenseBrowserDisplayType);
    
    ExpenseBrowserDisplayType displayType = displayTypeFromIndexPath(indexPath);
    self.expenseBrowserDisplayType = displayType;

    if (prevSelIndexPath.section == indexPath.section && prevSelIndexPath.row == indexPath.row) {
        prevSelIndexPath = nil;     // Avoid reloading the same row when same row selected which causes a crash.
    }
    
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, prevSelIndexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)selectDone:(id)sender {
    if (self.delegate) {
        [WaitOverlayView waitOverlayViewInView:self.view];
        [self performSelector:@selector(callDelegate:) withObject:nil afterDelay:0];
    }
}

-(void)callDelegate:(id)sender {
    [self.delegate browserDisplaySelectController:self doneBrowserDisplayType:self.expenseBrowserDisplayType];
}

@end
