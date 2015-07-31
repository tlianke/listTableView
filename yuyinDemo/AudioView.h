//
//  AudioView.h
//  yuyinDemo
//
//  Created by tlian on 15/3/26.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LevelMeter.h"

@interface AudioView : UIView
{
UIColor *_bgColor,*_borderColor;
}

@property (nonatomic, assign) BOOL vertical;// 频道方向，YES表时垂直，NO表示横向
@property (nonatomic, assign) NSUInteger numLights;// 显示频道格数
@property (nonatomic, assign) NSInteger channelNumber;// 频道数（添加多个int值，1,2,3....）
@property (nonatomic, assign) BOOL useGL;// 是否使用OpenGL画图,默认为YES
@property (nonatomic, assign) float level;
@property (nonatomic, assign) float peakLevel;

-(void)setBorderColor: (UIColor *)borderColor;
-(void)setBackgroundColor: (UIColor *)backgroundColor;

/**
 初始化频道
 */
-(void)initParams;

/**
 结束录音，清除音效UI的亮状态
 */
-(void)resetLightState;

/**
 开始录音显示UI的
 */
-(void)startRecordLightState;

@end
