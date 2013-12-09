//
//  RKKCameraViewController.m
//  Detrievo
//
//  Created by rkharat on 11/16/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "RKKCameraViewController.h"
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>

static sqlite3 *database = nil;
static sqlite3_stmt *statement = nil;

@interface RKKCameraViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate,ABPeoplePickerNavigationControllerDelegate, ABPersonViewControllerDelegate>

@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSMutableArray *contactsArray;

@end

@implementation RKKCameraViewController

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
    taggedMyself = FALSE;
    [self createDB];
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    // You code here to update the view.
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
    
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
            "CREATE TABLE IF NOT EXISTS MAPPINGS (ID INTEGER PRIMARY KEY AUTOINCREMENT, PERSONID INTEGER, IMG_URL TEXT) ";
            
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

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    taggedMyself = FALSE;
    
    UIImage *clickedImage = info[UIImagePickerControllerEditedImage];

    
    UIImageWriteToSavedPhotosAlbum(clickedImage,
                                   self,
                                   @selector(image:finishedSavingWithError:contextInfo:),
                                   nil);
    
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
    //  [self.imageView setFrame:CGRectMake(0, 0, selectedImage.size.width, selectedImage.size.height)];
    
    self.imgURLString = [info objectForKey:UIImagePickerControllerReferenceURL];
    self.imgURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    //print file name
    NSLog(@"image url is %@", self.imgURLString);
    
    self.imageView = [[UIImageView alloc]initWithImage:selectedImage];
    //self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (self.view.frame.size.height - 230))];
    
    float scale = self.imageView.frame.size.width/selectedImage.size.width;
    NSLog(@"scale: %f",scale);
    
    //assets-library://asset/asset.JPG?id=79465E8C-53B9-40D6-B11C-07A1856E9093&ext=JPG
    
    //assets-library://asset/asset.JPG?id=85991B66-F94B-4010-B2BD-6ED516E1C90A&ext=JPG
    
    self.imageView.image = selectedImage;
    
    //    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    
    [self.view addSubview:self.imageView];
    
    // Execute the method used to detect faces in background
    [self performSelectorInBackground:@selector(detectFaces:) withObject:selectedImage];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

-(void)image:(UIImage *)image
finishedSavingWithError:(NSError *)error
 contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Save failed"
                              message: @"Failed to save image"\
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }

}
//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
//    
//    [picker dismissViewControllerAnimated:YES completion:NULL];
//    
//}

