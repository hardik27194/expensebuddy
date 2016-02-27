//
//  ExpenseModel.h
//  RecordIt
//
//  Created by rob on 4/6/15.
//  Copyright (c) 2015 CAKEsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ExpenseDateAscending=0,
    ExpenseDateDescending
} ExpenseDateOrder;

@interface ExpenseCategory: NSObject
@property (nonatomic, assign) int id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *note;

-(UIImage *)icon32;

@end

@interface Expense: NSObject
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, weak) ExpenseCategory *cat;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double amount;
@property (nonatomic, copy) NSString *note;

-(Expense *)clone;
@end

typedef struct TotalQtyAmount {
    int qty;
    double amount;
} TotalQtyAmount;

TotalQtyAmount TotalQtyAmountMake(int qty, double amount);

@interface ExpenseLedger: NSObject
@property (nonatomic, copy) NSString *dbFilename;
@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly, strong) NSArray *categories;
@property (nonatomic, readonly, strong) NSArray *categoriesAlphabetical;
@property (nonatomic, readonly, strong) NSArray *categoriesFrequency;
@property (nonatomic, readonly, assign) BOOL wasExpenseModified;

-(instancetype)initWithDBFilename:(NSString *)dbFilename id:(NSString *)id name:(NSString *)name;
-(void)close;

-(void)clearItems;
-(void)loadDBRecords;
-(void)loadCategoriesFromDB;
-(ExpenseCategory *)defaultCategory;
-(void)clearWasExpenseModified;
-(BOOL)deleteExpense:(Expense *)expense;
-(BOOL)insertExpense:(Expense *)expense;
-(BOOL)updatePrevExpense:(Expense *)prevExpense withNewExpense:(Expense *)newExpense;
-(BOOL)updateCategory:(ExpenseCategory *)updatedCat;

-(NSArray *)queryExpensesWithWhereClause:(NSString *)where orderByClause:(NSString *)orderBy;
-(NSArray *)queryExpensesForDate:(NSDate *)date dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId;
-(NSArray *)queryExpensesFromMinDate:(NSDate *)minDate inclMaxDate:(NSDate *)maxDate dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId;
-(NSArray *)queryExpensesFromMinDate:(NSDate *)minDate exclMaxDate:(NSDate *)maxDate dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId;
-(NSArray *)queryExpensesForMonthDate:(NSDate *)monthDate dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId;
-(NSArray *)queryExpensesForYearDate:(NSDate *)yearDate dateOrder:(ExpenseDateOrder)expenseDateOrder catId:(int)catId;

-(BOOL)deleteExpensesWithWhereClause:(NSString *)where;
-(BOOL)deleteExpensesFromMinDate:(NSDate *)minDate exclMaxDate:(NSDate *)maxDate catId:(int)catId;
-(BOOL)deleteExpensesForYearDate:(NSDate *)yearDate catId:(int)catId;

-(NSArray *)queryYearsContainingExpenses;
-(TotalQtyAmount)queryTotalExpenseAmountForStartDate:(NSDate *)startDate inclEndDate:(NSDate *)endDate catId:(int)catId;
-(TotalQtyAmount)queryTotalExpenseAmountForYear:(int)year;
-(TotalQtyAmount)queryTotalExpenseForMonthDate:(NSDate *)monthDate;

+(double)totalCostFromExpenses:(NSArray *)expenses excludedCategories:(NSArray *)excludedCategories;
+(NSString *)csvFromExpenses:(NSArray *)expenses;

@end

@interface AppInfo: NSObject
@property (nonatomic, readwrite, assign) double version;
@property (nonatomic, readwrite, copy) NSString *appName;
@property (nonatomic, readwrite, copy) NSString *fullVersionProductIdentifier;
@property (nonatomic, readwrite, assign) BOOL isTestMode;

@end


@interface ExpenseModel: NSObject
+(void)copyExpenseDBFileToDocuments;
+(void)resetExpenseDBFile;
+(ExpenseLedger *)ledger;
+(AppInfo *)appInfo;

@end

@interface CategorySummary: NSObject
@property (nonatomic, weak, readwrite) ExpenseCategory *cat;
@property (nonatomic, assign, readwrite) int numExpenseTransactions;
@property (nonatomic, assign, readwrite) double totalExpenseAmount;

@end

typedef enum CategorySummariesOrderByType {
    CategorySummariesOrderByCategory=0,
    CategorySummariesOrderByExpenseTotals
} CategorySummariesOrderByType;

@interface ExpenseUtils: NSObject
+(NSArray *)categorySummariesFromExpenses:(NSArray *)expenses orderBy:(CategorySummariesOrderByType)orderBy;
@end