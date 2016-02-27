/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "SettingsController.h"
#import "YearMultiSelectController.h"
#import "UpgradeController.h"

#import "ExpenseModel.h"
#import "DateHelper.h"
#import "Utils.h"
#import "Defaults.h"

@interface SettingsController () <YearMultiSelectControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, weak, readonly) ExpenseLedger *ledger;
@property (weak, nonatomic) IBOutlet UISegmentedControl *categoryOrderSegmented;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellAboutApp;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellUpgradeStatus;

@end

@implementation SettingsController

-(ExpenseLedger *)ledger {
    return [ExpenseModel ledger];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.navigationItem) {
        self.navigationItem.title = @"Settings";
    }

    [self.categoryOrderSegmented setSelectedSegmentIndex:[Defaults inst].categoryDisplayOrder];
    [self.categoryOrderSegmented addTarget:self action:@selector(categoryOrderChanged:) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppInfo *appInfo = [ExpenseModel appInfo];

    self.cellAboutApp.textLabel.text = appInfo.appName;
    self.cellAboutApp.detailTextLabel.text = [NSString stringWithFormat:@"v%.2f", appInfo.version];
    
    if ([Defaults inst].isFullVersion) {
        self.cellUpgradeStatus.textLabel.text = @"Full Version Unlocked";
        self.cellUpgradeStatus.accessoryType = UITableViewCellAccessoryNone;
        self.cellUpgradeStatus.textLabel.enabled = NO;
        self.cellUpgradeStatus.userInteractionEnabled = NO;
    } else {
        self.cellUpgradeStatus.textLabel.text = @"Upgrade to Full Version";
        self.cellUpgradeStatus.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        self.cellUpgradeStatus.userInteractionEnabled = YES;
    }
    
/*
    UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [buyBtn setFrame:CGRectMake(0, 0, 60, 30)];
    buyBtn.layer.borderWidth = 1;
    buyBtn.layer.cornerRadius = 5;
    buyBtn.layer.borderColor = buyBtn.tintColor.CGColor;
    
    [buyBtn setTitle:@"Buy" forState:UIControlStateNormal];
    self.cellAboutApp.accessoryView = buyBtn;
*/
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"An Upgrade to the Full Version is available." delegate:self cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Take me to Upgrade Screen", nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    [alertView show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    static long UpgradeToFullVersionIndex = 1;
    
    if (buttonIndex == UpgradeToFullVersionIndex) {
        [Utils pushStoryboardViewID:@"UpgradeController" storyboard:self.storyboard navController:self.navigationController];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)categoryOrderChanged:(UISegmentedControl *)sender {
    if (sender.tag == 100) {
        [Defaults inst].categoryDisplayOrder = (CategoryDisplayOrder)sender.selectedSegmentIndex;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}
/*
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 22;
    } else {
        return [super tableView:tableView heightForFooterInSection:section];
    }
}
*/
-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showClearDataYearMultiSelect"]) {
        YearMultiSelectController *yearMultiSelectVC = (YearMultiSelectController *)segue.destinationViewController;
        yearMultiSelectVC.navTitle = @"Clear Data";
        yearMultiSelectVC.header1Title = nil;
        yearMultiSelectVC.header2Title = @"Select Years to Clear Permanently";
        yearMultiSelectVC.actionButtonTitle = @"Delete";
        yearMultiSelectVC.alertPrompt = @"Delete Data?";
        yearMultiSelectVC.alertMessage = @"Years to be deleted:";
        yearMultiSelectVC.alertWarningPrompt = @"This operation cannot be undone.";
        yearMultiSelectVC.delegate = self;
        yearMultiSelectVC.tag = @"erase";
    } else if ([segue.identifier isEqualToString:@"showExportDataYearMultiSelect"]) {
        YearMultiSelectController *yearMultiSelectVC = (YearMultiSelectController *)segue.destinationViewController;
        yearMultiSelectVC.navTitle = @"Export Data";
        yearMultiSelectVC.header1Title = nil;
        yearMultiSelectVC.header2Title = @"Select Years to Export";
        yearMultiSelectVC.actionButtonTitle = @"Export";
        yearMultiSelectVC.alertPrompt = @"Export Data?";
        yearMultiSelectVC.alertMessage = @"Years to be exported:";
        yearMultiSelectVC.delegate = self;
        yearMultiSelectVC.tag = @"export";
    }
}

-(void)yearMultiSelectController:(YearMultiSelectController *)yearMultiSelectVC selectedYears:(NSArray *)selectedYears {
    if ([yearMultiSelectVC.tag isEqualToString:@"erase"]) {
        [self processClearSelectedYears:selectedYears];
    } else if ([yearMultiSelectVC.tag isEqualToString:@"export"]) {
        [self processExportSelectedYears:selectedYears];
    }
}

-(void)processClearSelectedYears:(NSArray *)selectedYears {
    for (NSNumber *yearKey in selectedYears) {
        int year = yearKey.intValue;
        
        NSDate *yearDate = dateFromComponents(1, 1, year);
        [self.ledger deleteExpensesForYearDate:yearDate catId:-1];
    }
    
    // Close Export select view (YearMultiSelectController)
    [self.navigationController popViewControllerAnimated:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Data Cleared" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    [alertView show];
}

-(void)processExportSelectedYears:(NSArray *)selectedYears {
    NSMutableString *yearsCsv = [[NSMutableString alloc] init];

    NSString *csvHeaderLine = @"Date,Description,Amount,Category\n";
    [yearsCsv appendString:csvHeaderLine];
    
    for (NSNumber *yearKey in selectedYears) {
        int year = yearKey.intValue;
        NSDate *yearDate = dateFromComponents(1, 1, year);
        NSArray *yearExpenses = [self.ledger queryExpensesForYearDate:yearDate dateOrder:ExpenseDateAscending catId:-1];

        NSString *yearCsv = [ExpenseLedger csvFromExpenses:yearExpenses];
        [yearsCsv appendString:yearCsv];
    }

//    NSLog(@"yearsCsv:\n%@\n", yearsCsv);

    NSData *yearsData = [Utils dataFromString:yearsCsv];

    [Utils presentSendMailUI:self.navigationController delegate:self subject:@"Expenses export" body:@"Attached file is in comma-separated (csv) format."
                  attachment:yearsData mimeType:@"text/plain" filename:@"expenses_export.csv"];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [Utils handleSendMailResult:self.navigationController successSentMsg:@"Expenses export sent." cancelMsg:@"Export cancelled"
                       errorMsg:@"Error sending export file. Check email and connectivity." result:result error:error];
}

@end
