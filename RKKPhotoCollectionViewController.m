//
//  RKKPhotoCollectionViewController.m
//  Retriev
//
//  Created by Rohit Kharat on 11/25/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "RKKPhotoCollectionViewController.h"
#import "RKKRetrievedPhoto.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Social/Social.h>


@interface RKKPhotoCollectionViewController ()

{
    NSMutableArray *selectedRets;

}

@end


@implementation RKKPhotoCollectionViewController

@synthesize photosArray;
@synthesize photoURLArray;

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
    
    selectedRets = [NSMutableArray array];
    //self.photosArray = [[NSMutableArray alloc]init];

    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photosArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
    
    imageView.image = [self.photosArray objectAtIndex:indexPath.row];
    
    //recipeImageView.image = [UIImage imageNamed:[self.photosArray objectAtIndex:indexPath.row]];
    
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo-frame.png"]];

    
    return cell;
    
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
    }
    // }
    
    // Deselect all selected items
    for(NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    
    // Remove all items from selectedRecipes array
    [self.photosArray removeAllObjects];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    //   NSLog(@"hi ddude : %d  %d",indexPath.section,indexPath.row);
    //   NSLog(@" %@",[retImages objectAtIndex:indexPath.row]);
    
    // Determine the selected items by using the indexPath
    
    // NSString *selectedRet = [retImages [indexPath.section] objectAtIndex:indexPath.row];
    UIImage *selectedRet=    [self.photosArray objectAtIndex:indexPath.row];
    // Add the selected item into the array
    
    [selectedRets addObject:selectedRet];
    NSLog(@"select");
    // NSLog(@"inserted %@ at index %d", selectedRet, indexPath.row);
    //NSLog(@"%@", selectedRets);
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    UIImage *deSelectedRet =[self.photosArray objectAtIndex:indexPath.row];
    
    [selectedRets removeObject:deSelectedRet];
    NSLog(@"deselect");
    //NSLog(@"%@", selectedRets);
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    return NO;
    
}


-(IBAction)selectPhotos:(id)sender
{
    NSLog(@"select button clicked");
    //create collectionView property, link with storyboard, copy code from retPhotos
    self.collectionView.allowsMultipleSelection = TRUE;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
