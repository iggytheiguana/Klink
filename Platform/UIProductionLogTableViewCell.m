//
//  UIProductionLogTableViewCell.m
//  Platform
//
//  Created by Jordan Gurrieri on 11/17/11.
//  Copyright (c) 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "UIProductionLogTableViewCell.h"
#import "Page.h"
#import "Photo.h"
#import "ImageManager.h"
#import "ImageDownloadResponse.h"
#import "CallbackResult.h"
#import "Types.h"
#import "Macros.h"
#import "DateTimeHelper.h"

#define kPAGEID @"pageid"
#define kPHOTOID @"photoid"

@implementation UIProductionLogTableViewCell
@synthesize pageID                      = m_pageID;
@synthesize productionLogTableViewCell  = m_productionLogTableViewCell;
@synthesize iv_photo                    = m_iv_photo;
@synthesize lbl_draftTitle              = m_lbl_draftTitle;
@synthesize lbl_deadline                = m_lbl_deadline;
//@synthesize lbl_numPhotos               = m_lbl_numPhotos;
@synthesize lbl_numCaptions             = m_lbl_numCaptions;
@synthesize iv_captionIcon              = m_iv_captionIcon;
@synthesize btn_unreadCaptionsBadge     = m_btn_unreadCaptionsBadge;
@synthesize topVotedPhotoID             = m_topVotedPhotoID;
@synthesize topVotedCaptionID           = m_topVotedCaptionID;
@synthesize deadline                    = m_deadline;
@synthesize deadlineTimer               = m_deadlineTimer;
@synthesize eventManager                = __eventManager;


#pragma mark - Properties
- (EventManager*) eventManager {
    if (__eventManager != nil) {
        return __eventManager;
    }
    __eventManager = [EventManager instance];
    return __eventManager;
}

#pragma mark - Deadline Date Timer
- (void) timeRemaining:(NSTimer *)timer {
    NSDate* now = [NSDate date];
    NSTimeInterval remaining = [self.deadline timeIntervalSinceDate:now];
    self.lbl_deadline.text = [NSString stringWithFormat:@"deadline: %@", [DateTimeHelper formatTimeInterval:remaining]];
    [self setNeedsDisplay];
}


#pragma mark - Instance Methods
//- (NSFetchedResultsController*) new_frc_photo {
//    NSString* activityName = @"UIProductionLogTableViewCell.new_frc_photo:";
//    
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    ResourceContext* resourceContext = [ResourceContext instance];
//    
//    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:PHOTO inManagedObjectContext:resourceContext.managedObjectContext];
//    
//    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K=%d",THEMEID, self.pageID];
//    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NUMBEROFVOTES ascending:NO];
//    
//    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
//    [fetchRequest setPredicate:predicate];
//    [fetchRequest setEntity:entityDescription];
//    [fetchRequest setFetchBatchSize:20];
//    
//    NSFetchedResultsController* controller = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:resourceContext.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
//    
//    controller.delegate = self;
//       
//    
//    NSError* error = nil;
//    [controller performFetch:&error];
//  	if (error != nil)
//    {
//        LOG_UIPRODUCTIONLOGTABLEVIEWCELL(1, @"%@Could not create instance of NSFetchedResultsController due to %@",activityName,[error userInfo]);
//    }
//    
//  
//    [fetchRequest release];
//    
//    return controller;
//    
//}

- (void) dealloc {
    [self.deadlineTimer invalidate];
    
    self.productionLogTableViewCell = nil;
    self.iv_photo = nil;
    self.lbl_draftTitle = nil;
    self.lbl_deadline = nil;
    //self.lbl_numPhotos = nil;
    self.iv_captionIcon = nil;
    self.lbl_numCaptions = nil;
    self.btn_unreadCaptionsBadge = nil;
    
    [super dealloc];
}

- (void) renderUnreadCaptions {
    ResourceContext* resourceContext = [ResourceContext instance];
    Page* draft = (Page*)[resourceContext resourceWithType:PAGE withID:self.pageID];
    
    if (draft != nil) {
        // self.lbl_numPhotos.text = [draft.numberofphotos stringValue];
        //self.lbl_numCaptions.text = [draft.numberofcaptions stringValue];
        
        int newCaptions = [draft numberOfUnreadCaptions];
        
        if (newCaptions > 0) {
            if (newCaptions > 99) {
                // limit the label to "99"
                newCaptions = 99;
            }
            
            [self.btn_unreadCaptionsBadge setTitle:[NSString stringWithFormat:@"%d", newCaptions] forState:UIControlStateNormal];
            [self.btn_unreadCaptionsBadge setTitle:[NSString stringWithFormat:@"%d", newCaptions] forState:UIControlStateDisabled];
            
            [self.lbl_numCaptions setHidden:YES];
            [self.iv_captionIcon setHidden:YES];
            [self.btn_unreadCaptionsBadge setHidden:NO];
        }
        else {
            [self.lbl_numCaptions setHidden:NO];
            [self.iv_captionIcon setHidden:NO];
            [self.btn_unreadCaptionsBadge setHidden:YES];
        }
    }
}