-(void)detectFaces: (UIImage *)facePhoto
{
    self.originalImage = facePhoto;
    self.selectedImage = [CIImage imageWithCGImage:facePhoto.CGImage];
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    
    self.facesArray = [NSMutableArray arrayWithArray:[detector featuresInImage:self.selectedImage]];
    
    NSLog(@"number of faces: %d", self.facesArray.count);
    NSLog(@"faces array %@", self.facesArray);
    for (CIFaceFeature *faceFeature in self.facesArray) {
        
        CGRect modifiedFaceBounds = faceFeature.bounds;
        
        //store each modifiedFaceBound inside a global array here which will be accessed in touches began method below
        
        modifiedFaceBounds.origin.y = facePhoto.size.height-faceFeature.bounds.size.height-faceFeature.bounds.origin.y;
        
        //  modifiedFaceBounds.origin.x = facePhoto.size.width-faceFeature.bounds.size.width-faceFeature.bounds.origin.x;
        
        UIView *faceView = [[UIView alloc]initWithFrame:modifiedFaceBounds];
        
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [[UIColor blueColor] CGColor];
        
        [self.imageView addSubview:faceView];
    }
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // NSLog(@"touches began");
    
    //get the location of the touch
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    
    //check if the touch is within any of the face boxes.... so store the face boxes in an array... iterate over the array n run the below if condition for each face box.
    for (CIFaceFeature *faceFeature in self.facesArray)
    {
        CGRect faceBounds = faceFeature.bounds;
        
        faceBounds.origin.y = self.originalImage.size.height-faceFeature.bounds.size.height-faceFeature.bounds.origin.y;
        
        
        if (CGRectContainsPoint(faceBounds, touchPoint))
        {
            // NSLog(@"oh yeah!");
            if (!taggedMyself)
            {
                //Ask user whether he wants to tag himself or another person
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to Tag?"
                                                                         delegate:self
                                                                cancelButtonTitle:@"Another Person"
                                                           destructiveButtonTitle:@"Myself"
                                                                otherButtonTitles:nil];
                
                actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
                [actionSheet showInView:self.view];
            }
            else
            {
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tag Photo" message:@"Do you want to tag this person?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
                [alert show];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    NSLog(@"button clicked in alert");
    if (buttonIndex == 0) {
        //present contact list for tagging the person
        NSLog(@"OK button clicked");
        [self displayContacts];
        
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        //tag myself
        taggedMyself = TRUE;
        [self tagPerson:99999];
        
    }
    else
    {
        [self displayContacts];
        
    }
}

-(void)displayContacts
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
    RKKCameraViewController * __weak weakSelf = self;
    
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
    
    NSLog(@"Name: %@ %@", firstName, lastName);
    [self dismissViewControllerAnimated:picker completion:nil];
    //[contactName setText: [NSString stringWithFormat:@"%@ %@", firstName, lastName]];
    //  [firstName stringByAppendingString:(lastName)]
    ABRecordID recordID = ABRecordGetRecordID(person);
    NSLog(@"%d", recordID);
    
    [self tagPerson:recordID];
    
    return NO;
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

-(void)tagPerson: (ABRecordID)recordID
{
    [self getPhotoLocation];
    
    const char *dbPath = [databasePath UTF8String];
    
    if (sqlite3_open(dbPath, &database) == SQLITE_OK)
    {
        
        NSString *insertPersonSQL = [NSString stringWithFormat:@"INSERT INTO PERSONS VALUES (\"%d\")", recordID];
        const char *insert_stmt = [insertPersonSQL UTF8String];
        char *error;
        
        if (sqlite3_exec(database, insert_stmt, NULL, NULL, &error) == SQLITE_OK) {
            NSLog(@"insterted person");
        }
        else
        {
            NSLog(@"error %s", error);
        }
        
        NSString *insertPhotoSQL = [NSString stringWithFormat:@"INSERT INTO PHOTOS VALUES (\"%@\")", self.imgURL];
        insert_stmt = [insertPhotoSQL UTF8String];
        
        if (sqlite3_exec(database, insert_stmt, NULL, NULL, &error) == SQLITE_OK) {
            NSLog(@"insterted photo");
        }
        else
        {
            NSLog(@"error %s", error);
        }
        
        
        NSString *querySQL = [NSString stringWithFormat:@"select id from mappings where personid = \'%d\' and img_url = \"%@\" ", recordID, self.imgURL];
        const char *select_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(database,
                               select_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSLog(@"mapping already exists");
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"This person has already been tagged in this photo!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
            
            else
            {
                 NSString *insertMappingSQL = [NSString stringWithFormat:@"INSERT INTO MAPPINGS (PERSONID, IMG_URL, CITY) VALUES (\"%d\",\"%@\" ,\"%@\")", recordID, self.imgURLString, self.city];
                
                //without city
               // NSString *insertMappingSQL = [NSString stringWithFormat:@"INSERT INTO MAPPINGS (PERSONID, IMG_URL) VALUES (\"%d\",\"%@\")", recordID, self.imgURL];
                
                insert_stmt = [insertMappingSQL UTF8String];
                
                if (sqlite3_exec(database, insert_stmt, NULL, NULL, &error) == SQLITE_OK) {
                    NSLog(@"insterted mapping");
                }
                else
                {
                    NSLog(@"error %s", error);
                }
                
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

-(NSString *)getPhotoLocation
{
    NSLog(@"getting photo with url: %@", self.imgURL);
    // NSURL *imageURL = [NSURL URLWithString:self.imgURLString];
    
    //getting exception here!!
    //remove exception
    //remove unwanted code from other first view controller like use of RKKRetrievedPhoto Object
    //work on city search display controller
    //check if code takes both search criteria if city and name is selected
    
    NSLog(@"got URL");
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:self.imgURL resultBlock:^(ALAsset *asset)
     {
         
         //                  CLLocationCoordinate2D coord = kSanFranciscoCoordinate;
         //                  CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
         
         CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
         NSLog(@"got location %f, %f", location.coordinate.latitude, location.coordinate.longitude);
         CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
         
         
         
         [geocoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray *placemarks, NSError *error) {
                            NSLog(@"reverseGeocodeLocation:completionHandler: Completion Handler called!");
                            
                            if (error){
                                NSLog(@"Geocode failed with error: %@", error);
                                [self displayError:error];
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
                            
                            self.city = placemark.locality;
                            
                        }];
         
     }
            failureBlock:^(NSError *error)
     {
         // error handling
         NSLog(@"failure-----");
     }];
    
    return self.city;
    
}

// display a given NSError in an UIAlertView
- (void)displayError:(NSError*)error
{
    //    dispatch_async(dispatch_get_main_queue(),^ {
    //        [self lockUI:NO];
    
    NSString *message;
    switch ([error code])
    {
        case kCLErrorGeocodeFoundNoResult: message = @"kCLErrorGeocodeFoundNoResult";
            break;
        case kCLErrorGeocodeCanceled: message = @"kCLErrorGeocodeCanceled";
            break;
        case kCLErrorGeocodeFoundPartialResult: message = @"kCLErrorGeocodeFoundNoResult";
            break;
        default: message = [error description];
            break;
    }
    
    UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"An error occurred."
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];;
    [alert show];
    //  });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
