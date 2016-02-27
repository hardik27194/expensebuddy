//
//  ExpenseModel.m
//  RecordIt
//
//  Created by rob on 4/6/15.
//  Copyright (c) 2015 CAKEsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExpenseModel.h"
#import "DateHelper.h"
#import "DBHelper.h"
#import "Utils.h"
#import "Defaults.h"

@implementation ExpenseCategory
-(instancetype)init {
    self = [super init];
    if (self) {
        self.id = -1;
        self.name = @"";
        self.note = @"";
    }
    return self;
}

-(NSString *)description {
    NSString *s = [NSString stringWithFormat:@"{ExpenseCategory - id:%d, name:%@}\n", self.id, self.name];
    return s;
}

-(UIImage *)icon32 {
    NSString *iconFilename = [NSString stringWithFormat:@"cat%d", self.id];
    return [UIImage imageNamed:iconFilename];
}

@end


@implementation Expense
-(instancetype)init {
    self = [super init];
    if (self) {
        self.name = @"";
        self.amount = 0.0;
        self.date = nil;
        self.note = @"";
        self.cat = nil;
    }
    return self;
}

-(NSString *)description {
    NSString *s = [NSString stringWithFormat:@"{Expense - name:%@, amount:%f, date:%@}\n", self.name, self.amount, sqlDatetimeStringFromDate(self.date)];
    return s;
}

-(Expense *)clone {
    Expense *clonedExpense = [[Expense alloc] init];
    clonedExpense.name = self.name;
    clonedExpense.amount = self.amount;
    clonedExpense.date = self.date;
    clonedExpense.note = self.note;
    clonedExpense.cat = self.cat;
    return clonedExpense;
}

@end

@interface ExpenseLedger() {
    sqlite3 *_dbHandle;
}

@end

static NSString *_defaultLedgerDBFilename = @"expensedb.sqlite3";

@implementation ExpenseLedger
@synthesize categories = _categories;
@synthesize categoriesAlphabetical=_categoriesAlphabetical;
@synthesize categoriesFrequency=_categoriesFrequency;

-(NSArray *)categories {
    if (_categories == nil) {
        [self loadCategoriesFromDB];
    }
    
    return _categories;
}

// Categories sorted in alphabetical order.
-(NSArray *)categoriesAlphabetical {
    if (_categoriesAlphabetical == nil) {
        _categoriesAlphabetical = [self.categories sortedArrayUsingComparator:^NSComparisonResult(ExpenseCategory *catA, ExpenseCategory *catB) {
            NSString *nameA = catA.name;
            NSString *nameB = catB.name;
            
            // Category names "(Custom N)" should always appear last alphabetically.
            if ([nameA hasPrefix:@"("]) {
                nameA = [NSString stringWithFormat:@"zzz%@", nameA];
            }
            if ([nameB hasPrefix:@"("]) {
                nameB = [NSString stringWithFormat:@"zzz%@", nameB];
            }
            
            return [nameA compare:nameB];
        }];
    }
    return _categoriesAlphabetical;
}

// Categories sorted according to frequency of use in expenses.
-(NSArray *)categoriesFrequency {
    if (_categoriesFrequency == nil) {
        _categoriesFrequency = [self allCategoriesSortedByMostFrequent];
    }
    return _categoriesFrequency;
}

-(ExpenseCategory *)defaultCategory {
    return [self categoryFromId:0];
}

-(void)dealloc {
    if (_dbHandle != nil) {
        [self close];
    }
}

-(void)close {
    [DBHelper closeDBHandle:_dbHandle];
    _dbHandle = nil;
}

-(instancetype)initWithDBFilename:(NSString *)dbFilename id:(NSString *)id name:(NSString *)name {
    self = [super init];
    if (self) {
        self.dbFilename = dbFilename;
        self.id = id;
        self.name = name;
    }

    // Open db file and load expense records from it.
    if ([DBHelper openDBFilename:dbFilename dbHandle:&_dbHandle] == SQLITE_OK) {
        [self loadDBRecords];
    } else {
        NSLog(@"Error opening DB file:%@.", dbFilename);
    }
    
    return self;
}

-(instancetype)init {
    return [self initWithDBFilename:_defaultLedgerDBFilename id:@"" name:@""];
}

void ErrorDBNotOpen() {
    NSLog(@"DB Error: Database file not open.");
}

