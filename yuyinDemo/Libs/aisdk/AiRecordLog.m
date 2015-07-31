//
//  AiRecordLog.m
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import "AiRecordLog.h"
#import <sqlite3.h>

#pragma mark - AiRecordLogBean

@implementation AiRecordLogBean
@synthesize recordId, audioPath, params, result;

@end

#pragma mark - AiRecordLog

@interface AiRecordLog()
{
    sqlite3 *_database;
}
@end

@implementation AiRecordLog

//获取document目录并返回数据库目录
- (NSString *)dataFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"airecordlog.db"];
}

//创建，打开数据库
- (BOOL)openDB
{
    //获取数据库路径
    NSString *path = [self dataFilePath];
    //判断数据库是否存在
    BOOL find = [[NSFileManager defaultManager] fileExistsAtPath:path];
    //如果数据库存在，则用sqlite3_open直接打开（不要担心，如果数据库不存在sqlite3_open会自动创建）
    if (find) {
        if(sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
            return YES;
        }
        //如果打开数据库失败则关闭数据库
        sqlite3_close(_database);
        return NO;
    }
    //如果发现数据库不存在则利用sqlite3_open创建数据库
    if (sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
        //创建一个新表
        return [self createNewTable];
    }else{
        //如果创建并打开数据库失败则关闭数据库
        sqlite3_close(_database);
        return NO;
    }
    return NO;
}

/**
 * 创建recordlog表
 */
-(BOOL)createNewTable
{
    char *sql = "CREATE TABLE IF NOT EXISTS recordlog(recordId VARCHAR(255) PRIMARY KEY, audioPath TEXT, params TEXT, result TEXT)";
    sqlite3_stmt *statement;
    //sqlite3_prepare_v2 接口把一条SQL语句解析到statement结构里去. 使用该接口访问数据库是当前比较好的的一种方法
    NSInteger sqlReturn = sqlite3_prepare_v2(_database, sql, -1, &statement, nil);
    //第一个参数跟前面一样，是个sqlite3 * 类型变量，
    //第二个参数是一个 sql 语句。
    //第三个参数我写的是-1，这个参数含义是前面 sql 语句的长度。如果小于0，sqlite会自动计算它的长度（把sql语句当成以\0结尾的字符串）。
    //第四个参数是sqlite3_stmt 的指针的指针。解析以后的sql语句就放在这个结构里。
    //第五个参数是错误信息提示，一般不用,为nil就可以了。
    //如果这个函数执行成功（返回值是 SQLITE_OK 且 statement 不为NULL ），那么下面就可以开始插入二进制数据。
    
    //如果SQL语句解析出错的话程序返回
    if(sqlReturn != SQLITE_OK) {
        return NO;
    }
    //执行SQL语句
    int success = sqlite3_step(statement);
    //释放sqlite3_stmt
    sqlite3_finalize(statement);
    
    //执行SQL语句失败
    if (success != SQLITE_DONE) {
        return NO;
    }
    return YES;
}

-(BOOL)saveRecordId:(NSString *)p1 audioPath:(NSString *)p2 params:(NSString *)p3
{
    if ([self openDB]) {
        sqlite3_stmt *statement;
        
        //这个 sql 语句特别之处在于 values 里面有个? 号。在sqlite3_prepare函数里，?号表示一个未定的值，它的值等下才插入。
        char *sql = "INSERT INTO recordlog(recordId, audioPath, params) VALUES(?, ?, ?)";
        int success = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (success != SQLITE_OK) {
            sqlite3_close(_database);
            return NO;
        }
        //这里的数字1，2，3代表上面的第几个问号，这里将三个值绑定到三个绑定变量
        sqlite3_bind_text(statement, 1, [p1 UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [p2 UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [p3 UTF8String], -1, SQLITE_TRANSIENT);
        
        //执行插入语句
        success = sqlite3_step(statement);
        //释放statement
        sqlite3_finalize(statement);
        
        sqlite3_close(_database);
        if (success == SQLITE_ERROR) {
            return NO;
        }
        return YES;
    }
    return NO;
}

-(BOOL)saveRecordId:(NSString *)p1 result:(NSString *)p2
{
    if ([self openDB]) {
        sqlite3_stmt *statement;
        
        char *sql = "UPDATE recordlog set result=? WHERE recordId=?";
        int success = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (success != SQLITE_OK) {
            sqlite3_close(_database);
            return NO;
        }
        //这里的数字1，2，3代表上面的第几个问号，这里将三个值绑定到三个绑定变量
        sqlite3_bind_text(statement, 1, [p2 UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [p1 UTF8String], -1, SQLITE_TRANSIENT);
        
        //执行SQL语句
        success = sqlite3_step(statement);
        //释放statement
        sqlite3_finalize(statement);
        
        sqlite3_close(_database);
        if (success == SQLITE_ERROR) {
            return NO;
        }
        return YES;
    }
    return NO;
}

-(AiRecordLogBean *)getLog:(NSString *)p1
{
    if ([self openDB]) {
        sqlite3_stmt *statement;
        
        char *sql = "SELECT recordId, audioPath, params, result FROM recordlog WHERE recordId=? LIMIT 1";
        int success = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (success != SQLITE_OK) {
            sqlite3_close(_database);
            return nil;
        }
        sqlite3_bind_text(statement, 1, [p1 UTF8String], -1, SQLITE_TRANSIENT);
        
        //执行SQL语句
        AiRecordLogBean *item = nil;
        if(sqlite3_step(statement) == SQLITE_ROW){
            ////查询结果集中一条一条的遍历所有的记录，这里的数字对应的是列值,
            item = [[AiRecordLogBean alloc] init];
            item.recordId = p1;
            
            char *audioPath = (char*)sqlite3_column_text(statement, 1);
            item.audioPath = [NSString stringWithUTF8String:audioPath];
            
            char *params = (char*)sqlite3_column_text(statement, 2);
            item.params = [NSString stringWithUTF8String:params];
            
            char *result = (char*)sqlite3_column_text(statement, 3);
            item.result = [NSString stringWithUTF8String:result];
        }
        sqlite3_finalize(statement);
        sqlite3_close(_database);
        return item;
    }
    return nil;
}

-(BOOL)clear
{
    if ([self openDB]) {
        sqlite3_stmt *statement;
        char *sql = "DELETE FROM recordlog";
        int success = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (success != SQLITE_OK) {
            sqlite3_close(_database);
            return NO;
        }
        success = sqlite3_step(statement);
        sqlite3_finalize(statement);
        sqlite3_close(_database);
        if (success == SQLITE_ERROR) {
            return NO;
        }
        return YES;
    }
    return NO;
}

-(BOOL)remove:(NSString *)p1
{
    if ([self openDB]) {
        sqlite3_stmt *statement;
        char *sql = "DELETE FROM recordlog WHERE recordId=?";
        int success = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (success != SQLITE_OK) {
            sqlite3_close(_database);
            return NO;
        }
        sqlite3_bind_text(statement, 1, [p1 UTF8String], -1, SQLITE_TRANSIENT);
        success = sqlite3_step(statement);
        sqlite3_finalize(statement);
        sqlite3_close(_database);
        if (success == SQLITE_ERROR) {
            return NO;
        }
        return YES;
    }
    return NO;
}

@end
