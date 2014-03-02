//
//  RKKPhotoCollectionViewController.h
//  Retriev
//
//  Created by Rohit Kharat on 11/25/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKKPhotoCollectionViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>


{
    //NSArray *photosArray;
    IBOutlet UIBarButtonItem *selectButton;
    IBOutlet UIButton *collageButton;
}

@property (nonatomic, strong) NSMutableArray *photoURLArray;
@property (nonatomic, strong) NSMutableArray *photosArray;

@property(weak, nonatomic) IBOutlet UICollectionView *collView;

@property (nonatomic, retain) NSString *filePath;
@property (nonatomic,retain ) NSString *pathy;
@property (nonatomic)  BOOL didCreateVideo;
@property (copy,   nonatomic) NSURL *movieURL;

- (IBAction)collageMaking:(id)sender;
- (IBAction)share:(id)sender;
- (IBAction)collagey:(id)sender;

-(IBAction)selectPhotos:(id)sender;
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width;



@end
