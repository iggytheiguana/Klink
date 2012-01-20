//
//  ProductionLogViewController2.m
//  Platform
//
//  Created by Jordan Gurrieri on 11/16/11.
//  Copyright (c) 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "ProductionLogViewController.h"
#import "UIProductionLogTableViewCell.h"
#import "Macros.h"
#import "Page.h"
#import "Photo.h"
#import "ImageManager.h"
#import "ImageDownloadResponse.h"
#import "DraftViewController.h"
#import "ContributeViewController.h"
#import "UINotificationIcon.h"
#import "CloudEnumeratorFactory.h"
#import "DateTimeHelper.h"
#import "ApplicationSettings.h"
#import "ApplicationSettingsManager.h"
#import "ProfileViewController.h"
#import "PageState.h"
#import "PlatformAppDelegate.h"
#import "UserDefaultSettings.h"
#import "UIStrings.h"
#import "BookViewControllerBase.h"
#import "NotificationsViewController.h"
#import "DateTimeHelper.h"

#define kPHOTOID @"photoid"
#define kCELLID @"cellid"
#define kCELLTITLE @"celltitle"
#define kPRODUTIONLOGTABLEVIEWCELLHEIGHT 73

@implementation ProductionLogViewController
@synthesize tbl_productionTableView     = m_tbl_productionTableView;
@synthesize frc_draft_pages             = __frc_draft_pages;
@synthesize productionTableViewCell     = m_productionTableViewCell;
@synthesize lbl_title                   = m_lbl_title;
@synthesize lbl_numDraftsTotal          = m_lbl_numDraftsTotal;
@synthesize lbl_numDraftsClosing        = m_lbl_numDraftsClosing;
@synthesize cloudDraftEnumerator        = m_cloudDraftEnumerator;
@synthesize refreshHeader               = m_refreshHeader;
@synthesize selectedDraftID             = m_selectedDraftID;
@synthesize v_typewriter                = m_v_typewriter;
@synthesize btn_profileButton           = m_btn_profileButton;
@synthesize btn_newPageButton           = m_btn_newPageButton;
@synthesize btn_notificationsButton     = m_btn_notificationsButton;
@synthesize shouldOpenTypewriter        = m_shouldOpenTypewriter;
@synthesize shouldCloseTypewriter       = m_shouldCloseTypewriter;
@synthesize swipeGesture                = m_swipeGesture;


#pragma mark - Properties
//this NSFetchedResultsController will query for all draft pages
- (NSFetchedResultsController*) frc_draft_pages {
    NSString* activityName = @"ProductionLogViewController.frc_draft_pages:";
    if (__frc_draft_pages != nil) {
        return __frc_draft_pages;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    ResourceContext* resourceContext = [ResourceContext instance];
    PlatformAppDelegate* app = (PlatformAppDelegate*)[[UIApplication sharedApplication]delegate];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:PAGE inManagedObjectContext:app.managedObjectContext];
    
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:DATEDRAFTEXPIRES   ascending:YES];
    
    double doubleDateNow = [[NSDate date] timeIntervalSince1970];
    
    //add predicate to test for being published
    NSString* stateAttributeNameStringValue = [NSString stringWithFormat:@"%@",STATE];
    NSString* dateExpireAttributeNameStringValue = [NSString stringWithFormat:@"%@",DATEDRAFTEXPIRES];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K=%d AND %K >= %f",stateAttributeNameStringValue, kDRAFT, dateExpireAttributeNameStringValue,doubleDateNow];
    
    
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController* controller = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:resourceContext.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    controller.delegate = self;
    self.frc_draft_pages = controller;
    
    
    NSError* error = nil;
    [controller performFetch:&error];
  	if (error != nil)
    {
        LOG_PRODUCTIONLOGVIEWCONTROLLER(1, @"%@Could not create instance of NSFetchedResultsController due to %@",activityName,[error userInfo]);
    }
    
    [controller release];
    [fetchRequest release];
    [sortDescriptor release];
    return __frc_draft_pages;
    
}

