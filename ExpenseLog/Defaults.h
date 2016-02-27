/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

#import "ExpenseBrowserController.h"

typedef enum CategoryDisplayOrder {
    CategoryDisplayOrderStandard=0,
    CategoryDisplayOrderFrequency=1,
    CategoryDisplayOrderAlphabetical=2
} CategoryDisplayOrder;

@interface Defaults : NSObject
+(instancetype)inst;

@property (nonatomic, assign, readwrite) ExpenseBrowserDisplayType expenseBrowserDisplayType;
@property (nonatomic, copy, readwrite) NSDate *customStartDate;
@property (nonatomic, copy, readwrite) NSDate *customEndDate;
@property (nonatomic, assign, readwrite) ExpenseRange expenseRange;
@property (nonatomic, assign, readwrite) int ytdYear;
@property (nonatomic, assign, readwrite) CategoryDisplayOrder categoryDisplayOrder;

-(BOOL)isFullVersion;
-(BOOL)existsPurchasedProductId:(NSString *)productIdentifier;
-(void)addPurchasedProductId:(NSString *)productIdentifier;
-(void)removePurchasedProductId:(NSString *)productIdentifier;

@end
