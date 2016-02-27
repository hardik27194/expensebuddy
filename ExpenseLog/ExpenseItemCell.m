/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "ExpenseItemCell.h"
#import "DateHelper.h"
#import "ExpenseModel.h"
#import "Utils.h"

@implementation ExpenseItemCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+(void)registerCellForTableView:(UITableView *)tableView {
    UINib *expenseItemCellNib = [UINib nibWithNibName:@"ExpenseItemCell" bundle:nil];
    [tableView registerNib:expenseItemCellNib forCellReuseIdentifier:@"ExpenseItemCell"];
}

+(ExpenseItemCell *)expenseItemCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath expenses:(NSArray *)expenses {
    ExpenseItemCell *expenseItemCell = [tableView dequeueReusableCellWithIdentifier:@"ExpenseItemCell" forIndexPath:indexPath];
    Expense *expense = expenses[indexPath.row];
    
    expenseItemCell.datetimeLabel.text = [NSString stringWithFormat:@"%@ %@",
                                          dateStringFromDateWithFormat(expense.date, @"E"),
                                          dateStringFromDateWithStyle(expense.date, NSDateFormatterShortStyle, NSDateFormatterNoStyle)];
    [expenseItemCell.datetimeLabel sizeToFit];
    
    expenseItemCell.nameLabel.text = [NSString stringWithFormat:@"%@", expense.name];
    expenseItemCell.nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    expenseItemCell.nameLabel.numberOfLines = 0;
    [expenseItemCell.nameLabel sizeToFit];
    
    expenseItemCell.amountLabel.text = [Utils formattedCurrencyAmount:expense.amount];
    [expenseItemCell.amountLabel sizeToFit];
    
    expenseItemCell.categoryLabel.text = [NSString stringWithFormat:@"%@", expense.cat.name];
    expenseItemCell.iconImageView.image = expense.cat.icon32;
    
    return expenseItemCell;
}

@end
