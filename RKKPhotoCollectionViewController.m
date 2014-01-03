//
//  RKKPhotoCollectionViewController.m
//  Retriev
//
//  Created by Rohit Kharat on 11/25/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "RKKPhotoCollectionViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Social/Social.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "playVideo.h"


@interface RKKPhotoCollectionViewController () <UIAlertViewDelegate>

{
    NSMutableArray *selectedRets;
    NSMutableArray *collageSelect;
    BOOL stop;
    BOOL disp;
    UIAlertView *movieDoneAlert;
    
}

@end


@implementation RKKPhotoCollectionViewController

@synthesize photosArray;
@synthesize photoURLArray;
@synthesize pathy;

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
    
    //initialize photos array here
    
    self.collView.allowsMultipleSelection = YES;
    
    //selectedRets = [NSMutableArray array];
    self.photosArray = [[NSMutableArray alloc]init];
    selectedRets = [[NSMutableArray alloc] init];
    collageSelect = [[NSMutableArray alloc] init ];
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    return self.photoURLArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
    //code to get image from url
    NSURL *imageURL = [NSURL URLWithString:[self.photoURLArray objectAtIndex:indexPath.row]];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:imageURL resultBlock:^(ALAsset *asset)
     {
         if (asset)
         {
             UIImage  *copyOfOriginalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage] scale:0.5 orientation:UIImageOrientationUp];
             
             imageView.image = copyOfOriginalImage;
             [self.photosArray addObject:copyOfOriginalImage];
         }
         else
             NSLog(@"no asset");
     }
            failureBlock:^(NSError *error)
     {
         // error handling
         NSLog(@"failure-----");
     }];
    
    
    //recipeImageView.image = [UIImage imageNamed:[self.photosArray objectAtIndex:indexPath.row]];
    
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grey.png"]];
    
    
    return cell;
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *footerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        
        reusableview = footerview;
    }
    
    return reusableview;
}


- (IBAction)share:(id)sender {
    
    
    // Post selected photos to Facebook
    if ([selectedRets count] > 0) {
        // if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        [controller setInitialText:@"Check out the photos!"];
        for (UIImage *retPhoto in selectedRets) {
            [controller addImage:retPhoto];
        }
        
        [self presentViewController:controller animated:YES completion:Nil];
        
        // Deselect all selected items
        for(NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        
        // Remove all items from selectedRecipes array
        [selectedRets removeAllObjects];
    }
    // }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Photos Selected" message:@"Please select some photos to be shared" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
        [alert show];
    }
    
}

- (IBAction)collagey:(id)sender {
    
    [self collage];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.movieURL = info[UIImagePickerControllerMediaURL];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (BOOL)collage
{
    
    if ([selectedRets count] < 4) {
        
        if ([selectedRets count] > 0){
            
            for (NSString *obj in collageSelect){
                NSLog(@"From ArrayTag obj: %@", obj);
            }
            stop = [self createVideo];
        }
        
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Photos Selected" message:@"Please select some Photos to make a collage" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
            [alert show];
            stop = FALSE;
        }
        
        
    }
    // }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Limit Exceeded" message:@"You can select only 3 photos" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:Nil, nil];
        [alert show];
        stop = FALSE;
        
    }
    
    return stop;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    // NSString *selectedRet = [retImages [indexPath.section] objectAtIndex:indexPath.row];
    UIImage *selectedRet=    [self.photosArray objectAtIndex:indexPath.row];
    NSURL *imagelink = [self.photoURLArray objectAtIndex:indexPath.row];
    // Add the selected item into the array
    
    [selectedRets addObject:selectedRet];
    [collageSelect addObject:imagelink];
    NSLog(@"select");
    // NSLog(@"inserted %@ at index %d", selectedRet, indexPath.row);
    //NSLog(@"%@", selectedRets);
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    UIImage *deSelectedRet =[self.photosArray objectAtIndex:indexPath.row];
    NSURL *deimagelink = [self.photoURLArray objectAtIndex:indexPath.row];
    
    [selectedRets removeObject:deSelectedRet];
    [collageSelect removeObject:deimagelink];
    NSLog(@"deselect");
    //NSLog(@"%@", selectedRets);
}

//- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
//{
//    return NO;
//
//}


-(IBAction)selectPhotos:(id)sender
{
    NSLog(@"select button clicked");
    //create collectionView property, link with storyboard, copy code from retPhotos
    self.collectionView.allowsMultipleSelection = TRUE;
    
}


