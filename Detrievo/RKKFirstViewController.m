//
//  RKKFirstViewController.m
//  Detrievo
//
//  Created by rkharat on 11/8/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "RKKFirstViewController.h"
#import "RKKPhotoCollectionViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

static sqlite3 *database = nil;
static sqlite3_stmt *statement = nil;

@interface RKKFirstViewController () <ABPeoplePickerNavigationControllerDelegate, ABPersonViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSMutableArray *contactsArray;

@end

@implementation RKKFirstViewController

NSArray *searchResults;

@synthesize contactName;
@synthesize imagesFound;
@synthesize contactButton1, contactButton2, contactButton3, contactButton4;
@synthesize contactImage;
@synthesize selectedButtonTag;
@synthesize personHasImage, selectedContactFirstName, selectedContactLastName, myselfIcon;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self createDB];
    self.imageURLs = [[NSMutableArray alloc]init];
    self.images = [[NSMutableArray alloc]init];
    self.filteredImages = [[NSMutableArray alloc]init];
    self.retrievedPhotosArray = [[NSMutableArray alloc]init];
    retrievedPhoto = [[RKKRetrievedPhoto alloc]init];
    self.imagesFound = FALSE;
    self.citySelected = FALSE;
    self.datesSelected = FALSE;
    self.personSelected = FALSE;
    
    self.citiesArray = [[NSMutableArray alloc]init];
    self.namesToBeDisplayed = [[NSMutableString alloc]initWithString:@""];
    self.city = @"";
    self.personIds = [[NSMutableArray alloc]init];
    self.contactName.lineBreakMode = NSLineBreakByWordWrapping;
    
    UIImage *buttonImage = [[UIImage imageNamed:@"blueButton.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    [getPhotosButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    self.canDisplayBannerAds = TRUE;
    
    universalAppColor = [UIColor colorWithRed:0.23 green:0.49 blue:0.8 alpha:1.0];
    
    self.navigationController.navigationBar.barTintColor = universalAppColor;
    
    //----- code to change navigation title font and color --------
    CGRect frame = CGRectMake(0, 0, 400, 44);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:20];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"Retriev";
    [label setShadowColor:[UIColor darkGrayColor]];
    [label setShadowOffset:CGSizeMake(0, -0.5)];
    self.navigationItem.titleView = label;
    
//    //----- code to change imageview to circular view
//    UIImageView *contactImageView = [[UIImageView alloc]init];
//
//    contactImageView.layer.cornerRadius = 25;
//    contactImageView.layer.masksToBounds = YES;
//    contactImageView.image = [UIImage imageNamed:@"CF_Contact_Icon.png"];
//    
//    contactImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
//    contactImageView.layer.borderWidth = 1.0;
    
    defaultContactImage = [UIImage imageNamed:@"Icon-contact.png"];
    
    float cornerRadius = 25;
    UIColor *borderColor = [UIColor lightGrayColor];
    float borderWidth = 0.5;
    
    self.myselfIcon.layer.cornerRadius = cornerRadius;
    self.myselfIcon.layer.masksToBounds = YES;
    self.myselfIcon.layer.borderColor = borderColor.CGColor;
    self.myselfIcon.layer.borderWidth = borderWidth;
    
    self.contactButton1.layer.cornerRadius = cornerRadius;
    self.contactButton1.layer.masksToBounds = YES;
    self.contactButton1.layer.borderColor = borderColor.CGColor;
    self.contactButton1.layer.borderWidth = borderWidth;

    self.contactButton2.layer.cornerRadius = cornerRadius;
    self.contactButton2.layer.masksToBounds = YES;
    self.contactButton2.layer.borderColor = borderColor.CGColor;
    self.contactButton2.layer.borderWidth = borderWidth;
    
    self.contactButton3.layer.cornerRadius = cornerRadius;
    self.contactButton3.layer.masksToBounds = YES;
    self.contactButton3.layer.borderColor = borderColor.CGColor;
    self.contactButton3.layer.borderWidth = borderWidth;
    
    self.contactButton4.layer.cornerRadius = cornerRadius;
    self.contactButton4.layer.masksToBounds = YES;
    self.contactButton4.layer.borderColor = borderColor.CGColor;
    self.contactButton4.layer.borderWidth = borderWidth;
    
   // NSArray *personids = [NSArray arrayWithObjects:@"2",@"5",@"99999", nil];
   // [self getQueryForPersons:[NSMutableArray arrayWithArray:personids] andCity:@"San Francisco"];
}

