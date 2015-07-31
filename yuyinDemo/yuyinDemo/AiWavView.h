//
//  AiWavView.h
//  yuyinDemo
//
//  Created by tlian on 15/3/24.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AiWavView : UIView

//当前view最多显示多长时间,默认3秒
@property(nonatomic, assign)NSInteger secPerView;

@property(nonatomic, retain)UIColor *lineColor;
@property(nonatomic, assign)CGFloat lineWidth;
@property (nonatomic, assign) int yFactor;//y轴放大系数，默认3
@property (nonatomic, assign) int accuracy;// 采样精确度，默认44

-(void)setWavData:(const void*)audioData size:(int)size;

/**
 清空波形图UI
 */
-(void)clearView;

@end
