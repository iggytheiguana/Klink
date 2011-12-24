//
//  UIEditorialPageView.m
//  Platform
//
//  Created by Jordan Gurrieri on 12/15/11.
//  Copyright (c) 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "UIEditorialPageView.h"
#import "Page.h"
#import "Photo.h"
#import "Caption.h"
#import "Types.h"
#import "Attributes.h"
#import "FeedManager.h"
#import "ImageManager.h"
#import "CallbackResult.h"
#import "ImageDownloadResponse.h"
#import "Macros.h"
#import "UIImageView+UIImageViewCategory.h"

#define kPHOTOID                    @"photoid"
#define kPHOTOFRAMETHICKNESS        30

@implementation UIEditorialPageView
@synthesize pageID = m_pageID;
@synthesize photoID = m_photoID;
@synthesize captionID = m_captionID;
@synthesize view = m_view;
@synthesize lbl_draftTitle = m_lbl_draftTitle;
@synthesize iv_photo = m_iv_photo;
@synthesize iv_photoFrame = m_iv_photoFrame;
@synthesize lbl_caption = m_lbl_caption;
@synthesize lbl_photoby = m_lbl_photoby;
@synthesize lbl_captionby = m_lbl_captionby;


#pragma mark - Instance Methods
- (void)render {
    ResourceContext* resourceContext = [ResourceContext instance];
    
    Page* draft = (Page*)[resourceContext resourceWithType:PAGE withID:self.pageID];
    self.lbl_draftTitle.text = draft.displayname;
    
    Photo* photo = draft.photoWithHighestVotes;
    self.photoID = photo.objectid;
    
    if (photo != nil) {        
        ImageManager* imageManager = [ImageManager instance];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:photo.objectid forKey:kPHOTOID];
        
        if (photo.imageurl != nil && ![photo.imageurl isEqualToString:@""]) {
            Callback* callback = [[Callback alloc]initWithTarget:self withSelector:@selector(onImageDownloadComplete:) withContext:userInfo];
            UIImage* image = [imageManager downloadImage:photo.imageurl withUserInfo:nil atCallback:callback];
            [callback release];
            if (image != nil) {
                self.iv_photo.contentMode = UIViewContentModeScaleAspectFit;
                self.iv_photo.image = image;
                
                // get the frame for the new scaled image in the Photo ImageView
                CGRect scaledImage = [self.iv_photo frameForImage:image inImageViewAspectFit:self.iv_photo];
                
                // create insets to cap the photo frame according to the size of the scaled image
                UIEdgeInsets photoFrameInsets = UIEdgeInsetsMake(scaledImage.size.height/2 + kPHOTOFRAMETHICKNESS, scaledImage.size.width/2 + kPHOTOFRAMETHICKNESS, scaledImage.size.height/2 + kPHOTOFRAMETHICKNESS, scaledImage.size.width/2 + kPHOTOFRAMETHICKNESS);
                
                // apply the cap insets to the photo frame image
                UIImage* img_photoFrame = [UIImage imageNamed:@"picture_frame.png"];
                
                if ([UIImage instancesRespondToSelector:@selector(resizableImageWithCapInsets:)]) {
                    // This method is only available in iOS 5
                    self.iv_photoFrame.image = [img_photoFrame resizableImageWithCapInsets:photoFrameInsets];
                    
                    // resize the photo frame to wrap the scaled image while maintining the cap insets, this preserves the border thickness and shadows of the photo frame
                    self.iv_photoFrame.frame = CGRectMake((self.iv_photo.frame.origin.x + scaledImage.origin.x - kPHOTOFRAMETHICKNESS), (self.iv_photo.frame.origin.y + scaledImage.origin.y - kPHOTOFRAMETHICKNESS + 2), (scaledImage.size.width + 2*kPHOTOFRAMETHICKNESS), (scaledImage.size.height + 2*kPHOTOFRAMETHICKNESS - 2));
                } else {
                    // Fallback for iOS 4.x
                    self.iv_photoFrame.image = [img_photoFrame stretchableImageWithLeftCapWidth:(int)photoFrameInsets.left topCapHeight:(int)photoFrameInsets.top];
                    
                    // resize the photo frame to wrap the scaled image while maintining the cap insets, this preserves the border thickness and shadows of the photo frame
                    self.iv_photoFrame.frame = CGRectMake((self.iv_photo.frame.origin.x + scaledImage.origin.x - kPHOTOFRAMETHICKNESS/2), (self.iv_photo.frame.origin.y + scaledImage.origin.y - kPHOTOFRAMETHICKNESS + 2), (scaledImage.size.width + kPHOTOFRAMETHICKNESS), (scaledImage.size.height + 2*kPHOTOFRAMETHICKNESS - 2));
                }
            }
        }
        else {
            self.iv_photo.contentMode = UIViewContentModeCenter;
            self.iv_photo.image = [UIImage imageNamed:@"icon-pics2@2x.png"];
        }
    }
    
    // reset labels to defualt values
    self.lbl_caption.textColor = [UIColor darkGrayColor];
    self.lbl_caption.text = @"This photo had no captions.";
    
    Caption* topCaption = [photo captionWithHighestVotes];
    if (topCaption != nil) {
        self.captionID = topCaption.objectid;
        self.lbl_caption.textColor = [UIColor blackColor];
        self.lbl_caption.text = [NSString stringWithFormat:@"\"%@\"", topCaption.caption1];
    }
    
    self.lbl_captionby.text = [NSString stringWithFormat:@"- written by %@", photo.creatorname];
    self.lbl_photoby.text = [NSString stringWithFormat:@"- illustrated by %@", photo.creatorname];
    
    [self setNeedsDisplay];
}

