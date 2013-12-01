//
//  RKKRetrievedPhoto.h
//  Retriev
//
//  Created by Rohit Kharat on 11/26/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface RKKRetrievedPhoto : NSObject

@property (nonatomic, strong) NSURL *photoURL;
@property (nonatomic, strong) NSDate *photoDate;
@property (nonatomic, strong) CLLocation *photoLocation;
@property (nonatomic, strong) UIImage *image;

@end