- (void) updateDraftCounterLabels {
    int numDraftsTotal = [[self.frc_draft_pages fetchedObjects]count];
    self.lbl_numDraftsTotal.text = [NSString stringWithFormat:@"total drafts: %d", numDraftsTotal];
    
    int numDraftsClosing = 0;
    NSDate* now = [NSDate date];
    NSDate* deadline = nil;
    ApplicationSettings* settings = [[ApplicationSettingsManager instance] settings];
    NSTimeInterval draftExpirySetting = [settings.page_draftexpiry_seconds doubleValue];
    
    for (int i = 0; i < numDraftsTotal; i++) {
        Page* draft = [[self.frc_draft_pages fetchedObjects]objectAtIndex:i];
        deadline = [DateTimeHelper parseWebServiceDateDouble:draft.datedraftexpires];
        NSTimeInterval deadlineIntervalRemaining = [deadline timeIntervalSinceDate:now];
        if ((deadlineIntervalRemaining < draftExpirySetting) && (deadlineIntervalRemaining > 0)) {
            numDraftsClosing++;
        }
    }
    
    self.lbl_numDraftsClosing.text = [NSString stringWithFormat:@"closing today: %d", numDraftsClosing];
}

- (void) registerCallbackHandlers {
    // resister callbacks for change events
    Callback* newDraftCallback = [[Callback alloc]initWithTarget:self withSelector:@selector(onNewDraft:)];
    Callback* newPhotoCallback = [[Callback alloc]initWithTarget:self withSelector:@selector(onNewPhoto:)];
    Callback* newCaptionCallback = [[Callback alloc]initWithTarget:self withSelector:@selector(onNewCaption:)];
    Callback* newPhotoVoteCallback = [[Callback alloc]initWithTarget:self withSelector:@selector(onNewPhotoVote:)];
    Callback* newCaptionVoteCallback = [[Callback alloc]initWithTarget:self withSelector:@selector(onNewCaptionVote:)];
    
    //we set each callback to call on the mainthread
    newDraftCallback.fireOnMainThread = YES;
    newPhotoCallback.fireOnMainThread = YES;
    newCaptionCallback.fireOnMainThread = YES;
    newPhotoCallback.fireOnMainThread = YES;
    newCaptionCallback.fireOnMainThread = YES;
    newCaptionVoteCallback.fireOnMainThread = YES;
    
    [self.eventManager registerCallback:newDraftCallback forSystemEvent:kNEWPAGE];
    [self.eventManager registerCallback:newPhotoCallback forSystemEvent:kNEWPHOTO];
    [self.eventManager registerCallback:newCaptionCallback forSystemEvent:kNEWCAPTION];
    [self.eventManager registerCallback:newPhotoVoteCallback forSystemEvent:kNEWPHOTOVOTE];
    [self.eventManager registerCallback:newCaptionVoteCallback forSystemEvent:kNEWCAPTIONVOTE];
    
    [newDraftCallback release];
    [newPhotoCallback release];
    [newCaptionCallback release];
    [newPhotoVoteCallback release];
    [newCaptionVoteCallback release];
    
}

