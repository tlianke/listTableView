//
//  AiQRecorderDelegate.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AiConstants.h"

@class AiQRecorder;
@protocol AiQRecorderDelegate <NSObject>

@required
/**
 * 录音机正在录音，需要实时将录音数据传给评测引擎
 */
-(void)aiQRecorderPerformRecording:(AiQRecorder *)recorder audioData:(const void *)audioData size:(int)size;

/**
 * 录音机录音完成
 */
-(void)aiQRecorderDidFinishRecording:(AiQRecorder *)recorder stopType:(AIENGINE_STOPTYPE)stopType;

@optional
/**
 * 录音时，每隔 RECORD_INTERVAL_CALLBACK 会触发一次回调，通知应用已经录音的时长( 当前时间 - 录音开始时间 )。可用于更新录音进度条；
 * 获取 averagePower 和 peakPower 的值，需要设置 meteringEnabled = YES
 */
-(void)aiQRecorderIsRecording:(AiQRecorder *)recorder passedTime:(NSTimeInterval)passedTime averagePower:(Float32)averagePower peakPower:(Float32)peakPower;

/**
 * 录音机回放完成
 */
-(void)aiQRecorderDidFinishReplaying:(AiQRecorder *)recorder stopType:(AIENGINE_STOPTYPE)stopType;

@end
