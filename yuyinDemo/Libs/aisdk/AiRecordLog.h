//
//  AiRecordLog.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import "JSONKit2.h"

@interface AiRecordLogBean : NSObject

@property(nonatomic, copy)NSString *recordId;
@property(nonatomic, copy)NSString *audioPath;
@property(nonatomic, copy)NSString *params;
@property(nonatomic, copy)NSString *result;

@end

@interface AiRecordLog : NSObject

-(BOOL)saveRecordId:(NSString *)recordId audioPath:(NSString *)audioPath params:(NSString *)params;
-(BOOL)saveRecordId:(NSString *)recordId result:(NSString *)result;
-(AiRecordLogBean *)getLog:(NSString *)recordId;
-(BOOL)clear;
-(BOOL)remove:(NSString *)recordId;

@end