#pragma mark - Toolbar buttons
- (NSArray*) toolbarButtonsForViewController {
    //returns an array with the toolbar buttons for this view controller
    NSMutableArray* retVal = [[[NSMutableArray alloc]init]autorelease];
    
    //flexible space for button spacing
    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem* profileButton = [[UIBarButtonItem alloc]
                                      initWithImage:[UIImage imageNamed:@"icon-profile.png"]
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(onProfileButtonPressed:)];
    [retVal addObject:profileButton];
    [profileButton release];
    
    //add flexible space for button spacing
    [retVal addObject:flexibleSpace];
    
    //add draft button
    UIBarButtonItem* draftButton = [[UIBarButtonItem alloc]
                                     initWithImage:[UIImage imageNamed:@"icon-newPage.png"]
                                     style:UIBarButtonItemStylePlain
                                     target:self
                                     action:@selector(onPageButtonPressed:)];
    [retVal addObject:draftButton];
    [draftButton release];
    
    //check to see if the user is logged in or not
    if ([self.authenticationManager isUserAuthenticated]) {
        //we only add a notification icon for user's that have logged in
        
        //add flexible space for button spacing
        [retVal addObject:flexibleSpace];
        
        UINotificationIcon* notificationIcon = [UINotificationIcon notificationIconForPageViewControllerToolbar];
        UIBarButtonItem* notificationBarItem = [[[UIBarButtonItem alloc]initWithCustomView:notificationIcon]autorelease];
        
        [retVal addObject:notificationBarItem];
    }
    
    [flexibleSpace release];
    
    return retVal;
}

#pragma mark - Typewriter open animation
- (void) typewriterOpenView:(UIView *)viewToOpen duration:(NSTimeInterval)duration {
    // Remove existing animations before starting new animation
    [viewToOpen.layer removeAllAnimations];
    
    // Make sure view is visible
    viewToOpen.hidden = NO;
    //[self.view bringSubviewToFront:viewToOpen];
    
    // disable the view so it’s not doing anything while animating
    viewToOpen.userInteractionEnabled = NO;
    // Set the CALayer anchorPoint to the bottom edge and
    // translate the view to account for the new
    // anchorPoint. In case you want to reuse the animation
    // for this view, we only do the translation and
    // anchor point setting once.
    if (viewToOpen.layer.anchorPoint.y != 1.0f) {
        //viewToClose.layer.anchorPoint = CGPointMake(0.0f, 0.5f);
        viewToOpen.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
        //viewToClose.center = CGPointMake(viewToClose.center.x - viewToClose.bounds.size.width/2.0f, viewToClose.center.y);
        viewToOpen.center = CGPointMake(viewToOpen.center.x, viewToOpen.center.y + viewToOpen.bounds.size.height/2.0f);
    }
    // create an animation to hold the page turning
    CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    transformAnimation.removedOnCompletion = NO;
    transformAnimation.duration = duration;
    transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    // start the animation from the current state
    transformAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    // this is the basic rotation by 90 degree along the y-axis
    CATransform3D endTransform = CATransform3DMakeRotation(3.141f/2.0f,
                                                           -1.0f,
                                                           0.0f,
                                                           0.0f);
    // these values control the 3D projection outlook
    endTransform.m34 = 0.001f;
    endTransform.m24 = 0.005f;
    transformAnimation.toValue = [NSValue valueWithCATransform3D:endTransform];
    // Create an animation group to hold the rotation
    CAAnimationGroup *theGroup = [CAAnimationGroup animation];
    
    // Set self as the delegate to receive notification when the animation finishes
    theGroup.delegate = self;
    theGroup.duration = duration;
    // CAAnimation-objects support arbitrary Key-Value pairs, we add the UIView tag
    // to identify the animation later when it finishes
    [theGroup setValue:[NSNumber numberWithInt:viewToOpen.tag] forKey:@"viewToOpenTag"];
    // Here you could add other animations to the array
    theGroup.animations = [NSArray arrayWithObjects:transformAnimation, nil];
    theGroup.fillMode = kCAFillModeBoth;
    theGroup.removedOnCompletion = NO;
    // Add the animation group to the layer
    [viewToOpen.layer addAnimation:theGroup forKey:@"flipViewOpen"];
}

