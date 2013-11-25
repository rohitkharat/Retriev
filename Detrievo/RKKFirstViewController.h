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

@interface RKKFirstViewController : UIViewController

{
    ABPeoplePickerNavigationController *picker ;
    IBOutlet UILabel *contactName;
}

-(IBAction)displayContacts:(id)sender;

@end