-(BOOL)createDB{
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Build the path to the database file
    databasePath = [[NSString alloc] initWithString:
                    [docsDir stringByAppendingPathComponent: @"tagsDatabase.db"]];
    BOOL isSuccess = YES;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: databasePath ] == NO)
    {
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &database) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt =
            "CREATE TABLE IF NOT EXISTS PERSONS (PERSONID INTEGER PRIMARY KEY)";
            
            const char *sql_stmt_2 =
            "CREATE TABLE IF NOT EXISTS PHOTOS (IMG_URL TEXT PRIMARY KEY)";
            
            const char *sql_stmt_3 =
            "CREATE TABLE IF NOT EXISTS MAPPINGS (ID INTEGER PRIMARY KEY AUTOINCREMENT, PERSONID INTEGER, IMG_URL TEXT, CITY TEXT) ";
            
            if (sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg)
                != SQLITE_OK)
            {
                isSuccess = NO;
                NSLog(@"Failed to create table PERSONS");
            }
            
            if (sqlite3_exec(database, sql_stmt_2, NULL, NULL, &errMsg)
                != SQLITE_OK)
            {
                isSuccess = NO;
                NSLog(@"Failed to create table PHOTOS");
            }
            
            if (sqlite3_exec(database, sql_stmt_3, NULL, NULL, &errMsg)
                != SQLITE_OK)
            {
                isSuccess = NO;
                NSLog(@"Failed to create table MAPPINGS");
            }
            
            sqlite3_close(database);
            return  isSuccess;
        }
        
        else
        {
            isSuccess = NO;
            NSLog(@"Failed to open/create database");
        }
    }

    return isSuccess;
}

-(IBAction)displayContacts:(id)sender
{
    self.selectedButtonTag = [sender tag];
    _addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    self.contactsArray = [[NSMutableArray alloc]initWithCapacity:0];
    [self checkAddressBookAccess];

}

#pragma mark Address Book Access
// Check the authorization status of our application for Address Book
-(void)checkAddressBookAccess
{
    switch (ABAddressBookGetAuthorizationStatus())
    {
            // Update our UI if the user has granted access to their Contacts
        case  kABAuthorizationStatusAuthorized:
            [getPhotosOfLabel setHidden:TRUE];
            [self showPeoplePickerController];
            break;
            // Prompt the user for access to Contacts if there is no definitive answer
        case  kABAuthorizationStatusNotDetermined :
            [self requestAddressBookAccess];
            break;
            // Display a message if the user has denied or restricted access to Contacts
        case  kABAuthorizationStatusDenied:
        case  kABAuthorizationStatusRestricted:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning"
                                                            message:@"Permission was not granted for Contacts."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;
        default:
            break;
    }
}

// Prompt the user for access to their Address Book data
-(void)requestAddressBookAccess
{
    RKKFirstViewController * __weak weakSelf = self;
    
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error)
                                             {
                                                 if (granted)
                                                 {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [weakSelf showPeoplePickerController];
                                                         
                                                     });
                                                 }
                                             });
}