- (void) typewriterCloseView:(UIView *)viewToClose duration:(NSTimeInterval)duration {
    // Remove existing animations before starting new animation
    [viewToClose.layer removeAllAnimations];
    
    // Make sure view is visible
    viewToClose.hidden = NO;
    //[self.view bringSubviewToFront:viewToClose];
    
    // disable the view so it’s not doing anything while animating
    viewToClose.userInteractionEnabled = NO;
    // Set the CALayer anchorPoint to the bottom edge and
    // translate the view to account for the new
    // anchorPoint. In case you want to reuse the animation
    // for this view, we only do the translation and
    // anchor point setting once.
    if (viewToClose.layer.anchorPoint.y != 1.0f) {
        //viewToClose.layer.anchorPoint = CGPointMake(0.0f, 0.5f);
        viewToClose.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
        //viewToClose.center = CGPointMake(viewToClose.center.x - viewToClose.bounds.size.width/2.0f, viewToClose.center.y);
        viewToClose.center = CGPointMake(viewToClose.center.x, viewToClose.center.y + viewToClose.bounds.size.height/2.0f);
    }
    // create an animation to hold the page turning
    CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    transformAnimation.removedOnCompletion = NO;
    transformAnimation.duration = duration;
    transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    // start the animation from the open state
    // this is the basic rotation by 90 degree along the x-axis
    CATransform3D startTransform = CATransform3DMakeRotation(3.141f/2.0f,
                                                             -1.0f,
                                                             0.0f,
                                                             0.0f);
    // these values control the 3D projection outlook
    //startTransform.m34 = 0.001f;
    //startTransform.m14 = -0.0015f;
    startTransform.m34 = 0.001f;
    startTransform.m24 = 0.005f;
    transformAnimation.fromValue = [NSValue valueWithCATransform3D:startTransform];
    
    // end the transformation at the default state
    transformAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    
    // Create an animation group to hold the rotation
    CAAnimationGroup *theGroup = [CAAnimationGroup animation];
    
    // Set self as the delegate to receive notification when the animation finishes
    theGroup.delegate = self;
    theGroup.duration = duration;
    // CAAnimation-objects support arbitrary Key-Value pairs, we add the UIView tag
    // to identify the animation later when it finishes
    [theGroup setValue:[NSNumber numberWithInt:viewToClose.tag] forKey:@"viewToCloseTag"];
    // Here you could add other animations to the array
    theGroup.animations = [NSArray arrayWithObjects:transformAnimation, nil];
    theGroup.fillMode = kCAFillModeBoth;
    theGroup.removedOnCompletion = NO;
    // Add the animation group to the layer
    [viewToClose.layer addAnimation:theGroup forKey:@"flipViewClosed"];
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    
    // Get the tag from the animation, we use it to find the
    // animated UIView
    NSString *animationKeyClosed = [NSString stringWithFormat:@"flipViewClosed"];
    
    if (flag) {
        for (NSString* animationKey in self.v_typewriter.layer.animationKeys) {
            if ([animationKey isEqualToString:animationKeyClosed]) {
                // typewriter was closed
                
                self.v_typewriter.userInteractionEnabled = YES;
                
            }
            else {
                // typewriter was opened, move to draft view
                
                // Open Draft View
                DraftViewController* draftViewController = [DraftViewController createInstanceWithPageID:self.selectedDraftID];
                
                // Set up navigation bar back button
                self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Production Log"
                                                                                          style:UIBarButtonItemStyleBordered
                                                                                         target:nil
                                                                                         action:nil] autorelease];
                
                [self.navigationController pushViewController:draftViewController animated:YES];
                
                // Now we just hide the animated view since
                // animation.removedOnCompletion is not working
                // in animation groups. Hiding the view prevents it
                // from returning to the original state and showing.
                //self.iv_bookCover.hidden = YES;
                //[self.view sendSubviewToBack:self.iv_bookCover];
            }
        }
    }
    
    /*// Get the tag from the animation, we use it to find the
     // animated UIView
     NSNumber *tag = [theAnimation valueForKey:@"viewToOpenTag"];
     // Find the UIView with the tag and do what you want
     // This only searches the first level subviews
     for (UIView *subview in self.view.subviews) {
     if (subview.tag == [tag intValue]) {
     // Code for what's needed to happen after
     // the animation finishes goes here.
     if (flag) {
     // Now we just hide the animated view since
     // animation.removedOnCompletion is not working
     // in animation groups. Hiding the view prevents it
     // from returning to the original state and showing.
     subview.hidden = YES;
     }
     }
     }*/
    
}

