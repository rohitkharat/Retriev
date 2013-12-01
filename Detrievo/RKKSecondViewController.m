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

static sqlite3 *database = nil;
static sqlite3_stmt *statement = nil;

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

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

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
               // NSString *insertMappingSQL = [NSString stringWithFormat:@"INSERT INTO MAPPINGS (PERSONID, IMG_URL, CITY) VALUES (\"%d\",\"%@\" ,\"%@\")", recordID, self.imgURLString, [self getPhotoLocation]];
                
                //without city
                 NSString *insertMappingSQL = [NSString stringWithFormat:@"INSERT INTO MAPPINGS (PERSONID, IMG_URL) VALUES (\"%d\",\"%@\")", recordID, self.imgURL];
                
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
    //make sure city is getting inserted
    //work on city search display controller
    //check if code takes both search criteria if city and name is selected
    
    NSLog(@"got URL");
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:self.imgURL resultBlock:^(ALAsset *asset)
     {
         CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
         NSLog(@"got location");
         CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
         [geocoder reverseGeocodeLocation:location
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//---------------------------------------------------------------------------------------------------------------------------------
/*

- (CGPoint) leftEyePositionForImage:(UIImage *)image{
    return [self pointForImage:image fromPoint:self.leftEyePosition];
}

- (CGPoint) rightEyePositionForImage:(UIImage *)image{
    return [self pointForImage:image fromPoint:self.rightEyePosition];
}

- (CGPoint) mouthPositionForImage:(UIImage *)image{
    return [self pointForImage:image fromPoint:self.mouthPosition];
}

- (CGRect) boundsForImage:(UIImage *)image{
    return [self boundsForImage:image fromBounds:self.bounds];
}


- (CGPoint) normalizedLeftEyePositionForImage:(UIImage *)image{
    return [self normalizedPointForImage:image fromPoint:self.leftEyePosition];
}

- (CGPoint) normalizedRightEyePositionForImage:(UIImage *)image{
    return [self normalizedPointForImage:image fromPoint:self.rightEyePosition];
}

- (CGPoint) normalizedMouthPositionForImage:(UIImage *)image{
    return [self normalizedPointForImage:image fromPoint:self.mouthPosition];
}

- (CGRect) normalizedBoundsForImage:(UIImage *)image{
    return [self normalizedBoundsForImage:image fromBounds:self.bounds];
}


- (CGPoint) leftEyePositionForImage:(UIImage *)image inView:(CGSize)viewSize{
    CGPoint normalizedPoint = [self normalizedLeftEyePositionForImage:image];
    return [self pointInView:viewSize fromNormalizedPoint:normalizedPoint];
}

- (CGPoint) rightEyePositionForImage:(UIImage *)image inView:(CGSize)viewSize{
    CGPoint normalizedPoint = [self normalizedRightEyePositionForImage:image];
    return [self pointInView:viewSize fromNormalizedPoint:normalizedPoint];
}

- (CGPoint) mouthPositionForImage:(UIImage *)image inView:(CGSize)viewSize{
    CGPoint normalizedPoint = [self normalizedMouthPositionForImage:image];
    return [self pointInView:viewSize fromNormalizedPoint:normalizedPoint];
}

- (CGRect) boundsForImage:(UIImage *)image inView:(CGSize)viewSize{
    CGRect normalizedBounds = [self normalizedBoundsForImage:image fromBounds:self.bounds];
    return [self boundsInView:viewSize fromNormalizedBounds:normalizedBounds];
}


- (CGPoint) pointForImage:(UIImage*) image fromPoint:(CGPoint) originalPoint {
    
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    
    CGPoint convertedPoint;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
            convertedPoint.x = originalPoint.x;
            convertedPoint.y = imageHeight - originalPoint.y;
            break;
        case UIImageOrientationDown:
            convertedPoint.x = imageWidth - originalPoint.x;
            convertedPoint.y = originalPoint.y;
            break;
        case UIImageOrientationLeft:
            convertedPoint.x = imageWidth - originalPoint.y;
            convertedPoint.y = imageHeight - originalPoint.x;
            break;
        case UIImageOrientationRight:
            convertedPoint.x = originalPoint.y;
            convertedPoint.y = originalPoint.x;
            break;
        case UIImageOrientationUpMirrored:
            convertedPoint.x = imageWidth - originalPoint.x;
            convertedPoint.y = imageHeight - originalPoint.y;
            break;
        case UIImageOrientationDownMirrored:
            convertedPoint.x = originalPoint.x;
            convertedPoint.y = originalPoint.y;
            break;
        case UIImageOrientationLeftMirrored:
            convertedPoint.x = imageWidth - originalPoint.y;
            convertedPoint.y = originalPoint.x;
            break;
        case UIImageOrientationRightMirrored:
            convertedPoint.x = originalPoint.y;
            convertedPoint.y = imageHeight - originalPoint.x;
            break;
        default:
            break;
    }
    return convertedPoint;
}

- (CGPoint) normalizedPointForImage:(UIImage*) image fromPoint:(CGPoint) originalPoint {
    
    CGPoint normalizedPoint = [self pointForImage:image fromPoint:originalPoint];
    
    normalizedPoint.x /= image.size.width;
    normalizedPoint.y /= image.size.height;
    
    return normalizedPoint;
}

- (CGPoint) pointInView:(CGSize) viewSize fromNormalizedPoint:(CGPoint) normalizedPoint{
    return CGPointMake(normalizedPoint.x * viewSize.width, normalizedPoint.y * viewSize.height);
}

- (CGSize) sizeForImage:(UIImage *) image fromSize:(CGSize) originalSize{
    CGSize convertedSize;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            convertedSize.width = originalSize.width;
            convertedSize.height = originalSize.height;
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            convertedSize.width = originalSize.height;
            convertedSize.height = originalSize.width;
            break;
        default:
            break;
    }
    return convertedSize;
}

- (CGSize) normalizedSizeForImage:(UIImage *) image fromSize:(CGSize) originalSize{
    CGSize normalizedSize = [self sizeForImage:image fromSize:originalSize];
    normalizedSize.width /= image.size.width;
    normalizedSize.height /= image.size.height;
    
    return normalizedSize;
}

- (CGSize) sizeInView:(CGSize) viewSize fromNormalizedSize:(CGSize) normalizedSize{
    return CGSizeMake(normalizedSize.width * viewSize.width, normalizedSize.height * viewSize.height);
}

- (CGRect) boundsForImage:(UIImage *) image fromBounds:(CGRect) originalBounds{
    
    CGPoint convertedOrigin = [self pointForImage:image fromPoint:originalBounds.origin];;
    CGSize convertedSize = [self sizeForImage:image fromSize:originalBounds.size];
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
            convertedOrigin.y -= convertedSize.height;
            break;
        case UIImageOrientationDown:
            convertedOrigin.x -= convertedSize.width;
            break;
        case UIImageOrientationLeft:
            convertedOrigin.x -= convertedSize.width;
            convertedOrigin.y -= convertedSize.height;
        case UIImageOrientationRight:
            break;
        case UIImageOrientationUpMirrored:
            convertedOrigin.y -= convertedSize.height;
            convertedOrigin.x -= convertedSize.width;
            break;
        case UIImageOrientationDownMirrored:
            break;
        case UIImageOrientationLeftMirrored:
            convertedOrigin.x -= convertedSize.width;
            convertedOrigin.y += convertedSize.height;
        case UIImageOrientationRightMirrored:
            convertedOrigin.y -= convertedSize.height;
            break;
        default:
            break;
    }
    
    return CGRectMake(convertedOrigin.x, convertedOrigin.y,
                      convertedSize.width, convertedSize.height);
}

- (CGRect) normalizedBoundsForImage:(UIImage *) image fromBounds:(CGRect) originalBounds{
    
    CGRect normalizedBounds = [self boundsForImage:image fromBounds:originalBounds];
    normalizedBounds.origin.x /= image.size.width;
    normalizedBounds.origin.y /= image.size.height;
    normalizedBounds.size.width /= image.size.width;
    normalizedBounds.size.height /= image.size.height;
    
    return normalizedBounds;
}

- (CGRect) boundsInView:(CGSize) viewSize fromNormalizedBounds:(CGRect) normalizedBounds{
    return CGRectMake(normalizedBounds.origin.x * viewSize.width,
                      normalizedBounds.origin.y * viewSize.height,
                      normalizedBounds.size.width * viewSize.width,
                      normalizedBounds.size.height * viewSize.height);
}
*/

//---------------------------------------------------------------------------------------------------------------------------------

@end