// This method is called when the user has granted access to their address book data.
-(void)showPeoplePickerController
{
    picker = [[ABPeoplePickerNavigationController alloc]init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
}


#pragma mark ABPeoplePickerNavigationControllerDelegate methods
// Displays the information of a selected person
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    [self.addButton setHidden:TRUE];
    
    self.selectedContactFirstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    self.selectedContactLastName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    self.personID = ABRecordGetRecordID(person);
    
    NSInteger recordID  =  ABRecordGetRecordID(person);
    [self.personIds addObject:[NSString stringWithFormat:@"%d", recordID]];
    
    NSLog(@"Name and ID: %@ %@ %d", self.selectedContactFirstName, self.selectedContactLastName, self.personID);
    
    if (self.namesToBeDisplayed.length != 0) {
        [self.namesToBeDisplayed appendString:@"\nand \n"];
    }
    if (self.selectedContactFirstName.length!=0) {
        [self.namesToBeDisplayed appendFormat:@"%@ ", self.selectedContactFirstName];
    }
    if (self.selectedContactLastName.length!=0) {
        [self.namesToBeDisplayed appendFormat:@"%@ ", self.selectedContactLastName ];
    }
    
    [self dismissViewControllerAnimated:picker completion:nil];
   
    [self.contactName setText: self.namesToBeDisplayed];
    [self.contactName sizeToFit];
    [self.contactName setHidden:FALSE];
    [self.myselfButton setHidden:TRUE];
    [self.personButton setHidden:TRUE];
    [self.resetButton setHidden:FALSE];
    self.personSelected = TRUE;
    
    if (self.personIds.count<4) {
        [self.addButton setHidden:FALSE];
    }
    //[self getPhotos];
    
    //get contact image of the selected contact
    if (ABPersonHasImageData(person))
    {
        self.personHasImage = TRUE;
        CFDataRef imageData = ABPersonCopyImageData(person);
        self.contactImage = [UIImage imageWithData:(__bridge NSData *)imageData];
        CFRelease(imageData);
    }
    else
        self.personHasImage = FALSE;
    
    [self displaySelectedContact];
    
    

  //  [firstName stringByAppendingString:(lastName)]
	return NO;
}

-(IBAction)reset:(id)sender
{
    [self.contactName setHidden:TRUE];
    [self.myselfButton setHidden:FALSE];
    [self.personButton setHidden:FALSE];
    [self.resetButton setHidden:TRUE];
    //[self.cityName setHidden:TRUE];
    [self.locationButton setHidden:FALSE];

    myself = FALSE;
    self.personSelected = FALSE;
    self.citySelected = FALSE;
    self.cityName.text = @"Location";
    self.city = @"";
    self.contactName.text = @"";
    [self.addButton setHidden:TRUE];
    [self.personIds removeAllObjects];
    self.namesToBeDisplayed = [[NSMutableString alloc]initWithString:@""];
    
    [myselfLabel setTextColor:[UIColor darkGrayColor]];
    [self.myselfIcon setBackgroundColor:[UIColor clearColor]];
    
    [self.contactButton1 setImage:defaultContactImage forState:UIControlStateNormal];
    [self.contactButton2 setImage:defaultContactImage forState:UIControlStateNormal];
    [self.contactButton3 setImage:defaultContactImage forState:UIControlStateNormal];
    [self.contactButton4 setImage:defaultContactImage forState:UIControlStateNormal];
    
    [firstName1 setHidden:TRUE];
    [firstName2 setHidden:TRUE];
    [firstName3 setHidden:TRUE];
    [firstName4 setHidden:TRUE];
    
    [lastName1 setHidden:TRUE];
    [lastName2 setHidden:TRUE];
    [lastName3 setHidden:TRUE];
    [lastName4 setHidden:TRUE];

    [getPhotosOfLabel setHidden:FALSE];
}

// Does not allow users to perform default actions such as dialing a phone number, when they select a person property.
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
								property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}

// Dismisses the people picker and shows the application when users tap Cancel.
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark ABPersonViewControllerDelegate methods
// Does not allow users to perform default actions such as dialing a phone number, when they select a contact property.
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person
					property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
	return NO;
}

//iOS 8 update. Added this delegate method to make sure the shouldContinueAfterSelectingPerson method is invoked.
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person;
{
    [self peoplePickerNavigationController:peoplePicker shouldContinueAfterSelectingPerson:person];
}

-(IBAction)setMyself:(id)sender
{
    myself = TRUE;
    self.personSelected = TRUE;
    
    [self.namesToBeDisplayed appendString:@"Myself"];
    [self.contactName setText: self.namesToBeDisplayed];
    //[self.contactName sizeToFit];

    [self.contactName setHidden:FALSE];
    [self.myselfButton setHidden:TRUE];
    [self.personButton setHidden:TRUE];
    [self.resetButton setHidden:FALSE];
    [self.addButton setHidden:FALSE];
    
    [self.personIds addObject:@"99999"];
    
    [myselfLabel setTextColor:universalAppColor];
    [self.myselfIcon setBackgroundColor:universalAppColor];
    [getPhotosOfLabel setHidden:TRUE];

    
}

