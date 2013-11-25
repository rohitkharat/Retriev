//
//  RKKFirstViewController.h
//  Detrievo
//
//  Created by rkharat on 11/8/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <sqlite3.h>


@interface RKKFirstViewController : UIViewController

{
    ABPeoplePickerNavigationController *picker ;
    IBOutlet UILabel *contactName;
    IBOutlet UIImageView *imageView;
    BOOL imagesFound;
    
    NSString *databasePath;

}

-(IBAction)displayContacts:(id)sender;

-(BOOL)createDB;

-(IBAction)getPhoto:(id)sender;

@property (nonatomic, retain) NSArray *persons;
@property (nonatomic) ABRecordID personID;
@property (nonatomic, retain) NSMutableArray *imageURLs;

@end
