/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

@interface ExpenseItemCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *datetimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

+(void)registerCellForTableView:(UITableView *)tableView;
+(ExpenseItemCell *)expenseItemCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath expenses:(NSArray *)expenses;

@end
