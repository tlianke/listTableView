//
//  AiQEngine.m
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import "AiQEngine.h"
#import "aiengine.h"
#import "AiConstants.h"
#import "AFNetworkReachabilityManager.h"

#if !__has_feature(objc_arc)
#error "This source file must be compiled with ARC enabled!"
#endif

@interface AiQEngine()
{
    struct aiengine *engine;
    
    BOOL running;
    
    //{
    //  recordId: {responseJson}
    //  recordId: {responseBinary}
    //}
    NSMutableDictionary *respDict;
    
    BOOL isVadEnable;
    BOOL isFreeVersion;
    BOOL bAudioUpload;
}
@end

@implementation AiQEngine
@synthesize delegate, version, tag;

static int _aiengine_callback(const void *usrdata, const char *recordId, int type, const void *message, int size)
{
    @autoreleasepool {
        AiQEngine *THIS = (__bridge AiQEngine *)(usrdata);
        [THIS engineIntervalCallback:THIS recordId:recordId type:type message:message size:size];
        return 0;
    }
}

- (NSString *)filterJsonResult:(NSString *)json
{
    if (isFreeVersion == NO) {
        return json;
    }
    NSDictionary *dict = [json objectFromJSONString2];
    NSMutableDictionary *r = [[NSMutableDictionary alloc] initWithCapacity:3];
    if ([dict objectForKey:@"recordId"] != nil) {
        [r setValue:[dict objectForKey:@"recordId"] forKey:@"recordId"];
    }
    if ([dict objectForKey:@"errId"] != nil) {
        [r setValue:[dict objectForKey:@"errId"] forKey:@"errId"];
    }
    if ([dict objectForKey:@"error"] != nil) {
        [r setValue:[dict objectForKey:@"error"] forKey:@"error"];
    }
    if ([dict objectForKey:@"version"] != nil) {
        [r setValue:[dict objectForKey:@"version"] forKey:@"version"];
    }
    if ([dict objectForKey:@"result"] != nil) {
        NSDictionary *result = [dict objectForKey:@"result"];
        id idOverall = [result objectForKey:@"overall"];
        id idVersion = [result objectForKey:@"version"];
        id idRes = [result objectForKey:@"res"];
        id idInfo = [result objectForKey:@"info"];
        if (idOverall != nil && idVersion != nil && idRes != nil && idInfo != nil) {
            NSDictionary *v = @{@"overall": idOverall,
                                @"version": idVersion,
                                @"res": idRes,
                                @"info": idInfo};
            [r setValue:v forKey:@"result"];
        }
    }
    return [r JSONString2];
}

- (void)engineIntervalCallback:(AiQEngine *)THIS recordId:(const char *)recordId type:(int)type message:(const void *)message size:(int)size
{
    NSString *recId = [NSString stringWithCString:recordId encoding:NSUTF8StringEncoding];
    if (type == AIENGINE_MESSAGE_TYPE_JSON) {
        if (THIS && [THIS.delegate respondsToSelector:@selector(aiQEngine:didReceive:responseJson:)]) {
            NSString *responseString = [NSString stringWithCString:message encoding:NSUTF8StringEncoding];
            responseString = [self filterJsonResult:responseString];
            NSDictionary *dict = @{@"engine": THIS,
                                   @"recordId": recId,
                                   @"response": responseString};
            [THIS performSelectorOnMainThread:@selector(aiQEngineDidReceiveResponseJson:) withObject:dict waitUntilDone:[NSThread isMainThread]];
        }
        
    }else if(type == AIENGINE_MESSAGE_TYPE_BIN){
        NSMutableData *respData = [respDict objectForKey:recId];
        if (respData == nil) {
            [respDict setValue:[NSMutableData dataWithBytes:message length:size] forKey:recId];
        }else{
            [respData appendBytes:message length:size];
        }
        if (size == 0) { // size == 0 means end
            NSDictionary *dict = @{@"engine": THIS,
                                   @"recordId": recId,
                                   @"response": respData};
            [THIS performSelectorOnMainThread:@selector(aiQEngineDidReceiveResponseData:) withObject:dict waitUntilDone:[NSThread isMainThread]];
        }
    }
}
- (void)aiQEngineDidReceiveResponseJson:(NSDictionary *)dict
{
    AiQEngine *THIS = [dict objectForKey:@"engine"];
    NSString *recId = [dict objectForKey:@"recordId"];
    NSString *responseString = [dict objectForKey:@"response"];
    if (isVadEnable == YES) {//判断返回是否为VAD结果
        NSDictionary *responseDict = [responseString objectFromJSONString2];
        if ([responseDict objectForKey:@"vad_status"] != nil) {
            NSLog(@"%@", responseString);
            if (delegate &&
                [delegate respondsToSelector:@selector(aiQEngine:didReceive:vadJson:)]) {
                [delegate aiQEngine:THIS didReceive:recId vadJson:responseString];
            }
            return;
        }
    }
    [THIS.delegate aiQEngine:THIS didReceive:recId responseJson:responseString];
}
- (void)aiQEngineDidReceiveResponseData:(NSDictionary *)dict
{
    AiQEngine *THIS = [dict objectForKey:@"engine"];
    NSString *recId = [dict objectForKey:@"recordId"];
    NSData *responseData = [dict objectForKey:@"response"];
    [THIS.delegate aiQEngine:THIS didReceive:recId responseBinary:responseData];
}

