//
//  RKKPhotoCollectionViewController.h
//  Retriev
//
//  Created by Rohit Kharat on 11/25/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKKPhotoCollectionViewController : UICollectionViewController


{
    //NSArray *photosArray;
    IBOutlet UIBarButtonItem *selectButton;
}

@property (nonatomic, strong) NSMutableArray *photosArray;

-(IBAction)selectPhotos:(id)sender;

@end
