//
//  FullScreenPhotoController.h
//  Klink V2
//
//  Created by Jordan Gurrieri on 7/13/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "Theme.h"
#import "Caption.h"
#import "User.h"

#define kThumbnailWidthPortrait 66.67
#define kThumbnailHeightPortrait 100
#define kThumbnailWidthLandscape 150
#define kThumbnailHeightLandscape 100


@interface FullScreenPhotoController : UIViewController
        <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UIImageView *imageView;
    UILabel *submittedByLabel;
    UILabel *captionLabel;
    Photo *photo;
    Theme *theme;
    Caption *caption;
    User *user;
}
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UILabel *submittedByLabel;
@property (nonatomic, retain) IBOutlet UILabel *captionLabel;
@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) Theme *theme;
@property (nonatomic, retain) Caption *caption;
@property (nonatomic, retain) User *user;

@end