- (id)initWithConfig:(NSDictionary *)cfg;
{
    NSString *cfgString = [cfg JSONString2];
    NSLog(@"AiQEngine init, cfg = %@", cfgString);
    self = [super init];
    if (self) {
        if (cfg != nil) {
            //read provision config
            //NSDictionary *authDict = [self readProvision:cfg];
            //NSLog(@"%@", authDict);
            ////====
            //isFreeVersion = YES;
            //version = [NSString stringWithFormat:@"free.%@", AiConstants_sdkVersion];
            //
            ////nativeAndCloud [optional],
            ////本地和云端联合授权，默认0，
            ////配置1：免费版本MES，
            ////配置2：收费版本MES
            //if ([authDict objectForKey:@"nativeAndCloud"] != nil) {
            //    int nativeAndCloud = [[authDict objectForKey:@"nativeAndCloud"] intValue];
            //    if(nativeAndCloud == 2){
            //        isFreeVersion = NO;
            //        version = [NSString stringWithFormat:@"charge.%@", AiConstants_sdkVersion];
            //    }
            //}
            //====
            //create engine
            engine = aiengine_new([cfgString UTF8String]);
        }
        if (engine == NULL) {
            NSLog(@"[ERROR]aiengine_new failed.");
            return nil;
        }
        running = NO;
        respDict = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return self;
}

- (void)dealloc
{
    if (engine != NULL) {
        aiengine_delete(engine);
        engine = NULL;
    }
}

/**
 * 读取授权文件。返回授权字典
 */
- (NSDictionary *)readProvision:(NSDictionary *)cfg
{
    NSString *provisionPath = [cfg objectForKey:@"provision"];
    NSString *resp = [AiQEngine opt:4 data:provisionPath];
    NSDictionary *authDict = [resp objectFromJSONString2];
    return authDict;
}

- (NSString *)startWithParams:(NSString *)params
{
    return [self startWithParams:params vadEnable:NO];
}

- (NSString *)startWithParams:(NSString *)params vadEnable:(BOOL)vadEnable
{
    isVadEnable = vadEnable;
    char recordId[64] = {0};
    int rv = aiengine_start(engine, [params UTF8String], recordId, _aiengine_callback, (__bridge const void *)(self));
    if (rv != 0) {
        NSLog(@"[ERROR]aiengine_start failed.");
        return nil;
    }
    running = YES;
    return [NSString stringWithCString:recordId encoding:NSUTF8StringEncoding];
}

- (OSStatus)performWithAudioData:(const void *)audioData size:(int)size
{
    int rv = -1;
    rv = aiengine_feed(engine, audioData, size);
    return rv;
}

- (OSStatus)stop
{
    int rv = -1;
    rv = aiengine_stop(engine);
    running = NO;
    return rv;
}

- (void)reset
{
    [respDict removeAllObjects];
    if (running) {
        aiengine_cancel(engine);
        running = NO;
    }
}

- (BOOL)isRunning
{
    return running;
}

- (BOOL)isInitialized
{
    if (engine != 0) {
        return YES;
    }
    return NO;
}

- (void)changeAudioUpload
{
    AFNetworkReachabilityManager *m = [AFNetworkReachabilityManager sharedManager];
    if (bAudioUpload && m.isReachableViaWiFi) {
        aiengine_opt(engine, 4, "1", 1);
    }else{
        aiengine_opt(engine, 4, "0", 1);
    }
}

- (void)registerAudioUploadEvent
{
    AFNetworkReachabilityManager *m = [AFNetworkReachabilityManager sharedManager];
    if (bAudioUpload) {
        [m setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [self changeAudioUpload];
        }];
        [m startMonitoring];
    }else{
        [m stopMonitoring];
    }
}

- (void)enableAudioUpload:(BOOL)enable
{
    bAudioUpload = enable;
    [self registerAudioUploadEvent];
    [self changeAudioUpload];
}

+ (NSString *)getDeviceId
{
    char deviceId[64] = {0};
    aiengine_get_device_id(deviceId);
    return [NSString stringWithCString:deviceId encoding:NSUTF8StringEncoding];
}

+ (NSString *)opt:(NSInteger)opt data:(NSString *)data
{
    char buf[1024] = {0};
    strcpy(buf, [data UTF8String]);
    aiengine_opt(NULL, (int)opt, buf, 1024);
    return [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
}

@end
