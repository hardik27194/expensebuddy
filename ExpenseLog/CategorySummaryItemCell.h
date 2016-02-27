/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

@interface CategorySummaryItemCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *categoryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtotalAmountLabel;
@property (weak, nonatomic) IBOutlet UILabel *transactionsNumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

+(void)registerCellForTableView:(UITableView *)tableView;
+(CategorySummaryItemCell *)categorySummaryCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath categorySummaries:(NSArray *)categorySummaries;

@end
