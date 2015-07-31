//
//  AiWavView.m
//  yuyinDemo
//
//  Created by tlian on 15/3/24.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import "AiWavView.h"

@interface AiWavView()
{
    NSOperationQueue *myQueue;
    NSMutableArray *pointYArr;//view中所有的点
    NSInteger maxPointXY;//view中最多显示点的个数
    CGFloat dotWidth;//view中每个点的宽度
    CGFloat viewHeightHalf;//当前视图高度的一半
    CGFloat dotDensity;// 点的密度
}

@end

@implementation AiWavView

- (id)init
{
    self = [super init];
    if (self) {
        [self initParams];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initParams];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initParams];
    }
    return self;
}

-(void)initParams
{
    myQueue = [[NSOperationQueue alloc] init];
    [myQueue setMaxConcurrentOperationCount:1];
    pointYArr = [[NSMutableArray alloc] initWithCapacity:30];
    viewHeightHalf = self.bounds.size.height/2;
    _lineColor = [UIColor redColor];
    _lineWidth = 0.5f;
    dotDensity = 360.0;//依据屏幕像素来设置的初始值
    _yFactor = 3;
    _accuracy = floor(16000.0/dotDensity);
    [self setSecPerView:3.0];
}

-(void)setAccuracy:(int)accuracy{
    _accuracy = accuracy;
    dotDensity=16000.0/_accuracy;
    [self setSecPerView:_secPerView];
}

-(void)setSecPerView:(NSInteger)sp
{
    //secPerView=3, maxPointXY=16000*3
    _secPerView = sp;
    maxPointXY=_secPerView*dotDensity;
    dotWidth=self.frame.size.width/maxPointXY;
    //NSLog(@"dotWidth=%.2f", dotWidth);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();// 获取画布
    CGContextSetStrokeColorWithColor(context, _lineColor.CGColor);// 线条颜色
    CGContextSetShouldAntialias(context, NO); // 设置线条平滑，不需要两边像素宽
    CGContextSetLineWidth(context, _lineWidth);// 设置线宽
    //UIGraphicsPushContext(context);
    CGContextBeginPath(context);
    for (int i=0; i<[pointYArr count]; i++) {
        if (i < [pointYArr count]){
            CGFloat px=i*dotWidth;
            int y = [[pointYArr objectAtIndex:i] intValue];
            //365以内的小音量忽略
            CGFloat py1 = viewHeightHalf-viewHeightHalf*(y)/32768.0*_yFactor;
            if (i==0) {
                CGContextMoveToPoint(context,  px, py1);//线条起点
            }else{
                CGContextAddLineToPoint(context, px, py1);//线条结束点
            }
        }
    }
    CGContextStrokePath(context);// 结束，开始画图
    //UIGraphicsPopContext();
}

#pragma mark - Function
-(void)setWavData:(const void *)audioData size:(int)size
{
    if(audioData==NULL || size==0){return;}
    unsigned char *cData = (unsigned char *)malloc(size);
    memcpy(cData, audioData, size);
    NSValue *data = [NSValue valueWithPointer:cData];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                           selector:@selector(calculateWavDataInBackground:)
                                                                              object:@{@"data":data,
                                                                                       @"size":@(size)}];
    [myQueue addOperation:operation];
    //[self calculateWavDataInBackground:@{@"data":data, @"size":@(size)}];
}

-(void)calculateWavDataInBackground:(NSDictionary *)dict
{
    @autoreleasepool {
        NSValue *dataValue = [dict objectForKey:@"data"];
        unsigned char *audioData = [dataValue pointerValue];
        int size = [[dict objectForKey:@"size"] intValue];
        if (audioData!=NULL) {
            // 数组的大小
            NSUInteger s = size / 2;
            NSMutableArray *yArr = [[NSMutableArray alloc] initWithCapacity:16];
            int m = 0;
            for (long i =0; i < s; i ++) {
                m ++;
                /*
                 ** unsigned char 是8位的，我们的音频是16位的，所以这里把data数组的高8位和低8位合并为一个数据，
                 ** 作为一个波形图的点来显示
                 */
                short int d = ((audioData[i * 2 + 1]<<8) | audioData[i * 2]);//[-32768, 32767]
                if (m % _accuracy == 0) {
                    [yArr addObject:@(d)];
                }
            }
            [self performSelectorOnMainThread:@selector(setPointYInQueue:) withObject:yArr waitUntilDone:NO];
            free(audioData);
        }
    }
}


/**
 一维数组，每一项为一个音频数据
 */
-(void)setPointYInQueue:(NSArray *)yArr
{
    if ([pointYArr count]+[yArr count]<=maxPointXY) {
        //加到数组尾部
        [pointYArr addObjectsFromArray:yArr];
    }else{
        //len是多出来的点的个数，需要从数组中移除
        NSInteger len = ([pointYArr count]+[yArr count]-maxPointXY);
        if ([pointYArr count] < len) {
            [pointYArr removeAllObjects];
        }else{
            [pointYArr removeObjectsInRange:NSMakeRange(0, len)];
        }
        [pointYArr addObjectsFromArray:yArr];
    }
    [self setNeedsDisplay];
}

-(void)clearView
{
    [myQueue cancelAllOperations];
    [pointYArr removeAllObjects];
    [self setNeedsDisplay];
}

@end
