//
//  Common.h
//  yuyinDemo
//
//  Created by tlian on 15/3/10.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioHelper.h"
#import "AiSpeechEngine.h"

typedef enum{
    ENGINE_STATUS_NULL = -2,
    ENGINE_STATUS_LOADING = -1,
    ENGINE_STATUS_INITIALIZED = 0,
    ENGINE_STATUS_ERROR = 1
}ENGINE_STATUS;
#define kInitEngineSuccessNotification @"kInitEngineSuccessNotification"
#define kInitEngineErrorNotification @"kInitEngineErrorNotification"

#define kAppKey @"137394358700007e"
#define kSecretKey @"f69bd1c60f67731068dd1b1446ef823d"
#define kUmengAppkey @"53fef210fd98c502c1007467"

@interface Common : NSObject<AiSpeechEngineDelegate,UIAlertViewDelegate>

@property (nonatomic ,strong)AudioHelper *audioHelper;
@property (nonatomic, strong)AiSpeechEngine *engine;
@property (nonatomic, assign)ENGINE_STATUS engineStatus;
@property (nonatomic, assign)id<AiSpeechEngineDelegate>engineDelegate;
@property (nonatomic, getter=isShouldAutoPlay)BOOL shouldAutoPlay;
+(Common *)sharedInstance;
+(void)showEngineErrorAlertView:(NSString *)message;
@end