void ErrorDBSQL(NSString *sql) {
    NSLog(@"DB Error: Running statement '%@'", sql);
}

-(ExpenseCategory *)categoryFromId:(int)id {
    for (ExpenseCategory *cat in self.categories) {
        if (cat.id == id) {
            return cat;
        }
    }
    
    return nil;
}

-(void)loadCategoriesFromDB {
    sqlite3_stmt *stmt;
    
    NSString *selectCat;
    if ([Defaults inst].isFullVersion) {
        selectCat = @"SELECT id, name, note FROM expense_cat WHERE inactive = 0 ORDER BY id";
    } else {
        selectCat = @"SELECT id, name, note FROM expense_cat WHERE inactive = 0 AND (id < 4) ORDER BY id";
    }
    
    if ([DBHelper openStatementFromSQL:selectCat dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(selectCat);
        return;
    }
    
    NSMutableArray *resultCategories = [[NSMutableArray alloc] init];
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const int id = (const int)sqlite3_column_int(stmt, 0);
        const char *nameChar = (const char *)sqlite3_column_text(stmt, 1);
        const char *noteChar = (const char *)sqlite3_column_text(stmt, 2);
        
        if (nameChar == nil) nameChar = "";
        NSString *name = [NSString stringWithUTF8String:nameChar];
        
        if (noteChar == nil) noteChar = "";
        NSString *note = [NSString stringWithUTF8String:noteChar];
        
        ExpenseCategory *cat = [[ExpenseCategory alloc] init];
        cat.id = id;
        cat.name = name;
        cat.note = note;
        [resultCategories addObject:cat];
    }
    
    _categories = [[NSMutableArray alloc] initWithArray:resultCategories];

    // Reload these queries.
    _categoriesAlphabetical = nil;
    _categoriesFrequency = nil;
    
    [DBHelper closeStatement:stmt];
}

-(void)clearItems {
    _categories = [[NSMutableArray alloc] init];
}

-(void)loadDBRecords {
    if (_dbHandle == nil) {
        ErrorDBNotOpen();
        return;
    }
    
    [self loadCategoriesFromDB];
}

-(NSArray *)queryExpensesWithWhereClause:(NSString *)where orderByClause:(NSString *)orderBy {
    NSMutableArray *retExpenses = [[NSMutableArray alloc] init];

    NSString *query = @"SELECT date, catid, name, amount, note FROM expense";
    if (where) {
        query = [NSString stringWithFormat:@"%@ WHERE %@", query, where];
    }
    if (orderBy) {
        query = [NSString stringWithFormat:@"%@ ORDER BY %@", query, orderBy];
    }
    NSLog(@"queryExpenses: Running query '%@'.", query);
    
    sqlite3_stmt *stmt;
    if ([DBHelper openStatementFromSQL:query dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(query);
    }
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *dateChar = (const char *)sqlite3_column_text(stmt, 0);
        const int catid = (const int)sqlite3_column_int(stmt, 1);
        const char *nameChar = (const char *)sqlite3_column_text(stmt, 2);
        double amount = sqlite3_column_double(stmt, 3);
        const char *noteChar = (const char *)sqlite3_column_text(stmt, 4);
        
        if (dateChar == nil) dateChar = "";
        NSDate *date = dateFromSqlDatetimeString([NSString stringWithUTF8String:dateChar]);
        
        if (nameChar == nil) nameChar = "";
        NSString *name = [NSString stringWithUTF8String:nameChar];
        
        if (noteChar == nil) noteChar = "";
        NSString *note = [NSString stringWithUTF8String:noteChar];
        
        Expense *expense = [[Expense alloc] init];
        expense.date = date;
        expense.cat = [self categoryFromId:catid];
        expense.name = name;
        expense.amount = amount;
        expense.note = note;
        [retExpenses addObject:expense];
    }
    
    [DBHelper closeStatement:stmt];
    
    return retExpenses;
}

NSString *dateOrderByClause(ExpenseDateOrder expenseDateOrder) {
    static NSString *dateOrderByAsc = @"date asc";
    static NSString *dateOrderByDesc = @"date desc";
    
    if (expenseDateOrder == ExpenseDateAscending) {
        return dateOrderByAsc;
    } else {
        return dateOrderByDesc;
    }
}

