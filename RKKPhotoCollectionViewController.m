//
//  RKKPhotoCollectionViewController.m
//  Retriev
//
//  Created by Rohit Kharat on 11/25/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "RKKPhotoCollectionViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface RKKPhotoCollectionViewController ()

@end


@implementation RKKPhotoCollectionViewController

@synthesize photosArray;

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
    
    //initialize photos array here
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photosArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    
    //code to get image from url
    NSURL *imageURL = [NSURL URLWithString:[self.photosArray objectAtIndex:indexPath.row]];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:imageURL resultBlock:^(ALAsset *asset)
     {
         UIImage  *copyOfOriginalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage] scale:0.5 orientation:UIImageOrientationUp];
         
         recipeImageView.image = copyOfOriginalImage;
     }
            failureBlock:^(NSError *error)
     {
         // error handling
         NSLog(@"failure-----");
     }];

    
    //recipeImageView.image = [UIImage imageNamed:[self.photosArray objectAtIndex:indexPath.row]];
    
    return cell;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
