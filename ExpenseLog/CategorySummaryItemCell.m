/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "CategorySummaryItemCell.h"
#import "ExpenseModel.h"
#import "Utils.h"

@implementation CategorySummaryItemCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+(void)registerCellForTableView:(UITableView *)tableView {
    UINib *categorySummaryItemCellNib = [UINib nibWithNibName:@"CategorySummaryItemCell" bundle:nil];
    [tableView registerNib:categorySummaryItemCellNib forCellReuseIdentifier:@"CategorySummaryItemCell"];
}

+(CategorySummaryItemCell *)categorySummaryCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath categorySummaries:(NSArray *)categorySummaries {
    CategorySummaryItemCell *categorySummaryItemCell = [tableView dequeueReusableCellWithIdentifier:@"CategorySummaryItemCell" forIndexPath:indexPath];
    CategorySummary *categorySummary = categorySummaries[indexPath.row];
    
    categorySummaryItemCell.categoryNameLabel.text = [NSString stringWithFormat:@"%@", categorySummary.cat.name];
    categorySummaryItemCell.subtotalAmountLabel.text = [Utils formattedCurrencyAmount:categorySummary.totalExpenseAmount];
    categorySummaryItemCell.transactionsNumLabel.text = [NSString stringWithFormat:@"%d %@", categorySummary.numExpenseTransactions,
                                                         categorySummary.numExpenseTransactions > 1 ? @"transactions" : @"transaction"];
    categorySummaryItemCell.iconImageView.image = categorySummary.cat.icon32;
    
    return categorySummaryItemCell;
}

@end