-(NSArray *)queryExpensesForDate:(NSDate *)date dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId {
    NSDate *baseDate = dateStrippedTime(date);
    NSDate *baseDateNextDay = dateNextDay(baseDate);

    NSString *where = [NSString stringWithFormat:@"date >= '%@' AND date < '%@'", sqlDatetimeStringFromDate(baseDate), sqlDatetimeStringFromDate(baseDateNextDay)];
    if (catId != -1) {
        where = [NSString stringWithFormat:@"%@ AND catid = %d", where, catId];
    }

    return [self queryExpensesWithWhereClause:where orderByClause:dateOrderByClause(expenseDateOrder)];
}

-(NSArray *)queryExpensesFromMinDate:(NSDate *)minDate inclMaxDate:(NSDate *)maxDate dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId {
    NSDate *qMinDate = dateStrippedTime(minDate);
    NSDate *qMaxDate = dateStrippedTime(maxDate);
    NSDate *qMaxDateNextDay = dateNextDay(qMaxDate);

    NSString *where = [NSString stringWithFormat:@"date >= '%@' AND date < '%@'", sqlDatetimeStringFromDate(qMinDate), sqlDatetimeStringFromDate(qMaxDateNextDay)];
    if (catId != -1) {
        where = [NSString stringWithFormat:@"%@ AND catid = %d", where, catId];
    }
    
    return [self queryExpensesWithWhereClause:where orderByClause:dateOrderByClause(expenseDateOrder)];
}

-(NSArray *)queryExpensesFromMinDate:(NSDate *)minDate exclMaxDate:(NSDate *)maxDate dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId {
    NSDate *qMinDate = dateStrippedTime(minDate);
    NSDate *qMaxDate = dateStrippedTime(maxDate);
    
    NSString *where = [NSString stringWithFormat:@"date >= '%@' AND date < '%@'", sqlDatetimeStringFromDate(qMinDate), sqlDatetimeStringFromDate(qMaxDate)];
    if (catId != -1) {
        where = [NSString stringWithFormat:@"%@ AND catid = %d", where, catId];
    }
    
    return [self queryExpensesWithWhereClause:where orderByClause:dateOrderByClause(expenseDateOrder)];
}

-(NSArray *)queryExpensesForMonthDate:(NSDate *)monthDate dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId {
    NSDate *firstDayOfMonth = dateMonthFirstDay(monthDate);
    NSDate *lastDayOfMonth = dateMonthLastDay(monthDate);
    
    return [self queryExpensesFromMinDate:firstDayOfMonth exclMaxDate:dateNextDay(lastDayOfMonth) dateOrder:expenseDateOrder catId:catId];
}

-(NSArray *)queryExpensesForYearDate:(NSDate *)yearDate dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId {
    NSArray *expensesForYear = [self queryExpensesFromMinDate:dateYearFirstDay(yearDate) exclMaxDate:dateNextDay(dateYearLastDay(yearDate))
                                                        dateOrder:expenseDateOrder catId:-1];
    return expensesForYear;
}

