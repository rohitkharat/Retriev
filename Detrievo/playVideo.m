//
//  playVideo.m
//  Retriev
//
//  Created by aghurye on 12/9/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import "playVideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "RKKPhotoCollectionViewController.h"


@interface playVideo ()

@end

@implementation playVideo

@synthesize movieURL;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    NSLog(@"%@",self.movieURL);
    
    self.movieController = [[MPMoviePlayerController alloc] init];
    
    
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake (0, 0, 320, 476)];
    [self.view addSubview:self.movieController.view];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.movieController];
    
    [self.movieController play];
    
}

- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    NSLog(@"didfinishplayngvideo");
    [self.movieController stop];
    [self.movieController.view removeFromSuperview];
    self.movieController = nil;
    
}


@end
