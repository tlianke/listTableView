//
//  AiSpeechEngine.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AiSpeechEngineDelegate.h"
#import "JSONKit2.h"

@interface AiSpeechEngine : NSObject

/**
 * 当前已录音时长
 */
@property(nonatomic)NSTimeInterval recordCurrentTime;

/**
 * 录音总时长
 */
@property(nonatomic)NSTimeInterval recordDuration;

/**
 * 用户ID
 */
@property(nonatomic)NSString *userId;

/**
 * 事件委托
 */
@property(nonatomic, assign) id<AiSpeechEngineDelegate> delegate;

/**
 * 标签，用户自定义
 */
@property(nonatomic, assign) int tag;

/**
 * 是否开启音量检测
 */
@property(nonatomic, assign)BOOL meteringEnabled;

/**
 * 初始化语音引擎
 */
- (id)initWithCfg:(NSDictionary *)cfg;

/**
 * 开始语音引擎
 * @param
 *      path 录音文件地址
 *      duration 录音时长，单位：秒。如果<=0，则不会自动停止
 *      requestParams 请求参数
 *        coreType 内核类型
 *        refText 参考文本
 *        rank 评分级别
 * @return 录音ID
 */
- (NSString *)startWithPath:(NSString *)path duration:(NSTimeInterval)duration requestParams:(NSDictionary *)requestParams;
- (NSString *)startWithPath:(NSString *)path isDirectory:(BOOL)isDirectory duration:(NSTimeInterval)duration requestParams:(NSDictionary *)requestParams;
- (NSString *)startWithPath:(NSString *)path isDirectory:(BOOL)isDirectory duration:(NSTimeInterval)duration requestParams:(NSDictionary *)requestParams vadEnable:(BOOL)vadEnable;

/**
 * 停止语音引擎
 */
- (void)stop;

/**
 * 重置语音引擎
 */
- (void)reset;

/**
 * 开始回放最后一次的录音
 */
- (OSStatus)startReplay;

/**
 * 停止回放
 */
- (OSStatus)stopReplay;

/**
 * 检查语音引擎是否正在录音
 */
- (BOOL)isRecording;

/**
 * 检查语音引擎是否正在回放
 */
- (BOOL)isReplaying;

/**
 * 检查语音引擎是否初始化成功
 */
- (BOOL)isInitialized;

/**
 * 使用离线评测时，是否自动上传用户的音频。
 * 如果为YES，则在wifi网络下，自动上传用户音频
 * 如果为NO，则始终不上传用户音频
 */
- (void)enableAudioUpload:(BOOL)enable;

@end
