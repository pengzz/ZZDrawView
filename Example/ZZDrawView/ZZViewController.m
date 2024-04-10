//
//  ZZViewController.m
//  ZZDrawView
//
//  Created by pengzz on 12/14/2018.
//  Copyright (c) 2018 pengzz. All rights reserved.
//

#import "ZZViewController.h"
#import "ZZDrawViewManageView.h"

@interface ZZViewController ()
@property(nonatomic, strong)ZZDrawViewManageView *drawViewManageView;
@end

@implementation ZZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.drawViewManageView = [[ZZDrawViewManageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.drawViewManageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
