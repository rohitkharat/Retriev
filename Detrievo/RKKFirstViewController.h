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
#import <iAd/iAd.h>


@interface RKKFirstViewController : UIViewController <ADBannerViewDelegate>

{
    ABPeoplePickerNavigationController *picker ;
    IBOutlet UIImageView *imageView;
    
    NSString *databasePath;
    RKKRetrievedPhoto *retrievedPhoto;
    
    BOOL myself;
    IBOutlet UIButton *getPhotosButton;
    
    UIImage *defaultContactImage;
    
    IBOutlet UILabel *firstName1;
    IBOutlet UILabel *lastName1;
    IBOutlet UILabel *firstName2;
    IBOutlet UILabel *lastName2;
    IBOutlet UILabel *firstName3;
    IBOutlet UILabel *lastName3;
    IBOutlet UILabel *firstName4;
    IBOutlet UILabel *lastName4;
    IBOutlet UILabel *myselfLabel;
    IBOutlet UILabel *getPhotosOfLabel;
    
    UIColor *universalAppColor;
    
    IBOutlet UIButton *infoButton;
    
}

-(IBAction)displayContacts:(id)sender;

-(BOOL)createDB;

-(BOOL)getPhotos;

-(NSMutableArray *)checkRetrievedPhotos:(NSMutableArray *)retrievedPhotos;

-(IBAction)showSearchDisplayController:(id)sender;

-(IBAction)reset:(id)sender;
-(IBAction)setMyself:(id)sender;

-(NSMutableString *)getQueryForPersons: (NSMutableArray *)personids andCity: (NSString *)city;

-(void)displaySelectedContact;

@property (nonatomic, retain) NSArray *persons;
@property (nonatomic) ABRecordID personID;
@property (nonatomic, retain) NSMutableArray *imageURLs;
@property (nonatomic, retain) NSMutableArray *images;
@property (nonatomic, retain) NSMutableArray *retrievedPhotosArray;
@property (nonatomic, retain) NSMutableArray *filteredImages;

@property (nonatomic) BOOL citySelected;
@property (nonatomic) BOOL datesSelected;
@property (nonatomic) BOOL personSelected;

@property (nonatomic, retain) NSString *city;
//@property (nonatomic, retain) NSDate *startDate;
//@property (nonatomic, retain) NSDate *endDate;

@property (nonatomic, retain) IBOutlet UILabel *contactName;
@property (nonatomic, retain) IBOutlet UILabel *cityName;
@property (nonatomic, retain) IBOutlet UIButton *myselfButton;
@property (nonatomic, retain) IBOutlet UIButton *personButton;
@property (nonatomic, retain) IBOutlet UIButton *locationButton;
@property (nonatomic, retain) IBOutlet UIButton *resetButton;

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *citiesArray;
@property (nonatomic, strong) IBOutlet UITableView *searchResults;

@property (nonatomic, retain) NSMutableString *namesToBeDisplayed;
@property (nonatomic, retain) NSMutableArray *personIds;
@property (nonatomic, retain) IBOutlet UIButton *addButton;

@property (nonatomic, retain) IBOutlet UIButton *contactButton1;
@property (nonatomic, retain) IBOutlet UIButton *contactButton2;
@property (nonatomic, retain) IBOutlet UIButton *contactButton3;
@property (nonatomic, retain) IBOutlet UIButton *contactButton4;

@property (nonatomic, retain) UIImage *contactImage;
@property (nonatomic) NSInteger selectedButtonTag;
@property (nonatomic) BOOL personHasImage;
@property (nonatomic, retain) NSString *selectedContactFirstName;
@property (nonatomic, retain) NSString *selectedContactLastName;
@property (nonatomic, retain) IBOutlet UIButton *myselfIcon;

@property BOOL imagesFound;


@end
