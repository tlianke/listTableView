//
//  AudioView.m
//  yuyinDemo
//
//  Created by tlian on 15/3/26.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import "AudioView.h"
#import "LevelMeter.h"
#import "GLLevelMeter.h"

#define kPeakFalloffPerSec	.7
#define kLevelFalloffPerSec .8

@interface AudioView ()
{
    
    BOOL showPeaks;
    CGFloat _refreshHz;
    NSTimer *updateTimer;
    NSArray *subLevelMeters;
    CFAbsoluteTime _peakfalloffLastFire;// 最后录音结束时间
    NSMutableArray *_channelNumbers;// 频道数组（一个频道向数组中添加元素[NSNumber numberWithInt:0],多个添加多个int值，0,1,2,3....）
}

@end

@implementation AudioView
- (id)init
{
    self = [super init];
    if (self) {
        [self defaultInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self defaultInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self defaultInit];
    }
    return self;
}

#pragma mark Set方法

-(void)setChannelNumber:(int)channelNumber{
    _channelNumber = channelNumber;
    [self initChannelNumberArray];
}

-(void)setUseGL:(BOOL)useGL{
    _useGL = useGL;
    [self initParams];
}

#pragma mark init

-(void)defaultInit{
    // 默认值
//    UIColor *Color = [[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5];
    UIColor *color = [UIColor colorWithRed:.39 green:.44 blue:.57 alpha:1];
    _bgColor =color;
    _borderColor = color;
    _refreshHz = 1. / 30.;
    showPeaks = YES;
    _vertical = NO;
    _useGL = YES;
    _numLights = 30;
    _channelNumbers =[[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:1], nil];
}

-(void)initParams{
    int i;
    for (i = 0; i < [subLevelMeters count]; i++) {
        UIView *Meter = [subLevelMeters objectAtIndex:i];
        [Meter removeFromSuperview];
    }
    NSMutableArray *meters_build = [[NSMutableArray alloc] initWithCapacity:[_channelNumbers count]];
    CGRect totalRect;
    
    if (_vertical) totalRect = CGRectMake(0., 0., [self frame].size.width + 2., [self frame].size.height);
    else totalRect = CGRectMake(0., 0., self.frame.size.width, self.frame.size.height + 2.0);
    
    for (i = 0; i < [_channelNumbers count]; i ++) {
        CGRect fr;
        if (_vertical) {
            fr = CGRectMake(
                            totalRect.origin.x + (((CGFloat)i / (CGFloat)[_channelNumbers count]) * totalRect.size.width),
                            totalRect.origin.y,
                            (1. / (CGFloat)[_channelNumbers count]) * totalRect.size.width - 2.,
                            totalRect.size.height
                            );
        }else{
            fr = CGRectMake(
                            totalRect.origin.x,
                            totalRect.origin.y + (((CGFloat)i / (CGFloat)[_channelNumbers count]) * totalRect.size.height),
                            totalRect.size.width,
                            (1. / (CGFloat)[_channelNumbers count]) * totalRect.size.height - 2.
                            );
        }
        LevelMeter *newMeter;
        if (_useGL) {
            newMeter = [[GLLevelMeter alloc] initWithFrame:fr];
        }else{
            newMeter = [[LevelMeter alloc] initWithFrame:fr];
        }
        newMeter.numLights = _numLights;
        newMeter.vertical = _vertical;
        newMeter.bgColor = _bgColor;
        newMeter.borderColor = _borderColor;
        [meters_build addObject:newMeter];
        [self addSubview:newMeter];
    }
    subLevelMeters = [[NSArray alloc] initWithArray:meters_build];
}

-(void)initChannelNumberArray{
    if (_channelNumbers) {
        [_channelNumbers removeAllObjects];
    }
    for (int i = 0; i < _channelNumber; i++) {
        [_channelNumbers addObject:[NSNumber numberWithInt:i]];
    }
    [self initParams];
}
-(void)refresh{

    CGFloat maxLvl = -1.;
    CFAbsoluteTime thisFire = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime timepassed = thisFire - _peakfalloffLastFire;
    for (LevelMeter *meter in subLevelMeters) {
        CGFloat newPeak, newLevel;
        newLevel = meter.level - timepassed * kLevelFalloffPerSec;
        if (newLevel < 0.) newLevel = 0.;
        meter.level = newLevel;
        if (showPeaks) {
            newPeak = meter.peakLevel -timepassed *kPeakFalloffPerSec;
            if (newPeak < 0.) newPeak = 0.;
            meter.peakLevel = newPeak;
            if (newPeak > maxLvl) maxLvl = newPeak;
        }
        else if (newLevel > maxLvl) maxLvl = newLevel;
        [meter setNeedsDisplay];
    }
    
    if (maxLvl <= 0.) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
    _peakfalloffLastFire = thisFire;
}

-(void)resetLightState{
    if (updateTimer) [updateTimer invalidate];
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:_refreshHz
                                                   target:self
                                                 selector:@selector(refresh)
                                                 userInfo:nil
                                                  repeats:YES];
}

-(void)startRecordLightState{
    for (int i = 0; i < [_channelNumbers count]; i ++) {
        NSInteger channelIdx = [(NSNumber *)[_channelNumbers objectAtIndex:i] intValue];
        LevelMeter *meter = [subLevelMeters objectAtIndex:channelIdx];
        meter.level = _level;
        meter.peakLevel = _peakLevel;
        _peakfalloffLastFire = CFAbsoluteTimeGetCurrent();
        [meter setNeedsDisplay];
    }
}

-(void)setBorderColor: (UIColor *)borderColor
{
    _borderColor = borderColor;

    for (NSUInteger i=0; i < [subLevelMeters count]; i++)
    {
        id meter = [subLevelMeters objectAtIndex:i];
        if (_useGL)
        {
            ((GLLevelMeter*)meter).borderColor = nil;
            ((GLLevelMeter*)meter).borderColor = borderColor;
        }
        else
        {
            ((LevelMeter*)meter).borderColor = nil;
            ((LevelMeter*)meter).borderColor = borderColor;
        }
    }
}

-(void)setBackgroundColor: (UIColor *)bgColor
{
    _bgColor = bgColor;
    
    for (NSUInteger i=0; i < [subLevelMeters count]; i++)
    {
        id meter = [subLevelMeters objectAtIndex:i];
        if (_useGL) {
            ((GLLevelMeter*)meter).bgColor = nil;
            ((GLLevelMeter*)meter).bgColor = bgColor;
        } else {
            ((LevelMeter*)meter).bgColor = nil;
            ((LevelMeter*)meter).bgColor = bgColor;
        }
    }
    
}

@end
