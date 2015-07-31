//
//  AiQEngineDelegate.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AiQEngine;
@protocol AiQEngineDelegate <NSObject>

@required

/**
 * 引擎收到了vad数据
 */
-(void)aiQEngine:(AiQEngine *)engine didReceive:(NSString *)recordId vadJson:(NSString *)jsonString;

/**
 * 引擎收到了json数据
 */
-(void)aiQEngine:(AiQEngine *)engine didReceive:(NSString *)recordId responseJson:(NSString *)jsonString;

/**
 * 引擎收到了二进制数据
 */
-(void)aiQEngine:(AiQEngine *)engine didReceive:(NSString *)recordId responseBinary:(NSData *)binaryData;

@end
