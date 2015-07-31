//
//  AiQRecorder.m
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import "AiQRecorder.h"
#import "airecorder.h"


#if !__has_feature(objc_arc)
#error "This source file must be compiled with ARC enabled!"
#endif

#define RECORD_INTERVAL_CALLBACK 1.0/30.0

@interface AiQRecorder ()
{
    airecorder *recorder;
    NSTimeInterval recordStartTime;
    //NSTimeInterval recordDuration;
    NSTimer *recordTimer;
    AudioQueueLevelMeterState *_chan_lvls;
}
@property(nonatomic, assign)BOOL stopByFunc;
@end

@implementation AiQRecorder
@synthesize currentTime, duration;
@synthesize delegate, tag;
@synthesize meteringEnabled;
@synthesize stopByFunc;

- (id)init
{
    //NSLog(@"AiQRecorder init");
    self = [super init];
    if (self) {
        delegate = nil;
        recorder = airecorder_new();
        _chan_lvls = malloc(sizeof(AudioQueueLevelMeterState)*1);
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"AiQRecorder dealloc");
    [self stopRecordTimer];
    if (recorder != NULL) {
        airecorder_delete(recorder);
    }
    free(_chan_lvls);
    //[super dealloc];
}

-(OSStatus)recordWithPath:(NSString *)path
{
    return [self recordWithPath:path duration:0];
}

- (OSStatus)recordWithPath:(NSString *)path duration:(NSTimeInterval)dur
{
    return [self recordWithPath:path duration:dur sampleRate:16000];
}

- (OSStatus)recordWithPath:(NSString *)path duration:(NSTimeInterval)dur sampleRate:(int)sampleRate
{
    [self stopRecordTimer];
    OSStatus rv = airecorder_start_record(recorder, [path UTF8String], sampleRate, airecorder_interval_callback, (__bridge const void *)(self), 100);
    if (rv == noErr) {//start record success
        UInt32 val = meteringEnabled;
        AudioQueueSetProperty(recorder->queue, kAudioQueueProperty_EnableLevelMetering, &val, sizeof(UInt32));
        
        duration = dur;
        recordStartTime = [[NSDate date] timeIntervalSince1970];
        [self startRecordTimer];
    }
    return rv;
}

-(OSStatus)stop
{
    return [self stopByStopType:AIENGINE_STOPTYPE_MANUAL];
}

-(OSStatus)stopByStopType:(AIENGINE_STOPTYPE)stopType
{
    [self stopRecordTimer];
    OSStatus rv = airecorder_stop_record(recorder);
    //fix me if aiQRecorderDidFinishRecording called before
    //last aiQRecorderPerformRecording
    if (delegate &&
        [delegate respondsToSelector:@selector(aiQRecorderDidFinishRecording:stopType:)]) {
        [delegate aiQRecorderDidFinishRecording:self stopType:stopType];
    }
    return rv;
}

-(OSStatus)startReplay
{
    stopByFunc = NO;
    OSStatus rv = airecorder_start_replay(recorder, false, airecorder_replay_stopped, (__bridge const void *)(self));
    return rv;
}

-(OSStatus)stopReplay
{
    return [self stopReplayByStopType:AIENGINE_STOPTYPE_MANUAL];
}

-(OSStatus)stopReplayByStopType:(AIENGINE_STOPTYPE)stopType
{
    stopByFunc = YES;
    OSStatus rv = airecorder_stop_replay(recorder);
    if (rv == noErr) {
        AiQRecorder *THIS = self;
        if (THIS.delegate &&
            [THIS.delegate respondsToSelector:@selector(aiQRecorderDidFinishReplaying:stopType:)]) {
            [THIS.delegate aiQRecorderDidFinishReplaying:THIS stopType:stopType];
        }
    }
    return rv;
}

