//
//  RKKFirstViewController.h
//  Detrievo
//
//  Created by rkharat on 11/8/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "RKKRetrievedPhoto.h"
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <sqlite3.h>


@interface RKKFirstViewController : UIViewController

{
    ABPeoplePickerNavigationController *picker ;
    IBOutlet UIImageView *imageView;
    BOOL imagesFound;
    
    NSString *databasePath;
    RKKRetrievedPhoto *retrievedPhoto;
    
    BOOL myself;
}

-(IBAction)displayContacts:(id)sender;

-(BOOL)createDB;

-(BOOL)getPhotos;

-(NSMutableArray *)checkRetrievedPhotos:(NSMutableArray *)retrievedPhotos;

-(IBAction)reset:(id)sender;
-(IBAction)setMyself:(id)sender;

@property (nonatomic, retain) NSArray *persons;
@property (nonatomic) ABRecordID personID;
@property (nonatomic, retain) NSMutableArray *imageURLs;
@property (nonatomic, retain) NSMutableArray *images;
@property (nonatomic, retain) NSMutableArray *retrievedPhotosArray;
@property (nonatomic, retain) NSMutableArray *filteredImages;

@property (nonatomic) BOOL citySelected;
@property (nonatomic) BOOL datesSelected;

@property (nonatomic, retain) NSString *city;
//@property (nonatomic, retain) NSDate *startDate;
//@property (nonatomic, retain) NSDate *endDate;

@property (nonatomic, retain) IBOutlet UILabel *contactName;
@property (nonatomic, retain) IBOutlet UIButton *myselfButton;
@property (nonatomic, retain) IBOutlet UIButton *personButton;
@property (nonatomic, retain) IBOutlet UIButton *resetButton;

@end
