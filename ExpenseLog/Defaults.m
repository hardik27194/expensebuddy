/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "Defaults.h"
#import "ExpenseModel.h"
#import "ExpenseBrowserController.h"

@interface Defaults () {
    
}

@property (nonatomic, strong, readonly) NSUserDefaults* userDefaults;

@end


@implementation Defaults
@synthesize userDefaults=_userDefaults;

static NSString *_keyExpenseBrowserDisplayType = @"ExpenseBrowserDisplayType";
static NSString *_keyCustomStartDate = @"CustomStartDate";
static NSString *_keyCustomEndDate = @"CustomEndDate";
static NSString *_keyExpenseRange = @"ExpenseRange";
static NSString *_keyYtdYear = @"YtdYear";
static NSString *_keyCategoryDisplayOrder = @"CategoryDisplayOrder";

+(instancetype)inst {
    static Defaults *_defaults = nil;
    
    if (_defaults == nil) {
        _defaults = [[Defaults alloc] init];
    }
    return _defaults;
}

-(NSUserDefaults *)userDefaults {
    if (_userDefaults == nil) {
        // Initial settings to use the very first time the app is run.
        NSDictionary *factorySettings =
        @{
          _keyExpenseBrowserDisplayType: @(ExpenseBrowserDisplayExpenses),
          _keyExpenseRange: @(ExpenseRangePast10Days)
        };
        
        _userDefaults = [NSUserDefaults standardUserDefaults];
        [_userDefaults registerDefaults:factorySettings];
    }
    return _userDefaults;
}

-(ExpenseBrowserDisplayType)expenseBrowserDisplayType {
    return (ExpenseBrowserDisplayType)[self.userDefaults integerForKey:_keyExpenseBrowserDisplayType];
}
-(void)setExpenseBrowserDisplayType:(ExpenseBrowserDisplayType)expenseBrowserDisplayType {
    [self.userDefaults setInteger:expenseBrowserDisplayType forKey:_keyExpenseBrowserDisplayType];
}

-(NSDate *)customStartDate {
    return (NSDate *)[self.userDefaults objectForKey:_keyCustomStartDate];
}
-(void)setCustomStartDate:(NSDate *)customStartDate {
    [self.userDefaults setObject:customStartDate forKey:_keyCustomStartDate];
}

-(NSDate *)customEndDate {
    return (NSDate *)[self.userDefaults objectForKey:_keyCustomEndDate];
}
-(void)setCustomEndDate:(NSDate *)customEndDate {
    [self.userDefaults setObject:customEndDate forKey:_keyCustomEndDate];
}

-(ExpenseRange)expenseRange {
    return (ExpenseRange)[self.userDefaults integerForKey:_keyExpenseRange];
}
-(void)setExpenseRange:(ExpenseRange)expenseRange {
    [self.userDefaults setInteger:expenseRange forKey:_keyExpenseRange];
}

-(int)ytdYear {
    return (int)[self.userDefaults integerForKey:_keyYtdYear];
}
-(void)setYtdYear:(int)ytdYear {
    [self.userDefaults setInteger:ytdYear forKey:_keyYtdYear];
}

-(CategoryDisplayOrder)categoryDisplayOrder {
    return (CategoryDisplayOrder)[self.userDefaults integerForKey:_keyCategoryDisplayOrder];
}
-(void)setCategoryDisplayOrder:(CategoryDisplayOrder)categoryDisplayOrder {
    [self.userDefaults setInteger:categoryDisplayOrder forKey:_keyCategoryDisplayOrder];
}

-(BOOL)isFullVersion {
//    return [self existsPurchasedProductId:[ExpenseModel appInfo].fullVersionProductIdentifier];

    // Full version unlocked now that we're open source!
    return true;
}

-(NSString *)productIdentifierKey:(NSString *)productIdentifier {
    return [NSString stringWithFormat:@"keyProductIdentifier_%@", productIdentifier];
}
-(BOOL)existsPurchasedProductId:(NSString *)productIdentifier {
    NSString *key = [self productIdentifierKey:productIdentifier];
    return [self.userDefaults boolForKey:key];
}
-(void)addPurchasedProductId:(NSString *)productIdentifier {
    NSString *key = [self productIdentifierKey:productIdentifier];
    [self.userDefaults setBool:YES forKey:key];
    
    [[ExpenseModel ledger] loadCategoriesFromDB];
}
-(void)removePurchasedProductId:(NSString *)productIdentifier {
    NSString *key = [self productIdentifierKey:productIdentifier];
    [self.userDefaults setBool:NO forKey:key];

    [[ExpenseModel ledger] loadCategoriesFromDB];
}
@end
