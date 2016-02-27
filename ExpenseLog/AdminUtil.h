/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

@interface AdminUtil : NSObject
+(BOOL)isTestMode;
+(void)resetExpenseDB;
+(void)addTestExpenses:(int)numExpenses numPastYears:(int)numPastYears;
+(void)SetToLiteVersion;
+(void)SetToFullVersion;

@end
