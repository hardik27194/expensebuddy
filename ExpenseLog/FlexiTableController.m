/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "FlexiTableController.h"

@interface FlexiTableController ()

@end

@implementation FlexiTableController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Dynamic row height.
    self.tableView.estimatedRowHeight = 68.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Reload table view always to work around bug where row heights aren't dynamically set.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
