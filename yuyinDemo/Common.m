//
//  Common.m
//  yuyinDemo
//
//  Created by tlian on 15/3/10.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import "Common.h"
#import "JSONKit2.h"
#import "AFHTTPRequestOperation.h"
#import "SSZipArchive.h"
#import "AiHttpAuth.h"
#import "AiUtil.h"

static Common *instance;

@implementation Common
@synthesize engine,engineDelegate,engineStatus;
@synthesize audioHelper;
@synthesize shouldAutoPlay;

+(Common *)sharedInstance{
    if (instance == nil) {
        instance = [[Common alloc] init];
    }
    return instance;
}

#pragma mark - Function

-(id)init{

    self = [super init];
    if (self) {
        engineStatus = ENGINE_STATUS_NULL;
        // init audioHelper
        audioHelper = [[AudioHelper alloc] init];
        [audioHelper initSession];
        [audioHelper checkAndPrepareCategoryForRecording];
        
        shouldAutoPlay = YES;
        // 调用接口检查最新的应用版本号
        // 流程：授权－》解压－》初始化引擎
        [self doEngineAuth];
        
    }
    return self;
}

-(void)doEngineAuth{

    engineStatus = ENGINE_STATUS_LOADING;
    AiHttpAuth *auth = [[AiHttpAuth alloc] init];
    [auth start:kAppKey secreyKey:kSecretKey success:^(NSString *serialNumber) {
        NSLog(@"aiHttpAuth success:%@", serialNumber);
        [self performSelectorInBackground:@selector(initEngineInBackground:) withObject:serialNumber];
        
    } failure:^(NSString *errorString) {
        NSLog(@"aiHttpAuth failure:%@", errorString);
        [self postInitEngineStatus:ENGINE_STATUS_ERROR message:@"网络故障"];
    }];
}

// 初始化
-(void)initEngineInBackground:(NSString *)serialNumber{

    @autoreleasepool {
        NSString *resourceFile = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"aiengine.resource.zip"];
        NSString *dir = [AiUtil unzipFile:resourceFile];
        if (dir == nil) {//解压失败了
            [self postInitEngineStatus:ENGINE_STATUS_ERROR message:@"解压资源出错"];
            return;
        }
        
        NSString *provisionPath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"/aiengine.provision"];
        NSString *pathForEnWordScore = [dir stringByAppendingPathComponent:@"/eval/bin/eng.wrd.splp.offline.1.8"];
        NSString *pathForEnSentScore = [dir stringByAppendingPathComponent:@"/eval/bin/eng.snt.splp.offline.0.12"];
        //NSString *pathForCnWordScore = [dir stringByAppendingPathComponent:@"/bin/chn.wrd.gnr.splp.0.3"];
        //NSString *pathForCnSentScore = [dir stringByAppendingPathComponent:@"/bin/chn.snt.splp.offline.0.1"];
        //NSString *pathForVad = [dir stringByAppendingPathComponent:@"/bin/vad.0.9.20140315.bin"];
        //FIXME
        NSString *pathForEnPredExam = [dir stringByAppendingPathComponent:@"/exam/bin/eng.pred.0.0.8"];
        NSDictionary *cfgDict = @{@"appKey": kAppKey,
                                  @"secretKey": kSecretKey,
                                  @"provision": provisionPath,
                                  @"serialNumber": serialNumber,
                                  @"native": @{
                                          @"en.word.score": @{@"res": pathForEnWordScore},
                                          @"en.sent.score": @{@"res": pathForEnSentScore},
                                          @"en.pred.exam": @{@"res": pathForEnPredExam}
                                          //@"cn.word.score": @{@"res": pathForCnWordScore},
                                          //@"cn.sent.score": @{@"res": pathForCnSentScore}
                                          },
                                  //@"vad":@{
                                  //        @"enable": @1,
                                  //        @"res":pathForVad,
                                  //        @"speechLowSeek":@60,
                                  //        @"strip":@1,
                                  //        @"sampleRate":@16000}
                                  };
        engine = [[AiSpeechEngine alloc] initWithCfg:cfgDict];
        engine.delegate = self;
        engine.meteringEnabled = YES;
        if ([engine isInitialized]) {
            [engine enableAudioUpload:YES];
            [self postInitEngineStatus:ENGINE_STATUS_INITIALIZED message:nil];
        }else{
            [self postInitEngineStatus:ENGINE_STATUS_ERROR message:@"初始化异常"];
        }
    }

}

