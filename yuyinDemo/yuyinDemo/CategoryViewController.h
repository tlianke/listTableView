//
//  CategoryViewController.h
//  yuyinDemo
//
//  Created by tlian on 15/3/11.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoryViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
