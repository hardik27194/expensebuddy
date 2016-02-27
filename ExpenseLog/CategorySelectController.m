/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "CategorySelectController.h"
#import "UpgradeController.h"

#import "ExpenseModel.h"
#import "Utils.h"
#import "Defaults.h"

@interface CategorySelectController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (nonatomic, weak, readonly) ExpenseLedger *ledger;
@property (nonatomic, copy, readonly) NSArray *orderedCategories;

@end

@implementation CategorySelectController
@synthesize orderedCategories=_orderedCategories;

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

-(NSArray *)orderedCategories {
    if (_orderedCategories == nil) {
        CategoryDisplayOrder catOrder = [Defaults inst].categoryDisplayOrder;
        if (catOrder == CategoryDisplayOrderFrequency) {
            _orderedCategories = self.ledger.categoriesFrequency;
        } else if (catOrder == CategoryDisplayOrderStandard) {
            _orderedCategories = self.ledger.categories;
        } else if (catOrder == CategoryDisplayOrderAlphabetical) {
            _orderedCategories = self.ledger.categoriesAlphabetical;
        } else {
            _orderedCategories = self.ledger.categories;
        }
    }
    return _orderedCategories;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.navigationItem) {
        self.navigationItem.title = @"Categories";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 54;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    static NSString *s = @"    Select Category";
    return s;
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(BOOL)isFullVersion {
    return [Defaults inst].isFullVersion;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isFullVersion]) {
        return self.orderedCategories.count;
    } else {
        return self.orderedCategories.count + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseCategorySelectCell = @"CategorySelectCell";
    static NSString *reuseMoreCategoriesCell = @"MoreCategoriesCell";
    
    UITableViewCell *cell;
    if (![self isFullVersion] && indexPath.row == self.orderedCategories.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:reuseMoreCategoriesCell forIndexPath:indexPath];
        cell.textLabel.text = @"More Categories Available";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        ExpenseCategory *cat = self.orderedCategories[indexPath.row];

        cell = [tableView dequeueReusableCellWithIdentifier:reuseCategorySelectCell forIndexPath:indexPath];
        cell.textLabel.text = cat.name;
        cell.imageView.image = cat.icon32;
    
        if (cat.id == self.cat.id) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Ignore if More Categories row selected.
    if (![self isFullVersion] && indexPath.row == self.orderedCategories.count) {
        return;
    }
    
    ExpenseCategory *selCat = self.orderedCategories[indexPath.row];
    self.cat = selCat;

    if (self.delegate) {
        [self.delegate categorySelectController:self doneSelectCategory:selCat];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (![self isFullVersion] && indexPath.row == self.orderedCategories.count) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Full Category List" message:@"Available in the Full Version." delegate:self cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Take me to Upgrade Screen", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        alertView.tag = 200;
        [alertView show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    static long UpgradeToFullVersionIndex = 1;
    
    if (buttonIndex == UpgradeToFullVersionIndex) {
        [Utils pushStoryboardViewID:@"UpgradeController" storyboard:self.storyboard navController:self.navigationController];
    }
}

@end
