//
//  RKKSecondViewController.m
//  Detrievo
//
//  Created by rkharat on 11/8/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "RKKSecondViewController.h"
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

#define kSanFranciscoCoordinate CLLocationCoordinate2DMake(37.776278, -122.419367)


static sqlite3 *database = nil;
static sqlite3_stmt *statement = nil;
//float scale_width = 0.0;
//float scale_height = 0.0;


@interface RKKSecondViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate,ABPeoplePickerNavigationControllerDelegate, ABPersonViewControllerDelegate>

@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSMutableArray *contactsArray;


@end

@implementation RKKSecondViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    taggedMyself = FALSE;
    [self createDB];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self showPhotoLibrary:nil];
    
}

-(IBAction)showPhotoLibrary:(id)sender
{
    self.imagePicker = [[UIImagePickerController alloc]init];
    self.imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.delegate = self;
    
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    
    taggedMyself = FALSE;
    
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
    self.originalImage = [self imageWithImage:selectedImage scaledToSize:CGSizeMake(300, 280)];
    
    NSLog(@"self.originalImage scaled down to size = %f X %f", self.originalImage.size.width, self.originalImage.size.height);
    
    self.imgURLString = [info objectForKey:UIImagePickerControllerReferenceURL];
    self.imgURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    //print file name
    NSLog(@"image url is %@", self.imgURLString);
    
    
    //------------------------
    self.imageView = [[UIImageView alloc] initWithImage:self.originalImage];
    self.imageView.frame = CGRectMake(10.0f, 40.0f, self.originalImage.size.width, self.originalImage.size.height);
    
    [self.view addSubview:self.imageView];
    NSLog(@"self.imageView size = %f X %f", self.imageView.frame.size.width, self.imageView.frame.size.height);
    
    //    self.selectedImage = [[CIImage alloc] initWithImage:self.originalImage] ;
    self.selectedImage = [CIImage imageWithCGImage:[self imageWithImage:self.originalImage scaledToSize:CGSizeMake(150, 140)].CGImage];
    NSLog(@"CIImage size = %f X %f", self.selectedImage.extent.size.width, self.selectedImage.extent.size.height);
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
    
    //NSArray *features = [detector featuresInImage:self.selectedImage];
    self.facesArray = [[NSMutableArray alloc]init];
    self.facesArray = [NSMutableArray arrayWithArray:[detector featuresInImage:self.selectedImage]];
    
    [self performSelectorInBackground:@selector(detectFaces:) withObject:self.facesArray];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

-(void)detectFaces: (NSMutableArray *)features
{
    //Container for the face attributes
    UIView* faceContainer = [[UIView alloc] initWithFrame:self.imageView.frame];
    
    // flip faceContainer on y-axis to match coordinate system used by core image
    [faceContainer setTransform:CGAffineTransformMakeScale(1, -1)];
    
    NSLog(@"number of faces: %d", self.facesArray.count);

    for (CIFaceFeature *faceFeature in self.facesArray)
    {
        // get the width of the face
        CGFloat faceWidth = faceFeature.bounds.size.width;
        
        // create a UIView using the bounds of the face
        UIView* faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        
        // add a border around the newly created UIView
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [[UIColor orangeColor] CGColor];
        
        // add the new view to create a box around the face
        [faceContainer addSubview:faceView];
    }
    
    [self.view addSubview:faceContainer];

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
    
    faceBounds.origin.y = self.originalImage.size.height-faceFeature.bounds.size.height-faceFeature.bounds.origin.y + 40.0f;
    faceBounds.origin.x += 10.0f;

    
    if (CGRectContainsPoint(faceBounds, touchPoint))
    {
       // NSLog(@"oh yeah!");
        if (!taggedMyself)
        {
            //Ask user whether he wants to tag himself or another person
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Who do you want to Tag?"
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:@"Myself"
                                                            otherButtonTitles:@"Another Person",nil];
            
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
    else if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        NSLog(@"cancel button");
        
    }
    else [self displayContacts];
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
    RKKSecondViewController * __weak weakSelf = self;
    
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
               //  NSString *insertMappingSQL = [NSString stringWithFormat:@"INSERT INTO MAPPINGS (PERSONID, IMG_URL) VALUES (\"%d\",\"%@\")", recordID, self.imgURL];
                
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
                            
//                            if (error){
//                                NSLog(@"Geocode failed with error: %@", error);
//                                [self displayError:error];
//                                self.city = @"";
//                                
//                            }
                            
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
