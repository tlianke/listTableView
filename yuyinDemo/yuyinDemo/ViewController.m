//
//  ViewController.m
//  yuyinDemo
//
//  Created by tlian on 15/3/10.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import "ViewController.h"
#import "RMDownloadIndicator.h"
#import "Common.h"
#import <AVFoundation/AVFoundation.h>
#import "AiUtil.h"
#import "AiQEngine.h"

@interface ViewController ()<AiSpeechEngineDelegate,AVAudioPlayerDelegate>
{
    RMDownloadIndicator *recordIndicator;
    RMDownloadIndicator *replayIndicator;
    NSString *lastRecordId;
    AVAudioPlayer *dingPlayer;
    AVAudioPlayer *dongPlayer;
    AVAudioPlayer *replayer;
    NSTimer *dingTimer;
    
    NSArray *wordArray;
    NSArray *sentArray;
    NSArray *predArray;
    
    int n;//随机取的数据项
}

@end

@implementation ViewController
@synthesize recordButton;
@synthesize temp;
@synthesize refText;
@synthesize graphView;

-(void)dealloc{
    NSLog(@"ViewController dealloc");
    [Common sharedInstance].engineDelegate = nil;
    [self resetEngine];
    [self stopRecordAnimate];
    [self.audioView resetLightState];
}

- (void)viewDidLoad {
    NSLog(@"ViewController viewDidLoad");

    [super viewDidLoad];
    
    graphView.lineColor = [UIColor whiteColor];

    
    [self.audioView initParams];
    UIColor *bgColor = [[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5];
    [self.audioView setBorderColor:bgColor];
    [self.audioView setBackgroundColor:bgColor];
    self.audioView.channelNumber = 3;
    
    n = arc4random() % 4;

    // 数组
    wordArray = @[@"hello",@"clean",@"color",@"red",@"green"];
    sentArray = @[@"how are you",@"thank you",@"long time no see",@"can you help me",@"to start working"];
    predArray = @[@{@"qid":@"PAPER-000005-QT-000001",
                    @"lm":@"It is my birthday tomorrow, so I will have a birthday party at my home."},
                  @{@"qid":@"PAPER-000005-QT-000002",
                    @"lm":@"It is my birthday tomorrow, so I will have a birthday party at my home."},
                  @{@"qid":@"PAPER-000005-QT-000003",
                    @"lm":@"It is my birthday tomorrow, so I will have a birthday party at my home."},
                  @{@"qid":@"PAPER-000005-QT-000004",
                    @"lm":@"It is my birthday tomorrow, so I will have a birthday party at my home."},
                  @{@"qid":@"PAPER-000005-QT-000005",
                    @"lm":@"It is my birthday tomorrow, so I will have a birthday party at my home."}];
    
    if ([@"单词" isEqualToString:temp]) {
        refText.text = [wordArray objectAtIndex:n];
    }else if ([@"句子"isEqualToString:temp]){
        refText.text = [sentArray objectAtIndex:n];
    }else{
        refText.text = [[predArray objectAtIndex:n] objectForKey:@"lm"];
    }
    
    
    if (dingPlayer == nil) {
        NSString *dingPath = [[NSBundle mainBundle] pathForResource:@"A_timealarm" ofType:@"mp3"];
        NSURL *musicUrl = [[NSURL alloc] initFileURLWithPath:dingPath];
        dingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicUrl error:nil];
        [dingPlayer prepareToPlay];
    }
    dingPlayer.delegate = self;
    if (dongPlayer == nil) {
        NSString *dongPath = [[NSBundle mainBundle] pathForResource:@"record_finish" ofType:@"wav"];
        NSData *dongData = [NSData dataWithContentsOfFile:dongPath];
        dongPlayer = [[AVAudioPlayer alloc] initWithData:dongData error:nil];
        [dongPlayer prepareToPlay];
    }
    dongPlayer.delegate = self;
    
    // 录音Button
    recordIndicator = [self createIndicator];
    [recordButton addSubview:recordIndicator];
    [recordIndicator addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recordButtonClicked)]];
    
    // 播放Button
    replayIndicator = [self createIndicator];
    [self.replayButton addSubview:replayIndicator];
    [replayIndicator addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(replayButtonClicked)]];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Function

-(RMDownloadIndicator *)createIndicator{
    RMDownloadIndicator *indicator = [[RMDownloadIndicator alloc] initWithFrame:CGRectMake(2, 2, 46, 46) type:kRMClosedIndicator];
    [indicator setBackgroundColor:[UIColor clearColor]];
    [indicator setStrokeColor:[UIColor whiteColor]];
    [indicator setClosedIndicatorBackgroundStrokeColor:[UIColor clearColor]];
    indicator.radiusPercent = 0.45;
    [indicator loadIndicator];
    indicator.userInteractionEnabled = YES;
    return indicator;
}

