/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "AdminUtil.h"
#import "Utils.h"
#import "ExpenseModel.h"
#import "DateHelper.h"
#import "Defaults.h"

@implementation AdminUtil

NSString *randomPhrase() {
    static NSArray *items;

    items = [NSArray arrayWithObjects:
                             @"starbucks", @"dunkin' donuts", @"Coffee, Tea, and Ice Cream cafe",
                             @"Kenny Rogers", @"parking", @"\"Sherlock Holmes\"", @"jeepney ride",
                             @"bus", @"taxi", @"McDonald's", @"Jollibee",
                             @"the", @"and", @"a"
                            , nil];
    
    int maxWords = 20;
    int numWords = [Utils randFromMin:1 max:maxWords];
    
    NSMutableString *phrase = [[NSMutableString alloc] init];
    for (int i=0; i < numWords; i++) {
        NSString *randomItem = items[[Utils randFromMin:0 max:(int)items.count-1]];
        [phrase appendString:randomItem];
        
        if (i < numWords-1) {
            [phrase appendString:@" "];
        }
    }
    
    return phrase;
}

+(BOOL)isTestMode {
    return [ExpenseModel appInfo].isTestMode;
}

+(void)resetExpenseDB {
    [ExpenseModel resetExpenseDBFile];
}

+(void)addTestExpenses:(int)numExpenses numPastYears:(int)numPastYears {
    ExpenseLedger *ledger = [ExpenseModel ledger];
    
    Expense *expense;

    for (int i=0; i < numExpenses; i++) {
        expense = [[Expense alloc] init];
        expense.name = randomPhrase();
        expense.amount = [Utils randDoubleFromMin:0.01 max:100000.0f];
        expense.cat = ledger.categories[[Utils randFromMin:0 max:(int)ledger.categories.count-1]];
        expense.date = randomDatetime(numPastYears);

        [ledger insertExpense:expense];
    }
}

+(void)SetToLiteVersion {
    [[Defaults inst] removePurchasedProductId:[ExpenseModel appInfo].fullVersionProductIdentifier];
}

+(void)SetToFullVersion {
    [[Defaults inst] addPurchasedProductId:[ExpenseModel appInfo].fullVersionProductIdentifier];
}


@end
