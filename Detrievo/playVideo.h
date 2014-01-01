//
//  playVideo.h
//  Retriev
//
//  Created by aghurye on 12/9/13.
//  Copyright (c) 2013 rkharat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>


@interface playVideo : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (copy,   nonatomic) NSURL *movieURL;
@property (strong, nonatomic) MPMoviePlayerController *movieController;

@end