-(void)startRecordTimer
{
    [self stopRecordTimer];
    recordTimer = [NSTimer timerWithTimeInterval:RECORD_INTERVAL_CALLBACK target:self selector:@selector(recordTimerIntervalCallback:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:recordTimer forMode:NSRunLoopCommonModes];
}

-(void)stopRecordTimer
{
    if (recordTimer != nil) {
        [recordTimer invalidate];
        recordTimer = nil;
    }
}

-(void)reset
{
    [self stopRecordTimer];
    if (recorder->is_recording) {
        [self stopByStopType:AIENGINE_STOPTYPE_RESET];
    }
    if(recorder->player->is_playing){
        [self stopReplayByStopType:AIENGINE_STOPTYPE_RESET];
    }
}

-(BOOL)isRecording
{
    return recorder->is_recording;
}

-(BOOL)isReplaying
{
    return recorder->player->is_playing;
}

-(NSTimeInterval)currentTime
{
    if (recordStartTime == 0) {
        return 0;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval passedTime = now - recordStartTime;
    return passedTime;
}

#pragma mark - callbacks
-(void)recordTimerIntervalCallbackMainThread:(NSTimer *)timer
{
    NSTimeInterval passedTime = [self currentTime];
    //NSLog(@"recordTimerIntervalCallbackMainThread: passedTime=%.2f", passedTime);
    //callback
    if (meteringEnabled && recorder->queue) {
        UInt32 data_sz = sizeof(AudioQueueLevelMeterState) * 1;//channels=1
        OSErr status = AudioQueueGetProperty(recorder->queue, kAudioQueueProperty_CurrentLevelMeter, _chan_lvls, &data_sz);
        Float32 mAveragePower =0, mPeakPower = 0;
        if (status == noErr){
            mAveragePower = _chan_lvls[0].mAveragePower;
            mPeakPower = _chan_lvls[0].mPeakPower;
        }
        if (delegate &&
            [delegate respondsToSelector:@selector(aiQRecorderIsRecording:passedTime:averagePower:peakPower:)]) {
            [delegate aiQRecorderIsRecording:self passedTime:passedTime averagePower:mAveragePower peakPower:mPeakPower];
        }
    }else{
        if (delegate &&
            [delegate respondsToSelector:@selector(aiQRecorderIsRecording:passedTime:averagePower:peakPower:)]) {
            [delegate aiQRecorderIsRecording:self passedTime:passedTime averagePower:0 peakPower:0];
        }
    }
    if (duration > 0 && passedTime >= duration) {//stop timer
        [recordTimer invalidate];
        recordTimer = nil;
        OSStatus rv = airecorder_stop_record(recorder);
        if (rv == noErr) {
            if (delegate &&
                [delegate respondsToSelector:@selector(aiQRecorderDidFinishRecording:stopType:)]) {
                [delegate aiQRecorderDidFinishRecording:self stopType:AIENGINE_STOPTYPE_AUTO];
            }
        }
        [self stopRecordTimer];
    }
}

-(void)recordTimerIntervalCallback:(NSTimer *)timer
{
    if ([NSThread currentThread].isMainThread) {
        [self recordTimerIntervalCallbackMainThread:timer];
        
    }else{
        [self performSelectorOnMainThread:@selector(recordTimerIntervalCallbackMainThread:) withObject:timer waitUntilDone:NO];
    }
}

void airecorder_interval_callback(const void *user_data, const void *audio_data, int size)
{
    @autoreleasepool {
        AiQRecorder *THIS = (__bridge AiQRecorder *)(user_data);
        if (THIS.delegate &&
            [THIS.delegate respondsToSelector:@selector(aiQRecorderPerformRecording:audioData:size:)]) {
            [THIS.delegate aiQRecorderPerformRecording:THIS audioData:audio_data size:size];
        }
    }
}

void airecorder_replay_stopped(const void *user_data)
{
    AiQRecorder *THIS = (__bridge AiQRecorder *)(user_data);
    if (THIS.stopByFunc == YES) {
        return;
    }
    if (THIS.delegate &&
        [THIS.delegate respondsToSelector:@selector(aiQRecorderDidFinishReplaying:stopType:)]) {
        [THIS.delegate aiQRecorderDidFinishReplaying:THIS stopType:AIENGINE_STOPTYPE_AUTO];
    }
}

@end
