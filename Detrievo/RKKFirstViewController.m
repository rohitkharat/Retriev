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
    imagesFound = FALSE;
    self.citySelected = FALSE;
    self.datesSelected = FALSE;
    
    self.citiesArray = [[NSMutableArray alloc]initWithObjects:@"New York", @"Phoenix",@"Los Angeles", @"Mumbai",@"San Jose", @"San Diego", @"Tempe", nil ];
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
    NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    self.personID = ABRecordGetRecordID(person);
    
    NSLog(@"Name and ID: %@ %@ %d", firstName, lastName, self.personID);
    [self dismissViewControllerAnimated:picker completion:nil];
    [self.contactName setText: [NSString stringWithFormat:@"%@ %@", firstName, lastName]];
    [self.contactName setHidden:FALSE];
    [self.myselfButton setHidden:TRUE];
    [self.personButton setHidden:TRUE];
    [self.resetButton setHidden:FALSE];
    //[self getPhotos];

  //  [firstName stringByAppendingString:(lastName)]
	return NO;
}

-(IBAction)reset:(id)sender
{
    [self.contactName setHidden:TRUE];
    [self.myselfButton setHidden:FALSE];
    [self.personButton setHidden:FALSE];
    [self.resetButton setHidden:TRUE];
    myself = FALSE;
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

-(IBAction)setMyself:(id)sender
{
    myself = TRUE;
    
    [self.contactName setText: @"Myself"];
    [self.contactName setHidden:FALSE];
    [self.myselfButton setHidden:TRUE];
    [self.personButton setHidden:TRUE];
    [self.resetButton setHidden:FALSE];

    
}


-(BOOL)getPhotos
{
    //clear the existing images in array
    [self.imageURLs removeAllObjects];
    [self.retrievedPhotosArray removeAllObjects];
    [self.images removeAllObjects];
    imagesFound = FALSE;
    
    if (myself) {
        self.personID = 99999;
    }
    
    //get person id, city and date range from model
    const char *dbPath = [databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &database) == SQLITE_OK)
    {
        
        char *error;
        NSString *querySQL;
        if (self.citySelected)
        {
            querySQL = [NSString stringWithFormat:@"select img_url from mappings where personid = \'%d\' and city = \'%@\'", self.personID, self.city];
        }
        else
        {
            querySQL = [NSString stringWithFormat:@"select img_url from mappings where personid = \'%d\'", self.personID];
        }
        
        const char *select_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(database,
                               select_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            int count = 0;
            
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                count++;
                imagesFound = TRUE;
                NSLog(@"found image for this person");
                NSString *URLString = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                NSLog(@"url of the image = %@", URLString);
                [self.imageURLs addObject:URLString];
                
                NSLog(@"no. of objects in array: %d", self.imageURLs.count);
                
            }
            
            if (!imagesFound) {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Oops!" message:@"No photos found" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
            
        }
        else
        {
            NSLog(@"some issue with prepared statement");
        }
        
        sqlite3_reset(statement);
        
    }
    
    sqlite3_close(database);
    
    //code to get image from url
    for(NSString *imageURLString in self.imageURLs)
    {
        NSURL *imageURL = [NSURL URLWithString:imageURLString];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:imageURL resultBlock:^(ALAsset *asset)
         {
             UIImage  *copyOfOriginalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage] scale:0.5 orientation:UIImageOrientationUp];
             
             //add the image to a cell in the collection view
             //imageView.image = copyOfOriginalImage;
             
             //add the asset details in the retrievedPhoto object
             retrievedPhoto = [[RKKRetrievedPhoto alloc]init];
             
             retrievedPhoto.photoURL = imageURL;
             retrievedPhoto.photoLocation = [asset valueForProperty:ALAssetPropertyLocation];
             retrievedPhoto.photoDate = [asset valueForProperty:ALAssetPropertyDate];
             retrievedPhoto.image = copyOfOriginalImage;
             
             [self.images addObject:copyOfOriginalImage];
             [self.retrievedPhotosArray addObject:retrievedPhoto];
             NSLog(@"retrievedPhotosArray count = %lu", (unsigned long)self.retrievedPhotosArray.count);
         }
                failureBlock:^(NSError *error)
         {
             // error handling
             NSLog(@"failure-----");
         }];
    }
    
    return imagesFound;
    
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
                               NSLog(@"reverseGeocodeLocation:completionHandler: Completion Handler called!");
                               
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
 
    return [self getPhotos];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    NSLog(@"number of photos being sent = %d", self.retrievedPhotosArray.count);
    
    if ([segue.identifier isEqualToString:@"showPhotos"])
    {
        
        RKKPhotoCollectionViewController *photoCollectionViewController = [segue destinationViewController];
        
        photoCollectionViewController.photosArray = self.images;
        
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
    [self.searchDisplayController setActive:YES animated:YES];
    [self.searchDisplayController.searchBar setHidden:FALSE];
    [self.searchDisplayController.searchBar setShowsScopeBar:FALSE];
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searchDisplayController.searchBar setHidden:TRUE];

}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end

