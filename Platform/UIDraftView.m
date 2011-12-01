//
//  UIDraftView.m
//  Platform
//
//  Created by Jordan Gurrieri on 11/3/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "UIDraftView.h"
#import "DraftViewController.h"
#import "Macros.h"
#import "UIDraftTableViewCellLeft.h"
#import "DateTimeHelper.h"
#import "AuthenticationManager.h"
#import "Types.h"
#import "Attributes.h"
#import "Photo.h"
#import "Page.h"
#import "FullScreenPhotoViewController.h"

#define kPAGEID @"pageid"

@implementation UIDraftView
@synthesize frc_photos = __frc_photos;
@synthesize pageID = m_pageID;
@synthesize view = m_view;
@synthesize draftTitle = m_draftTitle;
@synthesize tbl_draftTableView = m_tbl_draftTableView;

@synthesize draftTableViewCellLeft = m_draftTableViewCellLeft;

@synthesize navigationController = m_navigationController;

#pragma mark - Properties
- (NSFetchedResultsController*) frc_photos {
    NSString* activityName = @"UIDraftView.frc_photos:";
    
    if (__frc_photos != nil) {
        return __frc_photos;
    }
    else {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
        ResourceContext* resourceContext = [ResourceContext instance];
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:PHOTO inManagedObjectContext:resourceContext.managedObjectContext];
        
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NUMBEROFVOTES ascending:NO];
        
        //add predicate to gather only photos for this pageID    
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K=%@", THEMEID, self.pageID];
        
        [fetchRequest setPredicate:predicate];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        [fetchRequest setEntity:entityDescription];
        [fetchRequest setFetchBatchSize:20];
        
        NSFetchedResultsController* controller = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:resourceContext.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        controller.delegate = self;
        self.frc_photos = controller;
        
        
        NSError* error = nil;
        [controller performFetch:&error];
        if (error != nil)
        {
            LOG_UIDRAFTVIEW(1, @"%@Could not create instance of NSFetchedResultsController due to %@",activityName,[error userInfo]);
        }
        
        [controller release];
        [fetchRequest release];
        
        return __frc_photos;
    }
}

#pragma mark - Instance Methods
- (void) renderDraftWithID:(NSNumber *)pageID {
    ResourceContext* resourceContext = [ResourceContext instance];
    Page* page = (Page*)[resourceContext resourceWithType:PAGE withID:pageID];
    
    if (page != nil) {
        
        self.pageID = page.objectid;
        self.draftTitle.text = page.displayname;
        [self.tbl_draftTableView reloadData];
        
    }
}

#pragma mark - Initialization
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Custom initialization
        //self.pageID = pageID;
        
        NSArray* topLevelObjs = nil;
        
        topLevelObjs = [[NSBundle mainBundle] loadNibNamed:@"UIDraftView" owner:self options:nil];
        if (topLevelObjs == nil)
        {
            NSLog(@"Error! Could not load UIDraftView file.\n");
        }
        
        [self addSubview:self.view];
        
        //self.tbl_draftTableView = [[UITableView alloc] initWithFrame:frame style:style];
        //self.tbl_draftTableView.frame = frame;
        //self.tbl_draftTableView.style = style;
        //self.tbl_draftTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        //self.tbl_draftTableView.delegate = self;
        //self.tbl_draftTableView.dataSource = self;
        //self.tbl_draftTableView.bounces = TRUE;
        //self.tbl_draftTableView.backgroundColor = [UIColor clearColor];
        //self.tbl_draftTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        //[self.view addSubview:self.tbl_draftTableView];
        
        //UIColor *background = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"page_curled.png"]];
        //self.view.backgroundColor = background;
        //[background release];

    }
    return self;
}

- (void)dealloc
{
    [self.tbl_draftTableView release];
    [self.frc_photos release];
    [self.pageID release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Table View Delegate methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 113;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Photo* selectedPhoto = [[self.frc_photos fetchedObjects] objectAtIndex:[indexPath row]];
    FullScreenPhotoViewController* photoViewController = [FullScreenPhotoViewController createInstanceWithPageID:selectedPhoto.themeid withPhotoID:selectedPhoto.objectid];
    
    [photoViewController addObserver:self forKeyPath:@"tableViewNeedsUpdate" options:NSKeyValueObservingOptionNew context:tableView];
    
    [self.navigationController pushViewController:photoViewController animated:YES];
    [photoViewController release];
}

 
#pragma mark Table View Data Source Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.frc_photos fetchedObjects]count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int photoCount = [[self.frc_photos fetchedObjects]count];
    if ([indexPath row] < photoCount) 
    {
        Photo* photo = [[self.frc_photos fetchedObjects] objectAtIndex:[indexPath row]];
        
        UIDraftTableViewCellLeft* cell = (UIDraftTableViewCellLeft*) [tableView dequeueReusableCellWithIdentifier:[UIDraftTableViewCellLeft cellIdentifier]];
        
        if (cell == nil) 
        {
            cell = [[[UIDraftTableViewCellLeft alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[UIDraftTableViewCellLeft cellIdentifier]]autorelease];
        }
        
        [cell renderWithPhotoID:photo.objectid];
        return cell;
    }
    else {
        return nil;
    }
}

#pragma mark - KVO-Observer Method
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    //NSObject* changeValue = [change objectForKey:NSKeyValueChangeNewKey];
    
    if ([keyPath isEqual:@"tableViewNeedsUpdate"] && (context == self.tbl_draftTableView)) {
        [self.tbl_draftTableView reloadData];
    }
    
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void) controller:(NSFetchedResultsController *)controller 
    didChangeObject:(id)anObject 
        atIndexPath:(NSIndexPath *)indexPath 
      forChangeType:(NSFetchedResultsChangeType)type 
       newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (type == NSFetchedResultsChangeInsert) {
        //new photo has been downloaded
        [self.tbl_draftTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
        [self.tbl_draftTableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    else if (type == NSFetchedResultsChangeDelete) {
        [self.tbl_draftTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
    
}

@end