- (void)renderWithPageID:(NSNumber*)pageID {
    self.pageID = pageID;
    
    [self render];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code 
        NSArray* topLevelObjs = nil;
        
        topLevelObjs = [[NSBundle mainBundle] loadNibNamed:@"UIEditorialPageView" owner:self options:nil];
        if (topLevelObjs == nil)
        {
            NSLog(@"Error! Could not load UIEditorialPageView nib file..\n");
        }
        
        [self addSubview:self.view];
        
        [self.lbl_draftTitle setFont:[UIFont fontWithName:@"TravelingTypewriter" size:24]];
        [self.lbl_caption setFont:[UIFont fontWithName:@"TravelingTypewriter" size:15]];
        [self.lbl_captionby setFont:[UIFont fontWithName:@"TravelingTypewriter" size:14]];
        [self.lbl_photoby setFont:[UIFont fontWithName:@"TravelingTypewriter" size:14]];
        
    }
    return self;
}

/*- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code 
        NSArray* topLevelObjs = nil;
        
        topLevelObjs = [[NSBundle mainBundle] loadNibNamed:@"UIEditorialPageView" owner:self options:nil];
        if (topLevelObjs == nil)
        {
            NSLog(@"Error! Could not load UIEditorialPageView nib file..\n");
        }
        
        [self addSubview:self.view];
        
        [self.lbl_draftTitle setFont:[UIFont fontWithName:@"TravelingTypewriter" size:24]];
        [self.lbl_caption setFont:[UIFont fontWithName:@"TravelingTypewriter" size:15]];
        [self.lbl_captionby setFont:[UIFont fontWithName:@"TravelingTypewriter" size:14]];
        [self.lbl_photoby setFont:[UIFont fontWithName:@"TravelingTypewriter" size:14]];
        
    }
    return self;
}*/

- (void)dealloc
{
    self.pageID = nil;
    self.photoID = nil;
    self.captionID = nil;
    self.view = nil;
    self.lbl_draftTitle = nil;
    self.iv_photo = nil;
    self.iv_photoFrame = nil;
    self.lbl_caption = nil;
    self.lbl_captionby = nil;
    self.lbl_photoby = nil;
    [super dealloc];
    
}

#pragma mark - Async callbacks
- (void)onImageDownloadComplete:(CallbackResult*)result {
    NSString* activityName = @"UIEditorialPageView.onImageDownloadComplete:";
    NSDictionary* userInfo = result.context;
    NSNumber* photoID = [userInfo valueForKey:kPHOTOID];
    ImageDownloadResponse* response = (ImageDownloadResponse*)result.response;
    
    if ([response.didSucceed boolValue] == YES) {
        if ([photoID isEqualToNumber:self.photoID]) {
            //we only draw the image if this view hasnt been repurposed for another photo
            LOG_IMAGE(0,@"%@settings UIImage object equal to downloaded response",activityName);
            [self.iv_photo performSelectorOnMainThread:@selector(setImage:) withObject:response.image waitUntilDone:NO];
            self.iv_photo.contentMode = UIViewContentModeScaleAspectFit;
            [self setNeedsDisplay];
        }
    }
    else {
        self.iv_photo.backgroundColor = [UIColor redColor];
        LOG_IMAGE(1,@"%@Image failed to download",activityName);
    }
    
}

@end