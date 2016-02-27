/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "CategoryBrowserController.h"
#import "UpgradeController.h"

#import "ExpenseModel.h"
#import "Utils.h"
#import "Defaults.h"

@interface CategoryBrowserController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>
@property (nonatomic, weak, readonly) ExpenseLedger *ledger;
@property (nonatomic, copy, readonly) NSArray *orderedCategories;
@property (nonatomic, strong, readonly) UISwipeGestureRecognizer *swipeGesture;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong, readwrite) NSIndexPath *indexPathBeingEdited;

@end

@implementation CategoryBrowserController
@synthesize orderedCategories=_orderedCategories;
@synthesize swipeGesture=_swipeGesture;
@synthesize tapGesture=_tapGesture;

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

-(UISwipeGestureRecognizer *)swipeGesture {
    if (_swipeGesture == nil) {
        _swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeGesture:)];
        _swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft + UISwipeGestureRecognizerDirectionRight;
    }
    return _swipeGesture;
}

-(UITapGestureRecognizer *)tapGesture {
    if (_tapGesture == nil) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGesture:)];
    }
    return _tapGesture;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.navigationItem) {
        self.navigationItem.title = @"Edit Categories";
    }
    
    [self.tableView addGestureRecognizer:self.swipeGesture];
    [self.tableView addGestureRecognizer:self.tapGesture];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _orderedCategories = nil;
    [self.tableView reloadData];
    
    if ([self.tableView numberOfRowsInSection:0] > 0) {
        [self performSelector:@selector(showSampleSwipe:) withObject:self afterDelay:0.35];
    }
}

-(void)showSampleSwipe:(id)sender {
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 54;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    static NSString *s = @"Swipe to edit category";
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
    static NSString *reuseCategoryItemCell = @"CategoryItemCell";
    static NSString *reuseCategoryItemEditCell = @"CategoryItemEditCell";
    static NSString *reuseMoreCategoriesCell = @"MoreCategoriesCell";
    
    UITableViewCell *cell;
    if (![self isFullVersion] && indexPath.row == self.orderedCategories.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:reuseMoreCategoriesCell forIndexPath:indexPath];
        cell.textLabel.text = @"More Categories Available";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        ExpenseCategory *cat = self.orderedCategories[indexPath.row];

        if (self.indexPathBeingEdited != nil && indexPath.row == self.indexPathBeingEdited.row) {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseCategoryItemEditCell forIndexPath:indexPath];
            UITextField *catNameField = (UITextField *)[cell viewWithTag:100];
            catNameField.backgroundColor = [Utils defaultTextHighlightColor];
            catNameField.text = cat.name;
            [catNameField becomeFirstResponder];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseCategoryItemCell forIndexPath:indexPath];
            cell.imageView.image = cat.icon32;
            cell.textLabel.text = cat.name;
            cell.userInteractionEnabled = NO;
        }
    }
    
    return cell;
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

-(BOOL)isEditing {
    if (self.indexPathBeingEdited != nil) {
        return YES;
    } else {
        return NO;
    }
}

-(void)updateNavActionButton {
    if (self.navigationItem) {
        if ([self isEditing]) {
            if (self.navigationItem.rightBarButtonItem == nil) {
                // Add 'Save' nav button.
                UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(selectSave:)];
                self.navigationItem.rightBarButtonItem = bbi;
            }
        } else {
            // Clear nav button.
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
}

-(void)selectSave:(id)sender {
    [self saveCategoryInIndexPath:self.indexPathBeingEdited];
}

-(void)didSwipeGesture:(UISwipeGestureRecognizer *)swipeGesture {
    NSIndexPath *prevIndexPathBeingEdited = self.indexPathBeingEdited;

    [self saveCategoryInIndexPath:self.indexPathBeingEdited];
    
    CGPoint swipePoint = [swipeGesture locationInView:self.tableView];
    NSIndexPath *indexPathSwiped = [self.tableView indexPathForRowAtPoint:swipePoint];
    if (indexPathSwiped == nil) {
        return;
    }

    // Ignore gestures made on 'More Categories' row.
    if (![self isFullVersion] && indexPathSwiped.row == self.orderedCategories.count) {
        return;
    }
    
    if (prevIndexPathBeingEdited == nil || indexPathSwiped.row != prevIndexPathBeingEdited.row) {
        // Reload the editable category name.
        self.indexPathBeingEdited = indexPathSwiped;
        [self updateNavActionButton];
        [self.tableView reloadRowsAtIndexPaths:@[self.indexPathBeingEdited] withRowAnimation:UITableViewRowAnimationRight];
    }
}

-(void)didTapGesture:(UITapGestureRecognizer *)tapGesture {
    [self saveCategoryInIndexPath:self.indexPathBeingEdited];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag == 100) {
        [self saveCategoryInIndexPath:self.indexPathBeingEdited];
    }
    return YES;
}

-(void)saveCategoryInIndexPath:(NSIndexPath *)indexPath {
    if (indexPath == nil) {
        return;
    }

    [self.tableView endEditing:YES];
    
    UITableViewCell *swipedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    UITextField *nameField = (UITextField *)[swipedCell viewWithTag:100];
    NSString *newCatName = nameField.text;
    if (newCatName.length > 0) {
        ExpenseCategory *cat = self.orderedCategories[indexPath.row];
        if (![cat.name isEqualToString:newCatName]) {
            cat.name = newCatName;
            [self.ledger updateCategory:cat];
        }
    }

    // Reload the read-only updated category name.
    self.indexPathBeingEdited = nil;
    [self updateNavActionButton];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

@end
