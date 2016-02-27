/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <MessageUI/MessageUI.h>

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface Utils : NSObject
+(NSString *)filepathFromDocumentsDir:(NSString *)filename;
+(NSString *)filepathFromBundleDir:(NSString *)filename;
+(BOOL)copyFromBundleToDocuments:(NSString *)filename;
+(void)deleteFileFromDocumentsDir:(NSString *)filename;

+(NSString *)formattedCurrencyAmount:(double)amount;
+(NSString *)formattedCurrencyAmount:(double)amount withLocale:(NSLocale *)locale;
+(double)amountFromFormattedCurrencyStr:(NSString *)currencyStr;
+(NSString *)formattedDateRangeWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+(UIColor *)defaultTableHeaderBgColor;
+(UIColor *)defaultTextHighlightColor;
+(UIColor *)defaultTextErrorColor;
+(void)formatToStandardHeaderView:(UIView *)view;

+(NSData *)dataFromString:(NSString *)s;

+(int)randFromMin:(int)min max:(int)max;
+(double)randDoubleFromMin:(double)min max:(double)max;

+(void)presentSendMailUI:(UIViewController *)parentVC delegate:(id<MFMailComposeViewControllerDelegate>)delegate subject:(NSString *)subject body:(NSString *)body
              attachment:(NSData *)attachment mimeType:(NSString *)mimeType filename:(NSString *)filename;
+(void)handleSendMailResult:(UIViewController *)parentVC successSentMsg:(NSString *)successSentMsg cancelMsg:(NSString *)cancelMsg errorMsg:(NSString *)errorMsg
                     result:(MFMailComposeResult)result error:(NSError *)error;

+(void)pushStoryboardViewID:(NSString *)viewID storyboard:(UIStoryboard *)storyboard navController:(UINavigationController *)navVC;
+(void)showTableViewRefreshControl:(UITableView *)tableView refreshControl:(UIRefreshControl *)refresh;
+(void)showModalDialogWithTitle:(NSString *)title message:(NSString *)msg;
@end