-(BOOL)deleteExpensesWithWhereClause:(NSString *)where {
    NSString *sql = @"DELETE FROM expense";
    if (where) {
        sql = [NSString stringWithFormat:@"%@ WHERE %@", sql, where];
    }
    NSLog(@"deleteExpenses: Running sql '%@'.", sql);
    
    sqlite3_stmt *stmt;
    if ([DBHelper execStatementFromSQL:sql dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(sql);
        return false;
    }
    
    return true;
}

-(BOOL)deleteExpensesFromMinDate:(NSDate *)minDate exclMaxDate:(NSDate *)maxDate catId:(int)catId {
    NSDate *qMinDate = dateStrippedTime(minDate);
    NSDate *qMaxDate = dateStrippedTime(maxDate);
    
    NSString *where = [NSString stringWithFormat:@"date >= '%@' AND date < '%@'", sqlDatetimeStringFromDate(qMinDate), sqlDatetimeStringFromDate(qMaxDate)];
    if (catId != -1) {
        where = [NSString stringWithFormat:@"%@ AND catid = %d", where, catId];
    }
    
    return [self deleteExpensesWithWhereClause:where];
}

-(BOOL)deleteExpensesForYearDate:(NSDate *)yearDate catId:(int)catId {
    return[self deleteExpensesFromMinDate:dateYearFirstDay(yearDate) exclMaxDate:dateNextDay(dateYearLastDay(yearDate)) catId:-1];
}

-(NSArray *)queryYearsContainingExpenses {
    sqlite3_stmt *stmt;
    
    NSString *selectYears = @"SELECT DISTINCT CAST(strftime('%Y', date) as int) as year FROM expense ORDER BY date";
    if ([DBHelper openStatementFromSQL:selectYears dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(selectYears);
        return [[NSArray alloc] init];
    }
    
    NSMutableArray *yearsContaingExpenses = [[NSMutableArray alloc] init];
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const int year = (const int)sqlite3_column_int(stmt, 0);
        if (year > 1000) {
            [yearsContaingExpenses addObject:[NSNumber numberWithInt:year]];
        }
    }
    
    [DBHelper closeStatement:stmt];

    return yearsContaingExpenses;
}

TotalQtyAmount TotalQtyAmountMake(int qty, double amount) {
    TotalQtyAmount rec;
    rec.qty = qty;
    rec.amount = amount;
    return rec;
}

-(TotalQtyAmount)queryTotalExpenseAmountForStartDate:(NSDate *)startDate inclEndDate:(NSDate *)endDate catId:(int)catId {
    NSString *catWhere = @"";
    if (catId != -1) {
        catWhere = [NSString stringWithFormat:@" AND catId = %d", catId];
    }
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*), SUM(amount) FROM expense WHERE date >= '%@' AND date < '%@' %@",
                       sqlDatetimeStringFromDate(startDate), sqlDatetimeStringFromDate(dateNextDay(endDate)), catWhere];
    
    sqlite3_stmt *stmt;
    if ([DBHelper openStatementFromSQL:query dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(query);
    }
    
    int count = 0;
    double totalAmount = 0.0f;
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        count = sqlite3_column_int(stmt, 0);
        totalAmount = sqlite3_column_double(stmt, 1);
    }

    [DBHelper closeStatement:stmt];
    
    return TotalQtyAmountMake(count, totalAmount);
}

-(TotalQtyAmount)queryTotalExpenseAmountForYear:(int)year {
    NSDate *yearFirstDay = dateFromComponents(1, 1, year);
    NSDate *yearLastDay = dateFromComponents(12, 31, year);
    return [self queryTotalExpenseAmountForStartDate:yearFirstDay inclEndDate:yearLastDay catId:-1];
}

-(TotalQtyAmount)queryTotalExpenseForMonthDate:(NSDate *)monthDate {
    NSDate *monthLastDay = dateMonthLastDay(monthDate);
    return [self queryTotalExpenseAmountForStartDate:monthDate inclEndDate:monthLastDay catId:-1];
}

NSNumber *keyForCategory(ExpenseCategory *cat) {
    return [NSNumber numberWithInt:cat.id];
}

NSDictionary *categorySummariesDictionaryFromExpenses(NSArray *expenses) {
    NSMutableDictionary *categorySummaries = [[NSMutableDictionary alloc] init];
    
    for (Expense *expense in expenses) {
        NSNumber *catKey = keyForCategory(expense.cat);
        CategorySummary *categorySummary = [categorySummaries objectForKey:catKey];
        
        if (categorySummary == nil) {
            CategorySummary *categorySummary = [[CategorySummary alloc] init];
            categorySummary.cat = expense.cat;
            categorySummary.numExpenseTransactions = 1;
            categorySummary.totalExpenseAmount = expense.amount;
            
            categorySummaries[catKey] = categorySummary;
        } else {
            categorySummary.numExpenseTransactions = categorySummary.numExpenseTransactions + 1;
            categorySummary.totalExpenseAmount = categorySummary.totalExpenseAmount + expense.amount;
        }
    }
    
    return categorySummaries;
}

