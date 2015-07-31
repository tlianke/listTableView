//
//  AiConstants.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#ifndef AiEngineLib_AiConstants_h
#define AiEngineLib_AiConstants_h


/**
 * 语音引擎停止的类型：
 * STOPTYPE_AUTO 到指定时长后自动结束，或VAD检测语音已经结束
 * STOPTYPE_MANUAL 运行过程中用户调用了stop方法来停止引擎
 * STOPTYPE_RESET 运行过程中用户调用了reset方法来停止引擎
 */
typedef enum {
    AIENGINE_STOPTYPE_AUTO = 0,
    AIENGINE_STOPTYPE_MANUAL = 1,
    AIENGINE_STOPTYPE_RESET = 2,
} AIENGINE_STOPTYPE;

#define AiConstants_sdkVersion @"1.0"

#endif