-(void)getCities
{
    [self.citiesArray removeAllObjects];
    
    const char *dbPath = [databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &database) == SQLITE_OK)
    {
        
        char *error;
        NSString *querySQL;
        
            querySQL = [NSString stringWithFormat:@"select distinct city from mappings"];
        
        const char *select_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(database,
                               select_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                const char* city = (const char*)sqlite3_column_text(statement, 0);
                NSString *cityString = city == NULL ? nil : [[NSString alloc] initWithUTF8String:city];
                
                if (cityString &&  ![cityString isEqualToString:@"(null)"]) {
                    NSLog(@"adding city: %@", cityString);
                    [self.citiesArray addObject:cityString];
                }
                
                NSLog(@"no. of cities: %d", self.citiesArray.count);
                
            }
            
        }
        else
        {
            NSLog(@"some issue with prepared statement");
        }
        
        sqlite3_reset(statement);
        
    }
    
    sqlite3_close(database);
    
}

-(NSMutableString *)getQueryForPersons: (NSMutableArray *)personids andCity: (NSString *)city;
{
    NSMutableString *query;
    NSMutableString *cityQuery = @"";
    
    if (city.length != 0 && ![city isEqualToString:@"(null)"])
    {
        cityQuery = [NSMutableString stringWithFormat:@" city = '%@' and ", city];

    }
    
    if (personids.count == 0)
    {
        query = [NSMutableString stringWithFormat:@"select distinct img_url from mappings where city = '%@'", city];
    }

    
    if (personids.count == 1)
    {
        query = [NSMutableString stringWithFormat:@"select img_url from mappings where %@ personid=\'%@\'",cityQuery,[personids objectAtIndex:0]] ;
    }
    else if (personids.count > 1)
    {
        query = [NSMutableString stringWithFormat:@"select img_url from mappings where %@ personid=\'%@\' and IMG_URL in ",cityQuery, [personids objectAtIndex:0]] ;
        
        for (int i =1; i<personids.count -1 ; i++) {
            [query appendFormat:[NSString stringWithFormat:@"(select img_url from mappings where %@ personid=\'%@\' and IMG_URL in ",cityQuery,[personids objectAtIndex:i]]];
        }
        
        [query appendFormat:[NSString stringWithFormat:@"(select img_url from mappings where %@ personid=\'%@\' group by img_url ",cityQuery, [personids objectAtIndex:personids.count-1]]];
        
        for (int i =1; i<personids.count ; i++) {
            [query appendFormat:@")"];
        }
        
    }
    NSLog(@"dynamic query is: %@", query);

    return query;
}

-(BOOL)getPhotos
{
    //clear the existing images in array
    [self.imageURLs removeAllObjects];
    [self.retrievedPhotosArray removeAllObjects];
    [self.images removeAllObjects];
    self.imagesFound = FALSE;
    
    if (myself) {
        self.personID = 99999;
    }
    
    //get person id, city and date range from model
    const char *dbPath = [databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &database) == SQLITE_OK)
    {
        /*
         select * from mappings where personid="2" and IMG_URL in (select img_url from mappings  where   personid= "5" and img_url in (select IMG_URL from mappings where personid ="99999" group by IMG_URL) ) 
         */
        
        char *error;
        NSString *querySQL = [self getQueryForPersons:self.personIds andCity:self.city];
        
        const char *select_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(database,
                               select_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                self.imagesFound = TRUE;
                NSString *URLString = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
              
                NSURL *imageURL = [NSURL URLWithString:URLString];
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                
                
                [library assetForURL:imageURL resultBlock:^(ALAsset *asset)
                 {
                     if (asset) {
                         self.imagesFound = TRUE;

                         NSLog(@"url of the image = %@", URLString);
                         [self.imageURLs addObject:URLString];
                         //self.imageURLs = tempURLs;
                         
                         NSLog(@"no. of objects in array: %lu", (unsigned long)self.imageURLs.count);
                     }
                 }
                        failureBlock:^(NSError *error)
                 {
                     // error handling
                     NSLog(@"failure-----");
                 }];
                NSLog(@"OUTSIDE BLOCK no. of objects in array: %lu", (unsigned long)self.imageURLs.count);
                
            }
            
            if (!self.imagesFound)
            {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Sorry!" message:@"No photos found" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }

            
            //self.imageURLs = tempURLs;
            
        }
        else
        {
            NSLog(@"some issue with prepared statement");
        }
        
        sqlite3_reset(statement);
        
    }
    
    sqlite3_close(database);
    