NSArray *categorySummariesFromExpenses(NSArray *expenses, CategorySummariesOrderByType orderBy) {
    NSDictionary *categorySummaries = categorySummariesDictionaryFromExpenses(expenses);
    NSMutableArray *unorderedCategorySummaries = [NSMutableArray arrayWithArray:categorySummaries.allValues];
    
    // Return sorted category subtotals from highest amount to lowest amount.
    NSArray *orderedCategorySummaries = [unorderedCategorySummaries sortedArrayUsingComparator:^NSComparisonResult(CategorySummary *categorySummaryA, CategorySummary *categorySummaryB) {
        if (orderBy == CategorySummariesOrderByExpenseTotals) {
            if (categorySummaryA.totalExpenseAmount > categorySummaryB.totalExpenseAmount) {
                return NSOrderedAscending;
            } else if (categorySummaryA.totalExpenseAmount < categorySummaryB.totalExpenseAmount) {
                return NSOrderedDescending;
            }
        } else if (orderBy == CategorySummariesOrderByCategory) {
            if (categorySummaryA.cat.id > categorySummaryB.cat.id) {
                return NSOrderedAscending;
            } else if (categorySummaryA.cat.id < categorySummaryB.cat.id) {
                return NSOrderedDescending;
            }
        }

        return NSOrderedSame;
    }];
    
    return orderedCategorySummaries;
}

BOOL expenseInExcludedCategory(Expense *expense, NSArray *excludedCategories) {
    if (excludedCategories == nil) {
        return false;
    }
    
    for (ExpenseCategory *cat in excludedCategories) {
        if (expense.cat.id == cat.id) {
            return true;
        }
    }
    
    return false;
}

+(double)totalCostFromExpenses:(NSArray *)expenses excludedCategories:(NSArray *)excludedCategories {
    double totalCost = 0.0f;
    
    for (Expense *expense in expenses) {
        if (!expenseInExcludedCategory(expense, excludedCategories)) {
            totalCost += expense.amount;
        }
    }
    
    return totalCost;
}

// Return array of categories sorted by how often they appear in expense transactions from most frequent to least.
-(NSArray *)allCategoriesSortedByMostFrequent {
    NSString *restrictWhere;
    if ([Defaults inst].isFullVersion == NO) {
        restrictWhere = @"WHERE expense_cat.inactive = 0 AND (expense_cat.id < 4)";
    } else {
        restrictWhere = @"";
    }
    
    NSString *query = [NSString stringWithFormat:
                       @"SELECT expense_cat.id, COUNT(expense.catid) as count_trans FROM expense_cat LEFT JOIN expense ON expense_cat.id = expense.catid %@ GROUP BY expense_cat.id ORDER BY count_trans DESC", restrictWhere];
    
    sqlite3_stmt *stmt;
    if ([DBHelper openStatementFromSQL:query dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(query);
    }
    
    NSMutableArray *categories = [[NSMutableArray alloc] initWithCapacity:self.categories.count];

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int catid = sqlite3_column_int(stmt, 0);

        ExpenseCategory *cat = [self categoryFromId:catid];
        [categories addObject:cat];
    }
    
    [DBHelper closeStatement:stmt];
    
    return categories;
}

