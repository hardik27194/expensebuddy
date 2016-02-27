/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

#import "Utils.h"
#import "DateHelper.h"

@implementation Utils

+(NSString *)filepathFromDocumentsDir:(NSString *)filename {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = documentPaths[0];
    NSString *documentFilepath = [documentDir stringByAppendingPathComponent:filename];

    return documentFilepath;
}

+(NSString *)filepathFromBundleDir:(NSString *)filename {
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
}

+(BOOL)copyFromBundleToDocuments:(NSString *)filename {
    NSString *documentFilepath = [Utils filepathFromDocumentsDir:filename];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentFilepath]) {
        NSString *bundleFilepath = [Utils filepathFromBundleDir:filename];

        // Attempt to copy file from bundle to documents.
        if (![[NSFileManager defaultManager] copyItemAtPath:bundleFilepath toPath:documentFilepath error:nil]) {
            return NO;
        }
    }
    
    return YES;
}

+(void)deleteFileFromDocumentsDir:(NSString *)filename {
    NSString *documentFilepath = [Utils filepathFromDocumentsDir:filename];

    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:documentFilepath error:&error];
    NSLog(@"deleteFileFromDocumentsDir error: %@", error);
}

+(NSString *)formattedCurrencyAmount:(double)amount {
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setLocale:currentLocale];

    [formatter setCurrencyCode:[currentLocale objectForKey:NSLocaleCurrencyCode]];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    return [formatter stringFromNumber:[NSNumber numberWithDouble:amount]];
}

+(NSString *)formattedCurrencyAmount:(double)amount withLocale:(NSLocale *)locale {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setLocale:locale];
    
    [formatter setCurrencyCode:[locale objectForKey:NSLocaleCurrencyCode]];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    return [formatter stringFromNumber:[NSNumber numberWithDouble:amount]];
}


+(double)amountFromFormattedCurrencyStr:(NSString *)currencyStr {
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setLocale:currentLocale];
    
    [formatter setCurrencyCode:[currentLocale objectForKey:NSLocaleCurrencyCode]];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    return [formatter numberFromString:currencyStr].doubleValue;
}

+(NSString *)formattedDateRangeWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    if (startDate != nil && endDate != nil) {
        NSString *rangeStr = [NSString stringWithFormat:@"%@ - %@",
                              dateStringFromDateWithStyle(startDate, NSDateFormatterShortStyle, NSDateFormatterNoStyle),
                              dateStringFromDateWithStyle(endDate, NSDateFormatterShortStyle, NSDateFormatterNoStyle)];
        return rangeStr;    // Ex. '1/1/2015 - 1/31/2015'
    } else {
        return nil;
    }
}

+(UIColor *)defaultTableHeaderBgColor {
    //$$ Need a better way to get this, hardcoded for iOS 7.
    return [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
}

+(UIColor *)defaultTextHighlightColor {
    return [UIColor colorWithRed:255.0f/255.0f green:242.0f/255.0f blue:204.0f/255.0f alpha:1.0];
}

+(UIColor *)defaultTextErrorColor {
    return [UIColor colorWithRed:0.92 green:0.60 blue:0.60 alpha:1.0];
}

// Helper for making all header views comply with standard font, size and casing.
+(void)formatToStandardHeaderView:(UIView *)view {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont systemFontOfSize:12];
        headerView.textLabel.text = [headerView.textLabel.text uppercaseString];
    }
}

+(NSData *)dataFromString:(NSString *)s {
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}

+(int)randFromMin:(int)min max:(int)max {
    return arc4random_uniform(max - min + 1) + min;
}

+(double)randDoubleFromMin:(double)min max:(double)max {
    double f = (double)rand() / RAND_MAX;
    return min + f * (max - min);
}

+(void)presentSendMailUI:(UIViewController *)parentVC delegate:(id<MFMailComposeViewControllerDelegate>)delegate subject:(NSString *)subject body:(NSString *)body
              attachment:(NSData *)attachment mimeType:(NSString *)mimeType filename:(NSString *)filename {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = delegate;
        [mailVC setSubject:subject];
        [mailVC setMessageBody:body isHTML:NO];
        [mailVC addAttachmentData:attachment mimeType:mimeType fileName:filename];
        [parentVC presentViewController:mailVC animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Setup Needed" message:@"Please configure your email account in device settings." delegate:nil
                                                  cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        [alertView show];
    }
}

+(void)handleSendMailResult:(UIViewController *)parentVC successSentMsg:(NSString *)successSentMsg cancelMsg:(NSString *)cancelMsg errorMsg:(NSString *)errorMsg
                     result:(MFMailComposeResult)result error:(NSError *)error {
    if (result == MFMailComposeResultSent) {
        [parentVC dismissViewControllerAnimated:YES completion:nil];
                    
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:successSentMsg message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        [alertView show];
    }
    else if (result == MFMailComposeResultCancelled) {
        [parentVC dismissViewControllerAnimated:YES completion:nil];
                    
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:cancelMsg message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        [alertView show];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        [alertView show];
    }
}

+(void)pushStoryboardViewID:(NSString *)viewID storyboard:(UIStoryboard *)storyboard navController:(UINavigationController *)navVC {
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:viewID];
    [navVC pushViewController:vc animated:YES];
}

+(void)showTableViewRefreshControl:(UITableView *)tableView refreshControl:(UIRefreshControl *)refresh {
    [tableView setContentOffset:CGPointMake(0, -refresh.frame.size.height) animated:YES];
}

+(void)showModalDialogWithTitle:(NSString *)title message:(NSString *)msg {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    [alertView show];
}

@end