-(void)postInitEngineStatus:(int)status message:(NSString *)message
{
    engineStatus = status;
    NSLog(@"postInitEngineStatus:%zd", engineStatus);
    if (status == ENGINE_STATUS_INITIALIZED) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kInitEngineSuccessNotification object:message];
        
    }else if(status == ENGINE_STATUS_ERROR){
        [Common showEngineErrorAlertView:message];
        [[NSNotificationCenter defaultCenter] postNotificationName:kInitEngineErrorNotification object:message];
    }
}

+(void)showEngineErrorAlertView:(NSString *)message{

    NSString *s = [NSString stringWithFormat:@"初始化引擎出错。\n错误信息:%@", message];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"出错啦" message:s delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

#pragma mark AispeechEngineDelegate
-(void)aiSpeechEngineDidFinishRecording:(AiSpeechEngine *)e stopType:(AIENGINE_STOPTYPE)stopType
{
    if (engineDelegate &&
        [engineDelegate respondsToSelector:@selector(aiSpeechEngineDidFinishRecording:stopType:)]) {
        [engineDelegate aiSpeechEngineDidFinishRecording:e stopType:stopType];
    }
}

-(void)aiSpeechEngineDidFinishReplaying:(AiSpeechEngine *)e stopType:(AIENGINE_STOPTYPE)stopType
{
    if (engineDelegate &&
        [engineDelegate respondsToSelector:@selector(aiSpeechEngineDidFinishReplaying:stopType:)]) {
        [engineDelegate aiSpeechEngineDidFinishReplaying:e stopType:stopType];
    }
}

-(void)aiSpeechEngine:(AiSpeechEngine *)e didReceive:(NSString *)recordId vadJson:(NSString *)jsonString
{
    if (engineDelegate &&
        [engineDelegate respondsToSelector:@selector(aiSpeechEngine:didReceive:vadJson:)]) {
        [engineDelegate aiSpeechEngine:e didReceive:recordId vadJson:jsonString];
    }
}

-(void)aiSpeechEngine:(AiSpeechEngine *)e didReceive:(NSString *)recordId responseJson:(NSString *)jsonString
{
    if (engineDelegate &&
        [engineDelegate respondsToSelector:@selector(aiSpeechEngine:didReceive:responseJson:)]) {
        [engineDelegate aiSpeechEngine:e didReceive:recordId responseJson:jsonString];
    }
}

-(void)aiSpeechEngineIsRecording:(AiSpeechEngine *)e passedTime:(NSTimeInterval)passedTime averagePower:(Float32)averagePower peakPower:(Float32)peakPower
{
    if (engineDelegate &&
        [engineDelegate respondsToSelector:@selector(aiSpeechEngineIsRecording:passedTime:averagePower:peakPower:)]) {
        [engineDelegate aiSpeechEngineIsRecording:e passedTime:passedTime averagePower:averagePower peakPower:peakPower];
    }
}

-(void)aiSpeechEngineIsRecording:(AiSpeechEngine *)e audioData:(const void *)audioData size:(int)size{
    if (engineDelegate && [engineDelegate respondsToSelector:@selector(aiSpeechEngineIsRecording:audioData:size:)]) {
        [engineDelegate aiSpeechEngineIsRecording:e audioData:audioData size:size];
    }
}

@end
