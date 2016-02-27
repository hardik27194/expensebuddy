/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "ExpenseBrowserController.h"

@class BrowserDisplaySelectController;
@protocol BrowserDisplaySelectControllerDelegate <NSObject>
-(void)browserDisplaySelectController:(BrowserDisplaySelectController *)sender doneBrowserDisplayType:(ExpenseBrowserDisplayType)expenseBrowserDisplayType;
@end

@interface BrowserDisplaySelectController : UITableViewController
@property (nonatomic, weak, readwrite) id<BrowserDisplaySelectControllerDelegate> delegate;
@property (nonatomic, assign, readwrite) ExpenseBrowserDisplayType expenseBrowserDisplayType;

@end
