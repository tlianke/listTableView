//
//  AudioHelper.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioHelper : NSObject
{
    BOOL recording;
}

- (void)initSession;
- (BOOL)hasHeadset;
- (BOOL)hasMicphone;
- (void)cleanUpForEndRecording;
- (BOOL)checkAndPrepareCategoryForRecording;

/**
 * 是否允许录音
 */
- (BOOL)canRecord;

@end
