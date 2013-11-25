//
//  RKKTabViewController.m
//  Detrievo
//
//  Created by rkharat on 11/16/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "RKKTabViewController.h"

@interface RKKTabViewController () <UITabBarDelegate, UITabBarControllerDelegate>

@end

@implementation RKKTabViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item; // called when a new view is selected by the user (but not programatically)
{
    NSLog(@"tab %i selected", [self.tabBarController selectedIndex]);
    
}

@end
