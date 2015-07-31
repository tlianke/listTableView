//
//  AiSpeechEngine.m
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import "AiSpeechEngine.h"
#import "AiQRecorder.h"
#import "AiQEngine.h"
//#import "AiRecordLog.h"
#import "AiQEngine.h"
//#import "LocationHelper.h"
//#import "Reachability.h"

#if !__has_feature(objc_arc)
#error "This source file must be compiled with ARC enabled!"
#endif

@interface AiSpeechEngine ()<AiQRecorderDelegate, AiQEngineDelegate>
{
    AiQRecorder *recorder;
    AiQEngine *engine;
    
    NSString *dirPath;
    NSString *appKey;
    //NSString *secretKey;
    //AiRecordLog *aiRecordLog;
    //ASIFormDataRequest *logRequest;
}
@end

@implementation AiSpeechEngine
@synthesize recordCurrentTime, recordDuration, userId;
@synthesize delegate, tag;
@synthesize meteringEnabled;

- (id)initWithCfg:(NSDictionary *)cfg
{
    //NSLog(@"AiSpeechEngine init, cfg=%@", [cfg JSONString]);
    self = [super init];
    if (self) {
        if ([cfg objectForKey:@"appKey"] != nil) {
            appKey = [cfg objectForKey:@"appKey"];
        }else{
            appKey = @"";
        }
        
        recorder = [[AiQRecorder alloc] init];
        recorder.delegate = self;
        
        engine = [[AiQEngine alloc] initWithConfig:cfg];
        engine.delegate = self;
        
        dirPath = nil;
        userId = [AiQEngine getDeviceId];
        
        //[LocationHelper sharedHelper];
        //aiRecordLog = [[AiRecordLog alloc] init];
        //[aiRecordLog clear];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"AiSpeechEngine dealloc");
    if (self) {
        [recorder reset];
        [engine reset];
        recorder.delegate = nil;
        engine.delegate = nil;
    }
}

- (NSString *)startWithPath:(NSString *)path duration:(NSTimeInterval)duration requestParams:(NSDictionary *)requestParams
{
    return [self startWithPath:path isDirectory:NO duration:duration requestParams:requestParams];
}

- (NSString *)startWithPath:(NSString *)path isDirectory:(BOOL)isDirectory duration:(NSTimeInterval)duration requestParams:(NSDictionary *)requestParams
{
    return [self startWithPath:path isDirectory:isDirectory duration:duration requestParams:requestParams vadEnable:NO];
}

- (NSString *)startWithPath:(NSString *)path isDirectory:(BOOL)isDirectory duration:(NSTimeInterval)duration requestParams:(NSDictionary *)requestParams vadEnable:(BOOL)vadEnable
{
    NSDictionary *recordDict = @{@"app": @{
                                         @"userId": userId},
                                 @"audio": @{
                                         @"audioType": @"wav",
                                         @"sampleRate": @16000,
                                         @"channel": @1,
                                         @"sampleBytes": @2},
                                 @"request": [NSDictionary dictionaryWithDictionary:requestParams]};
    if (vadEnable) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:recordDict];
        [dict setValue:@1 forKey:@"vadEnable"];
        [dict setValue:@0 forKey:@"volumeEnable"];
        recordDict = dict;
    }
    if ([@{} isEqualToDictionary:requestParams]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:recordDict];
        [dict removeObjectForKey:@"request"];
        recordDict = dict;
    }
    NSString *params = [recordDict JSONString2];
    NSString *recordId = [engine startWithParams:params vadEnable:vadEnable];
    if (recordId != nil) {
        OSStatus rv = noErr;
        NSString *filePath = nil;
        if (isDirectory) {
            dirPath = path;
            filePath = [dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav", recordId]];
        }else{
            filePath = path;
        }
        rv = [recorder recordWithPath:filePath duration:duration];
        if (rv != noErr) {
            NSLog(@"[ERROR]start record failed!");
            [engine stop];
            return nil;
        }
        //save log
        //[aiRecordLog saveRecordId:recordId audioPath:filePath params:params];
    }
    return recordId;
}

- (void)stop
{
    if (recorder.isRecording) {
        [recorder stop];
    }
    if (engine.isRunning) {
        [engine stop];
    }
}

- (void)stopByStopType:(int)stopType
{
    if (recorder.isRecording) {
        [recorder stopByStopType:stopType];
    }
    if (engine.isRunning) {
        [engine stop];
    }
}

- (void)reset
{
    [recorder reset];
    [engine reset];
}