NSString *transformCsvItem(NSString *s) {
    // Csv field formatting rules: https://en.wikipedia.org/wiki/Comma-separated_values#Basic_rules_and_examples

    BOOL hasEmbeddedComma = [s containsString:@","];
    BOOL hasEmbeddedQuote = [s containsString:@"\""];
    BOOL hasEmbeddedLineBreak = [s containsString:@"\n"];
    
    // Fields with embedded double-quote chars must be represented with a pair of double-quote chars.
    if (hasEmbeddedQuote) {
        s = [s stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    }
    
    // Fields with embedded commas must be quoted.
    // Fields with embedded line breaks must be quoted.
    // Fields with embedded double-quote chars must be quoted.
    if (hasEmbeddedComma || hasEmbeddedQuote || hasEmbeddedLineBreak) {
        s = [NSString stringWithFormat:@"\"%@\"", s];
    }
    
    return s;
}

+(NSString *)csvFromExpenses:(NSArray *)expenses {
    NSMutableString *csv = [[NSMutableString alloc] init];

    for (Expense *expense in expenses) {
        NSString *csvLine = [NSString stringWithFormat:@"%@,%@,%.2f,%@\n",
                             transformCsvItem(sqlDateStringFromDate(expense.date)),
                             transformCsvItem(expense.name),
                             expense.amount,
                             transformCsvItem(expense.cat.name)
                             ];
        [csv appendString:csvLine];
    }
    
    return csv;
}

// Clear the 'was expense modified' dirty bit. This can be used to keep track of whether expenses need to be requeried
// depending on whether an add/modify/delete expense operation was performed.
-(void)clearWasExpenseModified {
    _wasExpenseModified = NO;
}

-(BOOL)deleteExpense:(Expense *)expense {
    sqlite3_stmt *stmt;
    
    NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM expense WHERE date = '%@' AND catid=%d AND name='%@' AND amount=%f",
                           sqlDatetimeStringFromDate(expense.date), expense.cat.id, [DBHelper escapeQuotesFromString:expense.name], expense.amount];
    NSLog(@"deleteExpense: Running query '%@'.", deleteSql);
    if ([DBHelper execStatementFromSQL:deleteSql dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(deleteSql);
        return false;
    }

    _wasExpenseModified = YES;
    
    return true;
}

-(BOOL)insertExpense:(Expense *)expense {
    sqlite3_stmt *stmt;

    NSString *insertSql = [NSString stringWithFormat:@"INSERT INTO expense (date, catid, name, amount, note) VALUES ('%@', %d, '%@', %f, '%@')",
                           sqlDatetimeStringFromDate(expense.date), expense.cat.id, [DBHelper escapeQuotesFromString:expense.name], expense.amount,
                                expense.note? [DBHelper escapeQuotesFromString:expense.note] : @""];
    NSLog(@"insertExpense: Running query '%@'.", insertSql);
    if ([DBHelper execStatementFromSQL:insertSql dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(insertSql);
        return false;
    }
    
    // Category assignment has changed, so cat frequency sorting needs to be requeried.
    _categoriesFrequency = nil;
    
    _wasExpenseModified = YES;
    
    return true;
}

-(BOOL)updatePrevExpense:(Expense *)prevExpense withNewExpense:(Expense *)newExpense {
    if (![self deleteExpense:prevExpense]) {
        return false;
    }
    
    if (![self insertExpense:newExpense]) {
        return false;
    }
    
    // Category assignment has changed, so cat frequency sorting needs to be requeried.
    if (prevExpense.cat.id != newExpense.cat.id) {
        _categoriesFrequency = nil;
    }
    
    _wasExpenseModified = YES;
    
    return true;
}

-(BOOL)updateCategory:(ExpenseCategory *)updatedCat {
    sqlite3_stmt *stmt;
    
    NSString *updateSql = [NSString stringWithFormat:@"UPDATE expense_cat SET name='%@' WHERE id=%d", updatedCat.name, updatedCat.id];

    NSLog(@"updateCategory: Running query '%@'.", updateSql);
    if ([DBHelper execStatementFromSQL:updateSql dbHandle:_dbHandle statement:&stmt] != SQLITE_OK) {
        ErrorDBSQL(updateSql);
        return false;
    }

    // Category name may have changed, so alphabetical sorting needs to be requeried.
    _categoriesAlphabetical = nil;
    
    return true;
}

@end

@interface AppInfo () {
}
@end

@implementation AppInfo
@end

@interface ExpenseModel () {
}
@end

@implementation ExpenseModel
static ExpenseLedger *_ledger = nil;
static AppInfo *_appInfo = nil;

+(void)copyExpenseDBFileToDocuments {
    [Utils copyFromBundleToDocuments:_defaultLedgerDBFilename];
}

+(void)resetExpenseDBFile {
    // Make sure expense db file is closed.
    if (_ledger != nil) {
        [_ledger close];
        _ledger = nil;
    }
    
    // Restore original expense db file from bundle into documents.
    [Utils deleteFileFromDocumentsDir:_defaultLedgerDBFilename];
    [ExpenseModel copyExpenseDBFileToDocuments];
}

+(ExpenseLedger *)ledger {
    if (_ledger == nil) {
        _ledger = [[ExpenseLedger alloc] init];
    }
    return _ledger;
}

+(AppInfo *)appInfo {
    if (_appInfo == nil) {
        _appInfo = [[AppInfo alloc] init];
        _appInfo.version = 1.01f;
        _appInfo.fullVersionProductIdentifier = @"com.robdlc.expensebuddy.unlockfull";
        _appInfo.appName = @"Expense Buddy";
        _appInfo.isTestMode = NO;
    }
    
    return _appInfo;
}

@end

@implementation CategorySummary
@end

@implementation ExpenseUtils
+(NSArray *)categorySummariesFromExpenses:(NSArray *)expenses orderBy:(CategorySummariesOrderByType)orderBy {
    return categorySummariesFromExpenses(expenses, orderBy);
}

@end