//    //code to get image from url
//    for(NSString *imageURLString in self.imageURLs)
//    {
//        NSURL *imageURL = [NSURL URLWithString:imageURLString];
//        
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        [library assetForURL:imageURL resultBlock:^(ALAsset *asset)
//         {
//             if (asset) {
//                 
//                 
//                 UIImage  *copyOfOriginalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage] scale:0.5 orientation:UIImageOrientationUp];
//                 
//                 //add the image to a cell in the collection view
//                 //imageView.image = copyOfOriginalImage;
//                 
//                 //add the asset details in the retrievedPhoto object
//                 retrievedPhoto = [[RKKRetrievedPhoto alloc]init];
//                 
//                 retrievedPhoto.photoURL = imageURL;
//                 retrievedPhoto.photoLocation = [asset valueForProperty:ALAssetPropertyLocation];
//                 retrievedPhoto.photoDate = [asset valueForProperty:ALAssetPropertyDate];
//                 retrievedPhoto.image = copyOfOriginalImage;
//                 
//                 [self.images addObject:copyOfOriginalImage];
//                 [self.retrievedPhotosArray addObject:retrievedPhoto];
//                 NSLog(@"retrievedPhotosArray count = %lu", (unsigned long)self.retrievedPhotosArray.count);
//             }
//             
//         }
//                failureBlock:^(NSError *error)
//         {
//             // error handling
//             NSLog(@"failure-----");
//         }];
//    }
    
    if (self.imageURLs.count > 0) {
        NSLog(@"self.imageURLs count = %lu", (unsigned long)self.imageURLs.count);
        self.imagesFound = TRUE;
    }
    
    
    return self.imagesFound;
    
}

-(NSMutableArray *)checkRetrievedPhotos:(NSMutableArray *)retrievedPhotos
{
    NSLog(@"checking search criteria");
    if (self.citySelected && !self.datesSelected)
    {
        NSLog(@"city selected date not selected");
        for (RKKRetrievedPhoto *photo in self.retrievedPhotosArray)
        {
            CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
            [geocoder reverseGeocodeLocation:photo.photoLocation
                           completionHandler:^(NSArray *placemarks, NSError *error) {
                               
                               
                       if (error){
                           NSLog(@"Geocode failed with error: %@", error);
                           return;
                           
                       }
                       
                       
                       CLPlacemark *placemark = [placemarks objectAtIndex:0];
                       
                       NSLog(@"placemark.ISOcountryCode %@",placemark.ISOcountryCode);
                       NSLog(@"placemark.country %@",placemark.country);
                       NSLog(@"placemark.postalCode %@",placemark.postalCode);
                       NSLog(@"placemark.administrativeArea %@",placemark.administrativeArea);
                       NSLog(@"placemark.locality %@",placemark.locality);
                       NSLog(@"placemark.subLocality %@",placemark.subLocality);
                       NSLog(@"placemark.subThoroughfare %@",placemark.subThoroughfare);
                       
                   }];
        }
    }
    else if (!self.citySelected && self.datesSelected)
    {
        NSLog(@"city not selected, date selected");
        
    }
    else
    {
        NSLog(@"city and date selected");
        
    }
    return self.filteredImages;
    
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if (sender == infoButton)
    {
        return TRUE;
    }
 
    else if (!self.citySelected && !self.personSelected && !myself) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Please select a Person or a City" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return NO;
    }
    
    else
    {
        [self performSelectorOnMainThread:@selector(getPhotos) withObject:nil waitUntilDone:YES];
        return self.imagesFound;
    }
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

   // NSLog(@"number of urls being sent = %lu", (unsigned long)self.retrievedPhotosArray.count);
    
    if ([segue.identifier isEqualToString:@"showPhotos"])
    {
        
        RKKPhotoCollectionViewController *photoCollectionViewController = [segue destinationViewController];
        NSLog(@"at last stage... array count = %lu", (unsigned long)self.imageURLs.count);
        photoCollectionViewController.photoURLArray = self.imageURLs;
        photoCollectionViewController.interstitialPresentationPolicy = ADInterstitialPresentationPolicyAutomatic;
        
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [searchResults count];
        
    } else {
        return [self.citiesArray count];
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [searchResults objectAtIndex:indexPath.row];
    } else {
        cell.textLabel.text = [self.citiesArray objectAtIndex:indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        self.cityName.text = selectedCell.textLabel.text;
        self.city = selectedCell.textLabel.text;
        NSLog(@"did select row no. %d with title: %@", indexPath.row, self.cityName.text);
        [self.cityName setHidden:FALSE];
        //[self.locationButton setHidden:TRUE];
        [self.resetButton setHidden:FALSE];
        self.citySelected = TRUE;
        [self.searchDisplayController setActive:NO animated:YES];
    }
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"SELF contains[cd] %@",
                                    searchText];
    
    searchResults = [self.citiesArray filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

-(IBAction)showSearchDisplayController:(id)sender
{
    [self getCities];
    NSLog(@"show serach bar method");
    self.searchDisplayController.searchBar.scopeButtonTitles = nil;
    [self.searchDisplayController.searchBar setShowsScopeBar:NO];
    [self.searchDisplayController setActive:YES animated:YES];
    [self.searchDisplayController.searchBar setHidden:FALSE];
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searchDisplayController.searchBar setHidden:TRUE];

}

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1];
    [banner setAlpha:1];
    [UIView commitAnimations];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"error with Ad Banner: %@", error);
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1];
    [banner setAlpha:0];
    [UIView commitAnimations];
}