-(BOOL)createVideo
{
    self.didCreateVideo = FALSE;
    NSLog(@"create VIDEO!");
    
    NSError *error = nil;
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh-mm"];
    NSString *resultString = [dateFormatter stringFromDate: currentTime];
    NSLog(@"time: %@",resultString);
    NSArray       *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSLog(@"paths array count = %d", paths.count);
    NSString  *documentsDirectory = [paths objectAtIndex:0];
    self.filePath = [NSString stringWithFormat:@"%@/%@.mov", documentsDirectory,resultString];
    NSLog(@"filePath = %@", self.filePath);
    
    
    
    UIImage *imj = [selectedRets objectAtIndex:0];
    CGSize frameSize = imj.size;
    
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:self.filePath] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    
    
    
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   
                                   [NSNumber numberWithInt:640], AVVideoWidthKey,
                                   
                                   [NSNumber numberWithInt:960], AVVideoHeightKey,
                                   
                                   nil];
    
    AVAssetWriterInput* videoStream = [AVAssetWriterInput
                                       assetWriterInputWithMediaType:AVMediaTypeVideo
                                       outputSettings:videoSettings] ;
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput: videoStream
                                                     
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoStream);
    NSParameterAssert([videoWriter canAddInput:videoStream]);
    videoStream.expectsMediaDataInRealTime = YES;
    
    [videoWriter addInput:videoStream];
    [videoWriter startWriting];
    
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    int frameCount = 0;
    NSLog(@"no. of images being added to buffer: %d", selectedRets.count);
    
    for(UIImage *img in selectedRets)
    {
        //without maintaining aspect ratio
        buffer = [self pixelBufferFromCGImage:[[self imageWithImage:img scaledToSize:CGSizeMake(160, 280)] CGImage] andSize:img.size];
        
        //      maintain aspect ratio
        //        buffer = [self pixelBufferFromCGImage:[[self imageWithImage:img scaledToWidth:320.0f] CGImage] andSize:img.size];
        
        //CVPixelBufferRef buffer = [self pixelBufferFromCGImage:img.CGImage];
        
        BOOL append_ok = NO;
        
        while (!append_ok){
            if (adaptor.assetWriterInput.readyForMoreMediaData){
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) 1);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                if(buffer)
                    [NSThread sleepForTimeInterval:0.5];
            }else{
                [NSThread sleepForTimeInterval:1];
            }
        }
        frameCount++;
    }
    
    [videoStream markAsFinished];
    [videoWriter finishWriting];
    
    //this is not being called for some reason so check why
    //[self saveMovieToCameraRoll];
    
    // [self CompileFilesToMakeMovie];
    
    NSString *openCommand = [NSString stringWithFormat:@"/usr/bin/open \"%@\"", NSTemporaryDirectory()];
    system([openCommand fileSystemRepresentation]);
    
    self.didCreateVideo = TRUE;
    
    UISaveVideoAtPathToSavedPhotosAlbum (self.filePath,self, @selector(video:didFinishSavingWithError: contextInfo:), nil);
    
    return self.didCreateVideo;
    
}

- (void) openPhotoGallery
{
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    
    [self presentViewController:picker animated:YES completion:NULL];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (alertView == movieDoneAlert) {
        [self openPhotoGallery];
    }
}


- (void)video:(NSString *) videoPath didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
    if (error) {
        NSLog(@"Finished saving video with error: %@", error);
        self.didCreateVideo = FALSE;
    }
    movieDoneAlert = [[UIAlertView alloc]initWithTitle:@"Done"
                                               message:@"Movie succesfully exported."
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil, nil];
    [movieDoneAlert show];
    //stop = NO;
}


-(CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    //    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, 640,
    //                                          960, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,&pxbuffer);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          self.view.frame.size.width,
                                          self.view.frame.size.height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    //    CGContextRef context = CGBitmapContextCreate(pxdata, 640,
    //                                                 960, 8, 4*640, rgbColorSpace,
    //                                                 kCGImageAlphaNoneSkipFirst);
    CGContextRef context = CGBitmapContextCreate(pxdata, self.view.frame.size.width,
                                                 self.view.frame.size.height, 8, 4*self.view.frame.size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
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

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

//code to save to photo library of the iPhone
//- (void)saveMovieToCameraRoll
//{
//    NSLog(@"saveMovieToCameraRoll");
//    // save the movie to the camera roll
//	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//	//NSLog(@"writing \"%@\" to photos album", outputURL);
//	[library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:self.filePath]
//								completionBlock:^(NSURL *assetURL, NSError *error) {
//									if (error) {
//										NSLog(@"assets library failed (%@)", error);
//									}
//									else {
//										[[NSFileManager defaultManager] removeItemAtURL:[NSURL URLWithString:self.filePath] error:&error];
//										if (error)
//											NSLog(@"Couldn't remove temporary movie file \"%@\"", self.filePath);
//									}
//									self.filePath = nil;
//								}];
//}





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    
    return [self collage];
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"passVideo"]) {
        //[self createVideo];
        //NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        playVideo *destViewController = segue.destinationViewController;
        destViewController.movieURL = [NSURL URLWithString:self.filePath];
        NSLog(@"%@",destViewController.movieURL);
    }
}

@end