- (OSStatus)startReplay
{
    OSStatus rv = [recorder startReplay];
    return rv;
}

- (OSStatus)stopReplay
{
    OSStatus rv = [recorder stopReplay];
    return rv;
}

- (BOOL)isRecording
{
    if (recorder == nil) {
        return NO;
    }
    return recorder.isRecording;
}

- (BOOL)isReplaying
{
    if (recorder == nil) {
        return NO;
    }
    return recorder.isReplaying;
}

- (BOOL)isInitialized
{
    return engine.isInitialized;
}

- (NSTimeInterval)recordCurrentTime
{
    return recorder.currentTime;
}

- (NSTimeInterval)recordDuration
{
    return recorder.duration;
}

- (void)enableAudioUpload:(BOOL)enable
{
    [engine enableAudioUpload:enable];
}

- (void)setMeteringEnabled:(BOOL)b
{
    recorder.meteringEnabled = b;
}

- (BOOL)isMeteringEnabled
{
    return recorder.meteringEnabled;
}

#pragma mark - AiQRecorderDelegate
-(void)aiQRecorderPerformRecording:(AiQRecorder *)recorder audioData:(const void *)audioData size:(int)size
{
    // 波形图
    if (delegate && [delegate respondsToSelector:@selector(aiSpeechEngineIsRecording:audioData:size:)]) {
        [delegate aiSpeechEngineIsRecording:self audioData:audioData size:size];
    }
    [engine performWithAudioData:audioData size:size];
}

-(void)aiQRecorderIsRecording:(AiQRecorder *)recorder passedTime:(NSTimeInterval)passedTime averagePower:(Float32)averagePower peakPower:(Float32)peakPower
{
    if (delegate &&
        [delegate respondsToSelector:@selector(aiSpeechEngineIsRecording:passedTime:averagePower:peakPower:)]) {
        [delegate aiSpeechEngineIsRecording:self passedTime:passedTime averagePower:averagePower peakPower:peakPower];
    }
}

-(void)aiQRecorderDidFinishRecording:(AiQRecorder *)recorder stopType:(AIENGINE_STOPTYPE)stopType
{
    if (stopType == AIENGINE_STOPTYPE_AUTO) {
        [engine stop];
    }
    if (delegate &&
        [delegate respondsToSelector:@selector(aiSpeechEngineDidFinishRecording:stopType:)]) {
        [delegate aiSpeechEngineDidFinishRecording:self stopType:stopType];
    }
}

-(void)aiQRecorderDidFinishReplaying:(AiQRecorder *)recorder stopType:(AIENGINE_STOPTYPE)stopType
{
    if (delegate &&
        [delegate respondsToSelector:@selector(aiSpeechEngineDidFinishReplaying:stopType:)]) {
        [delegate aiSpeechEngineDidFinishReplaying:self stopType:stopType];
    }
}

#pragma mark - AiQEngineDelegate
-(void)aiQEngine:(AiQEngine *)engine didReceive:(NSString *)recordId vadJson:(NSString *)jsonString
{
    NSDictionary *responseDict = [jsonString objectFromJSONString2];
    int vad_status = [[responseDict objectForKey:@"vad_status"] intValue];
    if (vad_status == 2) {
        [self stopByStopType:AIENGINE_STOPTYPE_AUTO];
    }
    if (delegate &&
        [delegate respondsToSelector:@selector(aiSpeechEngine:didReceive:vadJson:)]) {
        [delegate aiSpeechEngine:self didReceive:recordId vadJson:jsonString];
    }
}

-(void)aiQEngine:(AiQEngine *)engine didReceive:(NSString *)recordId responseJson:(NSString *)jsonString
{
    //NSLog(@"aiQEngine:didReceive:%@ responseJson:%@", recordId, jsonString);
    //NSLog(@"delegate=%p", delegate);
    [self performSelectorInBackground:@selector(responseJsonThread:) withObject:@{@"recordId": recordId,
                                                                                  @"jsonString": jsonString}];
    //delegate
    if (delegate &&
        [delegate respondsToSelector:@selector(aiSpeechEngine:didReceive:responseJson:)]) {
        [delegate aiSpeechEngine:self didReceive:recordId responseJson:jsonString];
    }
}

-(void)aiQEngine:(AiQEngine *)engine didReceive:(NSString *)recordId responseBinary:(NSData *)binaryData
{
    if (delegate &&
        [delegate respondsToSelector:@selector(aiSpeechEngine:didReceive:responseBinary:)]) {
        [delegate aiSpeechEngine:self didReceive:recordId responseBinary:binaryData];
    }
}