-(void)resetEngine{
    if ([dingPlayer isPlaying] || [replayer isPlaying]) {
        [dingPlayer stop];
        [replayer stop];
        [self stopReplayAnimate];
    }
    ENGINE_STATUS engineStatus = [Common sharedInstance].engineStatus;
    if (engineStatus == ENGINE_STATUS_NULL || engineStatus == ENGINE_STATUS_LOADING) {
        //[Common showEngineErrorAlertView:@"引擎正在初始化，请稍候..."];
        return;
    }else if(engineStatus == ENGINE_STATUS_ERROR){
        //[Common showEngineErrorAlertView:@"引擎初始化失败，请退出应用，稍候重试。"];
        return;
    }
    [[Common sharedInstance].engine reset];
}

-(void)playDingAndRecord{
    
    //    if (dingPlayer != nil) {
    //        [dingPlayer stop];
    //    }
    if (dingTimer!=nil) {
        [dingTimer invalidate];
    }
    dingTimer = [NSTimer scheduledTimerWithTimeInterval:0.648 target:self selector:@selector(startRecordAfterDing) userInfo:nil repeats:NO];
    [dingPlayer play];
    
}

-(void)startRecordAfterDing{
    
    NSString *coreType;
    NSDictionary *requestParams;
    NSTimeInterval recordDuration;
    if ([@"单词" isEqualToString:temp]) {
        recordDuration = 2.0;
        coreType = @"en.word.score";
        requestParams = @{@"coreType":coreType,
                          @"refText":[wordArray objectAtIndex:n],
                          @"rank":@100,
                          @"robust":@0};
    }else if ([@"句子"isEqualToString:temp]){
        recordDuration = 2.0;
        coreType = @"en.sent.score";
        requestParams = @{@"coreType":coreType,
                          @"refText":[sentArray objectAtIndex:n],
                          @"rank":@100,
                          @"robust":@0};
    }else{
        recordDuration = 8.0;
        coreType = @"en.pred.exam";
        requestParams = @{@"coreType":coreType,
                          @"refText":@{@"qid":[[predArray objectAtIndex:n] objectForKey:@"qid"],
                                       @"lm":[[predArray objectAtIndex:0] objectForKey:@"lm"]
                                       },
                          @"rank":@100,
                          @"precision":@0.5,
                          @"client_params":@{
                          @"ext_subitem_rank4":@0,
                          @"ext_word_details":@1,
                          @"ext_phn_details":@1}};
        
    }
    //    coreType = @"en.word.score";
    //    NSTimeInterval recordDuration = 2.0;
    //    NSInteger wordCount = [AiUtil getWordCount:@"How are you"];
    //    if (wordCount > 1) {
    //        coreType = @"en.sent.score";
    //        recordDuration = 2.0 + 0.6 * wordCount;
    //    }
    //    NSDictionary *requestParams = @{@"coreType":coreType,
    //                                    @"refText":@"How are you",
    //                                    @"rank":@100,
    //                                    @"robust":@0};
    NSString *userId = [AiQEngine getDeviceId];
    [Common sharedInstance].engine.userId = userId;
    lastRecordId = [[Common sharedInstance].engine startWithPath:NSTemporaryDirectory() isDirectory:YES duration:recordDuration requestParams:requestParams];
    NSLog(@"startRecord, recordId=%@", lastRecordId);
    if (lastRecordId==nil) {
        recordButton.selected = NO;
    }else{
        [self startRecordAnimate:0 duration:recordDuration];
    }
}

#pragma mark buttonCkick
- (void)recordButtonClicked{
    if ([[Common sharedInstance].audioHelper canRecord] == NO) {
        return;
    }
    [Common sharedInstance].engineDelegate = self;
    ENGINE_STATUS engineStatus = [Common sharedInstance].engineStatus;
    if (engineStatus == ENGINE_STATUS_NULL) {
        [Common showEngineErrorAlertView:@"引擎还未初始化"];
    }else if (engineStatus == ENGINE_STATUS_LOADING){
        [Common showEngineErrorAlertView:@"引擎正在初始化"];
    }else if (engineStatus == ENGINE_STATUS_ERROR){
        [Common showEngineErrorAlertView:@"引擎初始化失败"];
    }else{
        if (recordButton.selected == NO) {
            recordButton.selected = YES;
            self.replayButton.selected = NO;
            self.replayButton.hidden = YES;
            self.scoreLabel.text = @"";
            [self resetEngine];
            [graphView clearView];
            [self playDingAndRecord];
        }else{
            recordButton.selected = NO;
            [self.audioView resetLightState];
            self.replayButton.hidden = NO;
            if ([dingPlayer isPlaying]) {
                [dingPlayer stop];
            }
            if ([[Common sharedInstance].engine isRecording]) {
                [[Common sharedInstance].engine stop];
            }
            [self stopRecordAnimate];
        }
    }
}

