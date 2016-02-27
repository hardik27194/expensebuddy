//
//  DBHelper.h
//  RecordIt
//
//  Created by rob on 4/7/15.
//  Copyright (c) 2015 CAKEsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface DBHelper : NSObject

+(int)openDBFilename:(NSString *)dbFilename dbHandle:(sqlite3 **)dbHandle;
+(int)closeDBHandle:(sqlite3 *)dbHandle;
+(int)openStatementFromSQL:(NSString *)sql dbHandle:(sqlite3 *)dbHandle statement:(sqlite3_stmt **)statement;
+(int)execStatementFromSQL:(NSString *)sql dbHandle:(sqlite3 *)dbHandle statement:(sqlite3_stmt **)statement;
+(int)closeStatement:(sqlite3_stmt *)statement;
+(NSString *)escapeQuotesFromString:(NSString *)s;

@end

