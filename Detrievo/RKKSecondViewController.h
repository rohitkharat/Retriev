//
//  RKKSecondViewController.h
//  Detrievo
//
//  Created by rkharat on 11/8/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <sqlite3.h>

@interface RKKSecondViewController : UIViewController

{
    ABPeoplePickerNavigationController *picker ;
    NSString *databasePath;
    BOOL taggedMyself;

}

-(BOOL)createDB;
-(NSString *)getPhotoLocation;

-(IBAction)showPhotoLibrary:(id)sender;

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@property (nonatomic, retain)  UIImagePickerController *imagePicker;
@property (nonatomic, retain)  IBOutlet UIImageView *imageView;
@property (nonatomic, retain) NSMutableArray *facesArray;
@property (nonatomic, retain) UIImage *originalImage;
@property (nonatomic, retain) CIImage *selectedImage;

@property (nonatomic, strong) NSString *imgURLString;

@property (nonatomic, retain) NSString *city;

@property (nonatomic, retain) NSURL *imgURL;

//@property (nonatomic) CGPoint leftEyePosition;
//@property (nonatomic) CGPoint rightEyePosition;
//@property (nonatomic) CGPoint mouthPosition;
//@property (nonatomic) CGRect bounds;

@end