- (void)openTypewriter {
    // Setup the typewriter animation
    self.shouldCloseTypewriter = YES;
    self.shouldOpenTypewriter = NO;
    
    [self typewriterOpenView:self.v_typewriter duration:0.5f];
}

- (void)closeTypewriter {
    // Setup the typewriter animation
    self.shouldCloseTypewriter = NO;
    self.shouldOpenTypewriter = YES;
    
    [self typewriterCloseView:self.v_typewriter duration:0.5f];
}

#pragma mark - Initializers
- (void) commonInit {
    //common setup for the view controller
    //self.cloudDraftEnumerator = [[CloudEnumeratorFactory instance]enumeratorForDrafts];
    //self.cloudDraftEnumerator.delegate = self;
            
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self commonInit];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {
    self.frc_draft_pages = nil;
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.cloudDraftEnumerator = [[CloudEnumeratorFactory instance]enumeratorForDrafts];
    self.cloudDraftEnumerator.delegate = self;
    
    CGRect frameForRefreshHeader = CGRectMake(0, 0.0f - self.tbl_productionTableView.bounds.size.height, self.tbl_productionTableView.bounds.size.width, self.tbl_productionTableView.bounds.size.height);
    
    EGORefreshTableHeaderView* erthv = [[EGORefreshTableHeaderView alloc] initWithFrame:frameForRefreshHeader];
    self.refreshHeader = erthv;
    [erthv release];
    
    self.refreshHeader.delegate = self;
    self.refreshHeader.backgroundColor = [UIColor clearColor];
    self.tbl_productionTableView.rowHeight = kPRODUTIONLOGTABLEVIEWCELLHEIGHT;
    [self.tbl_productionTableView addSubview:self.refreshHeader];
    [self.refreshHeader refreshLastUpdatedDate];
    
    [self updateDraftCounterLabels];
    
    [self registerCallbackHandlers];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Navigation Bar Buttons
    UIBarButtonItem* leftButton = [[[UIBarButtonItem alloc]
                                     initWithTitle:@"Home"
                                    style:UIBarButtonItemStyleBordered 
                                    target:self 
                                    action:@selector(onHomeButtonPressed:)] autorelease];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    // Create gesture recognizer for the typewriter view to pass swipes through to the tableview
    self.swipeGesture = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:nil] autorelease];
    self.swipeGesture.direction = UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
    self.swipeGesture.delegate = self;
    
    // Add the gesture to the typewriter view
    [self.v_typewriter addGestureRecognizer:self.swipeGesture];
    
    // Setup the animation to show the typewriter
    self.shouldCloseTypewriter = YES;
    self.shouldOpenTypewriter = YES;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.tbl_productionTableView = nil;
    self.productionTableViewCell = nil;
    self.refreshHeader = nil;
    self.lbl_title = nil;
    self.lbl_numDraftsTotal = nil;
    self.lbl_numDraftsClosing = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSString* activityName = @"ProductionLogViewController.viewWillAppear:";
    [super viewWillAppear:animated];

    //if its the first time the user has opened the production log, we display a welcome message
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:setting_HASVIEWEDPRODUCTIONLOGVC] == NO) {
        //this is the first time opening, so we show a welcome message
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Production Log" message:ui_WELCOME_PRODUCTIONLOG delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        
        [alert show];
        [alert release];
    }
    
    
    if ([self.cloudDraftEnumerator canEnumerate]) 
    {
        LOG_PRODUCTIONLOGVIEWCONTROLLER(0, @"%@Refreshing production log from cloud",activityName);
        [self.cloudDraftEnumerator enumerateUntilEnd:nil];
    }
    else {
        LOG_PRODUCTIONLOGVIEWCONTROLLER(0,@"%@Skipping refresh of production log, as the enumerator is not ready",activityName);
        
        //optionally if there is no draft query being executed, and we are authenticated, then we then refresh the notification feed
        Callback* callback = [Callback callbackForTarget:self selector:@selector(onFeedRefreshComplete:) fireOnMainThread:YES];
        [[FeedManager instance]tryRefreshFeedOnFinish:callback];

    }
    
       
    // Update draft counter labels at the top of the view
    [self updateDraftCounterLabels];

    // unhide navigation bar and toolbar
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    // Toolbar: we update the toolbar items each time the view controller is shown
    NSArray* toolbarItems = [self toolbarButtonsForViewController];
    [self setToolbarItems:toolbarItems];
    
    [self.navigationController setToolbarHidden:YES animated:NO];
    //[self.navigationController setNavigationBarHidden:YES animated:NO];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //we mark that the user has viewed this viewcontroller at least once
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:setting_HASVIEWEDPRODUCTIONLOGVC]==NO) {
        [userDefaults setBool:YES forKey:setting_HASVIEWEDPRODUCTIONLOGVC];
        [userDefaults synchronize];
    }
    
    if (self.shouldCloseTypewriter) {
        [self closeTypewriter];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString* activityName = @"ProductionLogViewController.numberOfRowsInSection";
 
    int retVal = [[self.frc_draft_pages fetchedObjects]count];
    // Return the number of rows in the section.
    LOG_PRODUCTIONLOGVIEWCONTROLLER(0, @"%@Number of rows in fetched results controller:%d",activityName,retVal);
        return retVal;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int draftCount = [[self.frc_draft_pages fetchedObjects]count];
    
    if ([indexPath row] < draftCount) {
        Page* draft = [[self.frc_draft_pages fetchedObjects] objectAtIndex:[indexPath row]];
        
        UIProductionLogTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[UIProductionLogTableViewCell cellIdentifier]];
        if (cell == nil) {
            cell = [[[UIProductionLogTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[UIProductionLogTableViewCell cellIdentifier]] autorelease];
        }
        
        [cell renderDraftWithID:draft.objectid];
        return cell;
    }
    else {
        return nil;
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - UIAlertView Delegate
- (void)alertView:(UICustomAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [super alertView:alertView clickedButtonAtIndex:buttonIndex];
    
    if (buttonIndex == 1 && alertView.delegate == self) {
        if (![self.authenticationManager isUserAuthenticated]) {
            // user is not logged in
            [self authenticate:YES withTwitter:NO onFinishSelector:alertView.onFinishSelector onTargetObject:self withObject:nil];
        }
    }
}

#pragma mark - Navigation Bar Button Handlers
- (void) onHomeButtonPressed:(id)sender {
    // Setup the typewriter animation
    self.shouldCloseTypewriter = YES;
    self.shouldOpenTypewriter = NO;
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIGestureRecognizer Delegates
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // test if our typewriter control subview is on-screen
    if (self.v_typewriter.superview != nil) {
        if (gestureRecognizer == self.swipeGesture) {
            // user swiped in the area of the typewriter view, pass the touch on to the tableview
            //[self.nextResponder touchesBegan:[NSSet setWithObject:touch] withEvent:UIEventTypeTouches];
            
            return NO; // ignore the touch
        }
    }
    return YES; // handle the touch
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Toolbar Button Event Handlers
- (void) onProfileButtonPressed:(id)sender {
    // Setup the typewriter animation
    self.shouldCloseTypewriter = NO;
    self.shouldOpenTypewriter = NO;
    
    if (![self.authenticationManager isUserAuthenticated]) {
        UICustomAlertView *alert = [[UICustomAlertView alloc]
                              initWithTitle:@"Login Required"
                              message:@"Hello! You must punch-in on the production floor to access your profile.\n\nPlease login, or join us as a new contributor via Facebook."
                              delegate:self
                              onFinishSelector:@selector(onProfileButtonPressed:)
                              onTargetObject:self
                              withObject:nil
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Login", nil];
        
        
        [alert show];
        [alert release];
    }
    else {
        ProfileViewController* profileViewController = [ProfileViewController createInstance];
        
        UINavigationController* navigationController = [[UINavigationController alloc]initWithRootViewController:profileViewController];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navigationController animated:YES];
        
        [navigationController release];
    }
   
}

- (void) onPageButtonPressed:(id)sender {
    // Setup the typewriter animation
    self.shouldCloseTypewriter = NO;
    self.shouldOpenTypewriter = NO;
    
    //we check to ensure the user is logged in first
    if (![self.authenticationManager isUserAuthenticated]) {
        UICustomAlertView *alert = [[UICustomAlertView alloc]
                              initWithTitle:@"Login Required"
                              message:@"Hello! You must punch-in on the production floor to start a new draft.\n\nPlease login, or join us as a new contributor via Facebook."
                              delegate:self
                              onFinishSelector:@selector(onPageButtonPressed:)
                              onTargetObject:self
                              withObject:nil
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Login", nil];
        [alert show];
        [alert release];
    }
    else {
        ContributeViewController* contributeViewController = [ContributeViewController createInstanceForNewDraft];
        contributeViewController.delegate = self;
        
        UINavigationController* navigationController = [[UINavigationController alloc]initWithRootViewController:contributeViewController];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navigationController animated:YES];
        
        [navigationController release];
        [contributeViewController release];
    }
}

- (void) onNotificationsButtonClicked:(id)sender {
    // Setup the typewriter animation
    self.shouldCloseTypewriter = NO;
    self.shouldOpenTypewriter = NO;
    
    //we check to ensure the user is logged in first
    if (![self.authenticationManager isUserAuthenticated]) {
        UICustomAlertView *alert = [[UICustomAlertView alloc]
                                    initWithTitle:@"Login Required"
                                    message:@"Hello! You must punch-in on the production floor to see your notifications.\n\nPlease login, or join us as a new contributor via Facebook."
                                    delegate:self
                                    onFinishSelector:@selector(onNotificationsButtonPressed:)
                                    onTargetObject:self
                                    withObject:nil
                                    cancelButtonTitle:@"Cancel"
                                    otherButtonTitles:@"Login", nil];
        [alert show];
        [alert release];
    }
    else {
        NotificationsViewController* notificationsViewController = [NotificationsViewController createInstance];
        
        UINavigationController* navigationController = [[UINavigationController alloc]initWithRootViewController:notificationsViewController];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navigationController animated:YES];
        
        [navigationController release];
    }
}

#pragma mark - Table view delegate
//- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return kPRODUTIONLOGTABLEVIEWCELLHEIGHT;
//}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.refreshHeader egoRefreshScrollViewDidScroll:scrollView];
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.refreshHeader egoRefreshScrollViewDidEndDragging:scrollView];
    
    // reset the content inset of the tableview so bottom is not covered by toolbar
    //[self.tbl_productionTableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 63.0f, 0.0f)];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Setup the typewriter animation
    self.shouldCloseTypewriter = YES;
    self.shouldOpenTypewriter = YES;
    
    /*// Set up navigation bar back button
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Production Log"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:nil
                                                                             action:nil] autorelease];
    
    // Open Draft View
    Page* draft = [[self.frc_draft_pages fetchedObjects] objectAtIndex:[indexPath row]];
    
    DraftViewController* draftViewController = [DraftViewController createInstanceWithPageID:draft.objectid];
    
    [self.navigationController pushViewController:draftViewController animated:YES];*/
    
    // Get ID of draft user selected
    Page* draft = [[self.frc_draft_pages fetchedObjects] objectAtIndex:[indexPath row]];
    self.selectedDraftID = draft.objectid;
    
    if (self.shouldOpenTypewriter) {
        [self openTypewriter];
    }
   
}

