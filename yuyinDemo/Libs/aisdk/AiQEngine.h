//
//  AiQEngine.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AiQEngineDelegate.h"
#import "JSONKit2.h"

@interface AiQEngine : NSObject

/**
 * 事件委托
 */
@property(nonatomic, assign) id<AiQEngineDelegate> delegate;

/**
 * 版本
 */
@property(nonatomic, copy, readonly) NSString *version;

/**
 * 标签，用户自定义
 */
@property(nonatomic, assign) int tag;

/**
 * 初始化AiQEngine
 */
- (id)initWithConfig:(NSDictionary *)cfg;

/**
 * 开始评分引擎。
 * 通常在开始录音前先调用该方法，保证录音开始时所有的数据都能传到引擎中
 * @return recordId
 */
- (NSString *)startWithParams:(NSString *)params;
- (NSString *)startWithParams:(NSString *)params vadEnable:(BOOL)vadEnable;

/**
 * 向评分引擎传入数据
 */
- (OSStatus)performWithAudioData:(const void *)audioData size:(int)size;

/**
 * 停止评分引擎。在停止录音后调用该方法，保证所有的音频数据都已经传入引擎
 */
- (OSStatus)stop;

/**
 * 重置评分引擎
 */
- (void)reset;

/**
 * 检查录音引擎是否已经开始了（即调用了start但还没调用stop）
 */
- (BOOL)isRunning;

/**
 * 检查录音引擎是否已经初始化了
 */
- (BOOL)isInitialized;

/**
 * 使用离线评测时，是否自动上传用户的音频。
 * 如果为YES，则在wifi网络下，自动上传用户音频
 * 如果为NO，则始终不上传用户音频
 */
- (void)enableAudioUpload:(BOOL)enable;

/**
 * 获取设备ID
 */
+ (NSString *)getDeviceId;

+ (NSString *)opt:(NSInteger)opt data:(NSString *)data;

@end