-(void)responseJsonThread:(NSDictionary *)dict
{
    @autoreleasepool {
        NSString *recordId = [dict objectForKey:@"recordId"];
        NSString *jsonString = [dict objectForKey:@"jsonString"];
        if (dirPath != nil) {
            NSString *filePath = [dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", recordId]];
            NSError *err = nil;
            [jsonString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
            if (err != nil) {
                NSLog(@"aiQEngine:didReceive:%@ responseJson:%@ writeToFileError:%@", recordId, jsonString, err);
            }
        }
        //update log & send
        //[aiRecordLog saveRecordId:recordId result:jsonString];
        //[self sendLog:recordId];
    }
}

#pragma mark - Log Function
//-(BOOL)isWiFiNetwork
//{
//    Reachability *r = [Reachability reachabilityForLocalWiFi];
//    if ([r isReachableViaWiFi]) {
//        return YES;
//    }
//    return NO;
//}
//
//-(NSDictionary *)getUserInfo
//{
//    CLLocationDegrees latitude = 0;//纬度
//    CLLocationDegrees longitude = 0;//经度
//    if ([LocationHelper sharedHelper].location != nil) {
//        latitude = [LocationHelper sharedHelper].location.coordinate.latitude;
//        longitude = [LocationHelper sharedHelper].location.coordinate.longitude;
//    };
//    return @{@"latitude": @(latitude),
//             @"longitude": @(longitude)};
//}

-(NSDictionary *)getDeviceInfo
{
    NSString *userInterfaceIdiom = @"";
    switch ([UIDevice currentDevice].userInterfaceIdiom) {
        case UIUserInterfaceIdiomPhone:
            userInterfaceIdiom = @"UIUserInterfaceIdiomPhone";
            break;
        case UIUserInterfaceIdiomPad:
            userInterfaceIdiom = @"UIUserInterfaceIdiomPad";
            break;
            
        default:
            break;
    }
    return @{@"name": [UIDevice currentDevice].name,
             @"systemName": [UIDevice currentDevice].systemName,
             @"systemVersion": [UIDevice currentDevice].systemVersion,
             @"model": [UIDevice currentDevice].model,
             @"localizedModel": [UIDevice currentDevice].localizedModel,
             @"userInterfaceIdiom": userInterfaceIdiom};
}

///**
// * 发送recordId对应的日志
// */
//- (void)sendLog:(NSString *)recordId
//{
//    if ([self isWiFiNetwork] == NO) {
//        return;
//    }
//    AiRecordLogBean *log = [aiRecordLog getLog:recordId];
//    if (log == nil) {
//        return;
//    }
//    NSDictionary *r = [log.result objectFromJSONString2];
//    if ([r objectForKey:@"result"] != nil) {
//        r = [r objectForKey:@"result"];
//    }
//    NSDictionary *resultDict = @{@"userId": [AiQEngine getDeviceId],
//                                 @"source": @"ADAPT_MES",
//                                 @"applicationId": appKey,
//                                 @"recordId": recordId,
//                                 @"version": engine.version,
//                                 @"params": [log.params objectFromJSONString2],
//                                 @"result": r,
//                                 @"user": [self getUserInfo],
//                                 @"device": [self getDeviceInfo]};
//    NSString *resultString = [resultDict JSONString2];
//    //NSLog(@"RESULT=%@", resultString);
//    NSURL *url = [NSURL URLWithString:kLogUrl];
//    logRequest = [ASIFormDataRequest requestWithURL:url];
//    //logRequest.delegate = self;//for DEBUG use
//    [logRequest setShouldCompressRequestBody:NO];
//    [logRequest setPostValue:resultString forKey:@"RESULT"];
//    
//    NSString *compressedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
//    [ASIDataCompressor compressDataFromFile:log.audioPath toFile:compressedFilePath error:nil];
//    [logRequest setFile:compressedFilePath forKey:@"AUDIO"];
//    [logRequest startAsynchronous];
//    
//    [aiRecordLog remove:recordId];
//}
//
//#pragma mark - ASIHTTPRequestDelegate
//-(void)requestFinished:(ASIHTTPRequest *)request
//{
//    NSLog(@"requestFinished: %@", request.responseString);
//}
//
//-(void)requestFailed:(ASIHTTPRequest *)request
//{
//    NSLog(@"requestFailed: %@", request.responseString);
//}

@end