-(void)displaySelectedContact
{
    switch (self.selectedButtonTag) {
        case 1:
            [firstName1 setHidden:FALSE];
            [lastName1 setHidden:FALSE];
            if (selectedContactFirstName.length!=0)
                firstName1.text = self.selectedContactFirstName;
            if (self.selectedContactLastName.length!=0)
                lastName1.text = self.selectedContactLastName;
        
            if (self.personHasImage)
            {
                [self.contactButton1 setImage:self.contactImage forState:UIControlStateNormal];
            }
            else
                [self.contactButton1 setImage:defaultContactImage forState:UIControlStateNormal];
            break;
            
        case 2:
            [firstName2 setHidden:FALSE];
            [lastName2 setHidden:FALSE];
            if (selectedContactFirstName.length!=0)
                firstName2.text = self.selectedContactFirstName;
            if (self.selectedContactLastName.length!=0)
                lastName2.text = self.selectedContactLastName;
            
            if (self.personHasImage)
            {
                [self.contactButton2 setImage:self.contactImage forState:UIControlStateNormal];
            }
            else
                [self.contactButton2 setImage:defaultContactImage forState:UIControlStateNormal];
            break;
            
        case 3:
            [firstName3 setHidden:FALSE];
            [lastName3 setHidden:FALSE];
            if (selectedContactFirstName.length!=0)
                firstName3.text = self.selectedContactFirstName;
            if (self.selectedContactLastName.length!=0)
                lastName3.text = self.selectedContactLastName;
            
            if (self.personHasImage)
            {
                [self.contactButton3 setImage:self.contactImage forState:UIControlStateNormal];
            }
            else
                [self.contactButton3 setImage:defaultContactImage forState:UIControlStateNormal];
            break;
            
        case 4:
            [firstName4 setHidden:FALSE];
            [lastName4 setHidden:FALSE];
            if (selectedContactFirstName.length!=0)
                firstName4.text = self.selectedContactFirstName;
            if (self.selectedContactLastName.length!=0)
                lastName4.text = self.selectedContactLastName;
            
            if (self.personHasImage)
            {
                [self.contactButton4 setImage:self.contactImage forState:UIControlStateNormal];
            }
            else
                [self.contactButton4 setImage:defaultContactImage forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