- (void)updateCaptionCountLabels {
    ResourceContext* resourceContext = [ResourceContext instance];
    
    Page* draft = (Page*)[resourceContext resourceWithType:PAGE withID:self.pageID];
    
    if (draft != nil) {
        // self.lbl_numPhotos.text = [draft.numberofphotos stringValue];
        self.lbl_numCaptions.text = [draft.numberofcaptions stringValue];
        
        /*int newCaptions = [draft numberOfUnreadCaptions];
        
        if (newCaptions > 0) {
            if (newCaptions > 99) {
                // limit the label to "99"
                newCaptions = 99;
            }
            
            [self.btn_unreadCaptionsBadge setTitle:[NSString stringWithFormat:@"%d", newCaptions] forState:UIControlStateNormal];
            [self.btn_unreadCaptionsBadge setTitle:[NSString stringWithFormat:@"%d", newCaptions] forState:UIControlStateDisabled];
            
            [self.lbl_numCaptions setHidden:YES];
            [self.iv_captionIcon setHidden:YES];
            [self.btn_unreadCaptionsBadge setHidden:NO];
        }
        else {*/
            [self.lbl_numCaptions setHidden:NO];
            [self.iv_captionIcon setHidden:NO];
            [self.btn_unreadCaptionsBadge setHidden:YES];
        //}
    }
}

- (void) renderPhoto:(Photo*)photo {
    if (photo.thumbnailurl != nil && ![photo.thumbnailurl isEqualToString:@""]) {
        ImageManager* imageManager = [ImageManager instance];
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObject:self.pageID forKey:kPAGEID];
        
        //add the photo id to the context
        [userInfo setValue:photo.objectid forKey:kPHOTOID];
        
        Callback* callback = [[Callback alloc]initWithTarget:self withSelector:@selector(onImageDownloadComplete:) withContext:userInfo];
        callback.fireOnMainThread = YES;
        
        UIImage* image = [imageManager downloadImage:photo.thumbnailurl withUserInfo:nil atCallback:callback];
        [callback release];
        
        if (image != nil) {
            self.iv_photo.contentMode = UIViewContentModeScaleAspectFit;
            self.iv_photo.image = image;
        }
    }
    else {
        self.iv_photo.contentMode = UIViewContentModeCenter;
        self.iv_photo.image = [UIImage imageNamed:@"icon-pics2-large.png"];
    }
    [self setNeedsDisplay];
}

- (void) renderPhoto {
    ResourceContext* resourceContext = [ResourceContext instance];
    Page* draft = (Page*)[resourceContext resourceWithType:PAGE withID:self.pageID];
    
    Photo* photo = [draft photoWithHighestVotes];
    self.topVotedPhotoID = photo.objectid;
    //[self renderPhoto:topPhoto];
    
    if (photo.thumbnailurl != nil && ![photo.thumbnailurl isEqualToString:@""]) {
        ImageManager* imageManager = [ImageManager instance];
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObject:self.pageID forKey:kPAGEID];
        
        //add the photo id to the context
        [userInfo setValue:photo.objectid forKey:kPHOTOID];
        
        Callback* callback = [[Callback alloc]initWithTarget:self withSelector:@selector(onImageDownloadComplete:) withContext:userInfo];
        callback.fireOnMainThread = YES;
        
        UIImage* image = [imageManager downloadImage:photo.thumbnailurl withUserInfo:nil atCallback:callback];
        [callback release];
        
        if (image != nil) {
            self.iv_photo.contentMode = UIViewContentModeScaleAspectFit;
            self.iv_photo.image = image;
        }
    }
    else {
        self.iv_photo.contentMode = UIViewContentModeCenter;
        self.iv_photo.image = [UIImage imageNamed:@"icon-pics2-large.png"];
    }
    
    [self setNeedsDisplay];
}

- (void) renderCaption {
    self.lbl_deadline.textColor = [UIColor darkGrayColor];
    self.lbl_deadline.text = @"This photo has no captions! Go ahead, add one...";
    
    ResourceContext* resourceContext = [ResourceContext instance];
    Page* draft = (Page*)[resourceContext resourceWithType:PAGE withID:self.pageID];
    
    Caption* caption = [draft captionWithHighestVotes];
    self.topVotedCaptionID = caption.objectid;
    
    if (caption.caption1 != nil && ![caption.caption1 isEqualToString:@""] && ![caption.caption1 isEqualToString:@" "]) {
        self.lbl_deadline.textColor = [UIColor blackColor];
        self.lbl_deadline.text = [NSString stringWithFormat:@"\"%@\"", caption.caption1];
    }
    
//    CGSize maximumSize = CGSizeMake(150, 1000);
//    UIFont* font = [UIFont fontWithName:@"AmericanTypewriter" size:13];
//    
//    CGSize messageSize = [caption.caption1 sizeWithFont:font constrainedToSize:maximumSize lineBreakMode:UILineBreakModeWordWrap];
//    
//    self.lbl_deadline.frame = CGRectMake(self.lbl_deadline.frame.origin.x, self.lbl_deadline.frame.origin.y, self.lbl_deadline.frame.size.width, messageSize.height);
    
    [self setNeedsDisplay];
}

