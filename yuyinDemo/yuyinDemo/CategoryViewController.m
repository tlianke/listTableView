//
//  CategoryViewController.m
//  yuyinDemo
//
//  Created by tlian on 15/3/11.
//  Copyright (c) 2015年 tlian. All rights reserved.
//

#import "CategoryViewController.h"
#import "ViewController.h"

@interface CategoryViewController ()
{
    NSArray *categoryArray;
}

@end

@implementation CategoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate =self;
    self.tableView.dataSource = self;
    categoryArray = @[@"单词",@"句子",@"段落"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return categoryArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = [categoryArray objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    ViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"vc"];
    vc.temp = [categoryArray objectAtIndex:indexPath.row];
    [self presentViewController:vc animated:YES completion:nil];
    
}

@end
