//
//  AiSpeechEngineDelegate.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AiConstants.h"

@class AiSpeechEngine;
@protocol AiSpeechEngineDelegate <NSObject>

@required

/**
 * 引擎运行完成
 */
-(void)aiSpeechEngineDidFinishRecording:(AiSpeechEngine *)engine stopType:(AIENGINE_STOPTYPE)stopType;

/**
 * 引擎收到了json结果
 */
-(void)aiSpeechEngine:(AiSpeechEngine *)engine didReceive:(NSString *)recordId responseJson:(NSString *)jsonString;

@optional

/**
 * 引擎收到了vad结果
 * {"vad_status": 2, "volume": 0.000000}
 */
-(void)aiSpeechEngine:(AiSpeechEngine *)engine didReceive:(NSString *)recordId vadJson:(NSString *)jsonString;

/**
 * 引擎收到了二进制结果
 */
-(void)aiSpeechEngine:(AiSpeechEngine *)engine didReceive:(NSString *)recordId responseBinary:(NSData *)binaryData;

/**
 * 引擎运行时，每隔 RECORD_INTERVAL_CALLBACK 会触发一次回调，通知应用已经运行的时长( 当前时间 - 引擎开始时间 )。可用于更新录音进度条
 * 获取 averagePower 和 peakPower 的值，需要设置 meteringEnabled = YES
 */
-(void)aiSpeechEngineIsRecording:(AiSpeechEngine *)engine passedTime:(NSTimeInterval)passedTime averagePower:(Float32)averagePower peakPower:(Float32)peakPower;

/**
 * 录音机正在录音，需要实时将录音数据画波形图
 */
-(void)aiSpeechEngineIsRecording:(AiSpeechEngine *)engine audioData:(const void *)audioData size:(int)size;


/**
 * 引擎回放完成
 */
-(void)aiSpeechEngineDidFinishReplaying:(AiSpeechEngine *)engine stopType:(AIENGINE_STOPTYPE)stopType;

@end
