//
//  AiQRecorder.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AiQRecorderDelegate.h"
@interface AiQRecorder : NSObject
{
}
/**
 * 当前已录音时长
 */
@property(nonatomic)NSTimeInterval currentTime;

/**
 * 录音总时长
 */
@property(nonatomic)NSTimeInterval duration;

/**
 * 事件委托
 */
@property(nonatomic, assign) id<AiQRecorderDelegate> delegate;

/**
 * 标签，用户自定义
 */
@property(nonatomic, assign) int tag;

/**
 * 是否开启音量检测
 */
@property(nonatomic, assign)BOOL meteringEnabled;

/**
 * 开始录音
 * path 音频保存路径
 * duration 录音时长，单位：秒
 * 如果指定了录音时长，会在录音结束后回调录音停止的事件
 */
- (OSStatus)recordWithPath:(NSString *)path;
- (OSStatus)recordWithPath:(NSString *)path duration:(NSTimeInterval)duration;
- (OSStatus)recordWithPath:(NSString *)path duration:(NSTimeInterval)duration sampleRate:(int)sampleRate;

/**
 * 停止录音
 */
- (OSStatus)stop;
- (OSStatus)stopByStopType:(AIENGINE_STOPTYPE)stopType;

/**
 * 开始回放最后一次的录音
 */
- (OSStatus)startReplay;

/**
 * 停止回放
 */
- (OSStatus)stopReplay;

/**
 * 重置录音机状态。
 * 如果当时正在录音，则会停止录音；
 * 如果当时正在回放，则会停止回放
 */
- (void)reset;

/**
 * 录音机是否正在录音
 */
- (BOOL)isRecording;

/**
 * 录音机是否正在回放
 */
- (BOOL)isReplaying;

@end