- (void) render {
    ResourceContext* resourceContext = [ResourceContext instance];
    
    Page* draft = (Page*)[resourceContext resourceWithType:PAGE withID:self.pageID];
    
    if (draft != nil) {
       
        self.lbl_draftTitle.text =  draft.displayname;
       
        // Update caption count labels
       [self updateCaptionCountLabels];
        
        /*Photo* topPhoto = [draft photoWithHighestVotes];
        self.topVotedPhotoID = topPhoto.objectid;
        [self renderPhoto:topPhoto];*/
        
//        // Set deadline
//        self.deadline = [DateTimeHelper parseWebServiceDateDouble:draft.datedraftexpires];
//        self.deadlineTimer = [NSTimer scheduledTimerWithTimeInterval:60.0f
//                                         target:self
//                                       selector:@selector(timeRemaining:)
//                                       userInfo:nil
//                                        repeats:YES];
//        [self timeRemaining:self.deadlineTimer];
    
    }
    [self setNeedsDisplay];
}

- (void) renderDraftWithID:(NSNumber*)pageID {
    self.pageID = pageID;
    
    // reset defalts
    self.topVotedPhotoID = nil;
    self.deadline = nil;
    self.lbl_draftTitle.text = nil;
    //self.lbl_numPhotos.text = nil;
    self.lbl_numCaptions.text = nil;
    self.btn_unreadCaptionsBadge.titleLabel.text = nil;
    [self.btn_unreadCaptionsBadge setHidden:YES];
    self.lbl_deadline.text = nil;
    
    self.iv_photo.image = nil;
    self.iv_photo.contentMode = UIViewContentModeCenter;
    self.iv_photo.image = [UIImage imageNamed:@"icon-pics2-large.png"];
    
    [self.deadlineTimer invalidate];
    
    [self render];
}


#pragma mark - Initialization
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        NSArray* topLevelObjs = nil;
        
        topLevelObjs = [[NSBundle mainBundle] loadNibNamed:@"UIProductionLogTableViewCellNew" owner:self options:nil];
        self.topVotedPhotoID = nil;
        if (topLevelObjs == nil)
        {
            NSLog(@"Error! Could not load UIProductionLogTableViewCell file.\n");
        }
        
        [self.contentView addSubview:self.productionLogTableViewCell];
        
        // resister callbacks for newPhotoVote events incase the topPhoto changes
        Callback* newPhotoVoteCallback = [[Callback alloc]initWithTarget:self withSelector:@selector(onNewPhotoVote:)];
        newPhotoVoteCallback.fireOnMainThread = YES;
        [self.eventManager registerCallback:newPhotoVoteCallback forSystemEvent:kNEWPHOTOVOTE];
        
        [newPhotoVoteCallback release];
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


#pragma mark - Async callbacks
- (void)onImageDownloadComplete:(CallbackResult*)result {
    NSString* activityName = @"UIProductionLogTableViewCell.onImageDownloadComplete:";
    NSDictionary* userInfo = result.context;
    NSNumber* draftID = [userInfo valueForKey:kPAGEID];
    NSNumber* photoID = [userInfo valueForKey:kPHOTOID];
    
    ImageDownloadResponse* response = (ImageDownloadResponse*)result.response;
    
    if ([response.didSucceed boolValue] == YES) {
        if ([draftID isEqualToNumber:self.pageID] &&
            [photoID isEqualToNumber:self.topVotedPhotoID]) {
            
            //we only draw the image if this view hasnt been repurposed for another draft
            LOG_IMAGE(0,@"%@settings UIImage object equal to downloaded response",activityName);
            [self.iv_photo performSelectorOnMainThread:@selector(setImage:) withObject:response.image waitUntilDone:NO];
            self.iv_photo.contentMode = UIViewContentModeScaleAspectFit;
            [self setNeedsDisplay];
        }
    }
    else {
        //self.iv_photo.backgroundColor = [UIColor redColor];
        // show the photo placeholder icon
        [self.iv_photo setContentMode:UIViewContentModeCenter];
        self.iv_photo.image = [UIImage imageNamed:@"icon-pics2-large.png"];
        LOG_IMAGE(1,@"%@Image failed to download",activityName);
        [self setNeedsDisplay];
    }
    
}

- (void) onNewPhotoVote:(CallbackResult*)result {
    ResourceContext* resourceContext = [ResourceContext instance];
    
    Page* draft = (Page*)[resourceContext resourceWithType:PAGE withID:self.pageID];
    
    if (draft != nil) {
        Photo* topPhoto = [draft photoWithHighestVotes];
        self.topVotedPhotoID = topPhoto.objectid;
        [self renderPhoto:topPhoto];
    }
}

#pragma mark - Statics
+ (NSString*) cellIdentifier {
    return @"productionlogcellnew";
}


@end
