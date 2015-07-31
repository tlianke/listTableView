//
//  ViewController.h
//  yuyinDemo
//
//  Created by tlian on 15/3/10.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AiWavView.h"
#import "AudioView.h"

@interface ViewController : UIViewController

@property (nonatomic, copy)NSString *temp;//"单词", "句子", "段落"
@property (weak, nonatomic) IBOutlet UILabel *refText;

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;

@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (weak, nonatomic) IBOutlet AiWavView *graphView;
@property (weak, nonatomic) IBOutlet AudioView *audioView;

- (IBAction)backButtonClicked:(id)sender;
@end