- (void)replayButtonClicked {
    
    if (lastRecordId == nil) {
        return;
    }
    if (self.replayButton.selected == NO) {
        self.replayButton.selected = YES;
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",lastRecordId]];
            replayer = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:filePath] error:nil];
            replayer.delegate = self;
            [replayer prepareToPlay];
        [replayer play];
        [self startReplayAnimate:0 duration:replayer.duration];
    }else{
        self.replayButton.selected = NO;
        if ([replayer isPlaying]) {
            [replayer stop];
        }
        [self stopReplayAnimate];
    }
}

#pragma mark RMDownloadIndicator

- (void)startRecordAnimate:(NSTimeInterval)position duration:(NSTimeInterval)duration
{
    [recordIndicator setIndicatorAnimationDuration:0];
    [recordIndicator updateWithTotalBytes:duration downloadedBytes:position];
    [recordIndicator setIndicatorAnimationDuration:duration-position];
    [recordIndicator updateWithTotalBytes:duration downloadedBytes:duration];
}

- (void)startReplayAnimate:(NSTimeInterval)position duration:(NSTimeInterval)duration
{
    [replayIndicator setIndicatorAnimationDuration:0];
    [replayIndicator updateWithTotalBytes:duration downloadedBytes:position];
    [replayIndicator setIndicatorAnimationDuration:duration-position];
    [replayIndicator updateWithTotalBytes:duration downloadedBytes:duration];
}

- (void)stopReplayAnimate
{
    [replayIndicator setIndicatorAnimationDuration:0];
    [replayIndicator updateWithTotalBytes:100 downloadedBytes:0];
}

- (void)stopRecordAnimate
{
    [recordIndicator setIndicatorAnimationDuration:0];
    [recordIndicator updateWithTotalBytes:100 downloadedBytes:0];
    if (dingTimer!=nil) {
        [dingTimer invalidate];
    }
}

#pragma mark - AiSpeechEngineDelegate
// 引擎收到了json结果
-(void)aiSpeechEngine:(AiSpeechEngine *)engine didReceive:(NSString *)recordId responseJson:(NSString *)jsonString
{
    NSLog(@"aiSpeechEngine:didReceive:%@ responseJson:%@", recordId, jsonString);
    if ([recordId isEqualToString:lastRecordId]) {
        [dongPlayer play];
        NSDictionary *dict = [jsonString objectFromJSONString2];

        NSLog(@"%@",dict);
        NSDictionary *result = [dict objectForKey:@"result"];
        int overall = [[result objectForKey:@"overall"] intValue];
        self.scoreLabel.text = [NSString stringWithFormat:@"%i",overall];
    }
    
}

// 引擎运行完成
-(void)aiSpeechEngineDidFinishRecording:(AiSpeechEngine *)engine stopType:(AIENGINE_STOPTYPE)stopType
{
    NSLog(@"aiSpeechEngineDidFinishRecording:stopType:%d", stopType);
    if (stopType == AIENGINE_STOPTYPE_AUTO) {
        recordButton.selected = NO;
        self.replayButton.hidden = NO;
        [self stopRecordAnimate];
        
        [self.audioView resetLightState];
        
    }
    
}

/**
 * 引擎运行时，每隔 RECORD_INTERVAL_CALLBACK 会触发一次回调，通知应用已经运行的时长( 当前时间 - 引擎开始时间 )。可用于更新录音进度条
 * 获取 averagePower 和 peakPower 的值，需要设置 meteringEnabled = YES
 */
-(void)aiSpeechEngineIsRecording:(AiSpeechEngine *)engine passedTime:(NSTimeInterval)passedTime averagePower:(Float32)averagePower peakPower:(Float32)peakPower{
//    NSLog(@"mpeakPower : %f, maveragePower : %f",peakPower,averagePower);
    self.audioView.peakLevel = peakPower;
    self.audioView.level = averagePower;
    [self.audioView startRecordLightState];
}

-(void)aiSpeechEngineIsRecording:(AiSpeechEngine *)engine audioData:(const void *)audioData size:(int)size{
    //NSLog(@"isMainThread=%d", [NSThread currentThread].isMainThread);
    [graphView setWavData:audioData size:size];
}

// 引擎回放完成
-(void)aiSpeechEngineDidFinishReplaying:(AiSpeechEngine *)engine stopType:(AIENGINE_STOPTYPE)stopType{
    NSLog(@"回放完成");
}
#pragma mark AVAudioPlayerDelegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{

    if (player == replayer) {
        self.replayButton.selected = NO;
        [self stopReplayAnimate];
    }
}

- (IBAction)backButtonClicked:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
