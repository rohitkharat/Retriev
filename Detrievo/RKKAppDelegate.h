//
//  RKKAppDelegate.h
//  Detrievo
//
//  Created by rkharat on 11/8/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKKAppDelegate : UIResponder <UIApplicationDelegate, UITabBarDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong)  UITabBarController *tabBarController;


@end