#pragma mark - NSFetchedResultsControllerDelegate methods
- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tbl_productionTableView beginUpdates];
}


- (void) controller:(NSFetchedResultsController *)controller 
    didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath 
      forChangeType:(NSFetchedResultsChangeType)type 
       newIndexPath:(NSIndexPath *)newIndexPath {
    
    NSString* activityName = @"ProductionLogViewController.controller.didChangeObject:";
    if (controller == self.frc_draft_pages) {
        if (type == NSFetchedResultsChangeInsert) {
            //insertion of a new page
            Resource* resource = (Resource*)anObject;
            int count = [[self.frc_draft_pages fetchedObjects]count];
            LOG_PRODUCTIONLOGVIEWCONTROLLER(0, @"%@Inserting newly created resource with type %@ and id %@ at index %d (num itemsin frc:%d)",activityName,resource.objecttype,resource.objectid,[newIndexPath row],count);
            [self.tbl_productionTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            LOG_PRODUCTIONLOGVIEWCONTROLLER(0, @"%@Scrolling table view to newly created item",activityName);
           // [self.tbl_productionTableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            //LOG_PRODUCTIONLOGVIEWCONTROLLER(0, @"%@Reloading table",activityName);
           // [self.tbl_productionTableView reloadData];
            // Update draft counter labels at the top of the view
            [self updateDraftCounterLabels];
        }
        else if (type == NSFetchedResultsChangeDelete) {
            [self.tbl_productionTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
           // [self.tbl_productionTableView reloadData];
            // Update draft counter labels at the top of the view
            [self updateDraftCounterLabels];
        }
    }
    else {
        LOG_PRODUCTIONLOGVIEWCONTROLLER(1, @"%@Received a didChange message from a NSFetchedResultsController that isnt mine. %p",activityName,&controller);
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    
    [self.tbl_productionTableView endUpdates];
    [self.tbl_productionTableView reloadData];
}

#pragma mark - Callback Event Handlers
- (void) onNewDraft:(CallbackResult*)result {
    [self.tbl_productionTableView reloadData];
}

- (void) onNewPhoto:(CallbackResult*)result {
    [self.tbl_productionTableView reloadData];
}

- (void) onNewCaption:(CallbackResult*)result {
    [self.tbl_productionTableView reloadData];
}

- (void) onNewPhotoVote:(CallbackResult*)result {
    [self.tbl_productionTableView reloadData];
}

- (void) onNewCaptionVote:(CallbackResult*)result {
    [self.tbl_productionTableView reloadData];
}


#pragma mark - EgoRefreshTableHeaderDelegate
- (void) egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view {
    
    [self.cloudDraftEnumerator reset];
    [self.cloudDraftEnumerator enumerateUntilEnd:nil];

}

- (BOOL) egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view {
    if (self.cloudDraftEnumerator != nil) {
        return [self.cloudDraftEnumerator isLoading];
    }
    else {
        return NO;
    }
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view {
    return [NSDate date];
}


#pragma mark - Call back for feed refresh
- (void) onFeedRefreshComplete:(CallbackResult*)result 
{
    //perform any post feed update actions here
}
#pragma mark - CloudEnumeratorDelegate
- (void) onEnumerateComplete:(CloudEnumerator*)enumerator 
                 withResults:(NSArray *)results 
                withUserInfo:(NSDictionary *)userInfo
{
    //we tell the ego fresh header that we've stopped loading items
    [self.refreshHeader egoRefreshScrollViewDataSourceDidFinishedLoading:self.tbl_productionTableView];
    
    // reset the content inset of the tableview so bottom is not covered by toolbar
    [self.tbl_productionTableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 63.0f, 0.0f)];
}

@end
