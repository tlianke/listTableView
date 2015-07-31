//
//  AiQPlayer.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AiQPlayerDelegate.h"

@interface AiQPlayer : NSObject

/**
 * 事件委托
 */
@property(nonatomic, assign) id<AiQPlayerDelegate> delegate;

/**
 * 标签，用户自定义
 */
@property(nonatomic, assign) int tag;

/**
 * 加载音频
 */
- (OSStatus)loadWithPath:(NSString *)path;

/**
 * 播放音频
 */
- (OSStatus)play;

/**
 * 停止播放音频
 */
- (OSStatus)stop;

/**
 * 复位播放器
 */
- (void)reset;

/**
 * 当前播放器是否正在播放音频
 */
- (BOOL)isPlaying;

@end
