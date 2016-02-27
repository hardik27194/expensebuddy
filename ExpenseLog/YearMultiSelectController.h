/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

@class YearMultiSelectController;
@protocol YearMultiSelectControllerDelegate <NSObject>
-(void)yearMultiSelectController:(YearMultiSelectController *)yearMultiSelectVC selectedYears:(NSArray *)selectedYears;
@end

@interface YearMultiSelectController : UITableViewController
@property (nonatomic, weak, readwrite) id<YearMultiSelectControllerDelegate> delegate;
@property (nonatomic, copy, readwrite) NSString *tag;
@property (nonatomic, copy, readwrite) NSString *navTitle;
@property (nonatomic, copy, readwrite) NSString *header1Title;
@property (nonatomic, copy, readwrite) NSString *header2Title;

@property (nonatomic, copy, readwrite) NSString *actionButtonTitle;
@property (nonatomic, copy, readwrite) NSString *alertPrompt;
@property (nonatomic, copy, readwrite) NSString *alertMessage;
@property (nonatomic, copy, readwrite) NSString *alertWarningPrompt;

@end
