//
//  AiQPlayerDelegate.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AiConstants.h"

@class AiQPlayer;
@protocol AiQPlayerDelegate <NSObject>

@required
/**
 * 播放器播放完成
 */
-(void)aiQPlayerDidFinishPlaying:(AiQPlayer *)player stopType:(AIENGINE_STOPTYPE)stopType;

@end
