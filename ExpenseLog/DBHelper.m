//
//  DBHelper.m
//  RecordIt
//
//  Created by rob on 4/7/15.
//  Copyright (c) 2015 CAKEsoft. All rights reserved.
//

#import "DBHelper.h"
#import "Utils.h"

@implementation DBHelper

+(int)openDBFilename:(NSString *)dbFilename dbHandle:(sqlite3 **)dbHandle {
    NSString *filepath = [Utils filepathFromDocumentsDir:dbFilename];
    if (filepath == nil) {
        return -1;
    }
    return sqlite3_open_v2([filepath UTF8String], dbHandle, SQLITE_OPEN_READWRITE, nil);
}

+(int)closeDBHandle:(sqlite3 *)dbHandle {
    return sqlite3_close(dbHandle);
}

+(int)openStatementFromSQL:(NSString *)sql dbHandle:(sqlite3 *)dbHandle statement:(sqlite3_stmt **)statement {
    return sqlite3_prepare(dbHandle, [sql UTF8String], -1, statement, nil);
}

+(int)execStatementFromSQL:(NSString *)sql dbHandle:(sqlite3 *)dbHandle statement:(sqlite3_stmt **)statement {
    return sqlite3_exec(dbHandle, [sql UTF8String], nil, statement, nil);
}

+(int)closeStatement:(sqlite3_stmt *)statement {
    return sqlite3_finalize(statement);
}

+(NSString *)escapeQuotesFromString:(NSString *)s {
    return [s stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

@end


