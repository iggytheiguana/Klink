//
//  UIPagedViewSlider2.m
//  Klink V2
//
//  Created by Bobby Gill on 8/2/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "UIPagedViewSlider2.h"
#import "UIPagedViewItem.h"
#define PADDING 0
#define kNumberOfPagesAfterLastVisibleIndexToLoad   5
#define kNumberOfPagesBeforeFirstVisibleIndexToLoad 5
@implementation UIPagedViewSlider2
@synthesize pagingScrollView    =   m_pagingScrollView;
@synthesize visiblePages        =   m_visiblePages;
@synthesize recycledPages       =   m_recycledPages;
@synthesize delegate            =   m_delegate;
@synthesize currentPageIndex    =   m_currentPageIndex;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

		m_currentPageIndex = 1;
		m_performingLayout = NO;
		m_rotating = NO;
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [super dealloc];
}

- (void)    didReceiveMemoryWarning {
    [self.recycledPages removeAllObjects];
}

-(id)       initWithWidth:          (int)   width_portrait
               withHeight:          (int)   height_portrait
       withWidthLandscape:          (int)   width_landscape
      withHeightLandscape:          (int)   height_landscape
              withSpacing:          (int)   spacing {
    
    m_itemHeight = height_portrait;
    m_itemWidth = width_portrait;
    m_itemSpacing = spacing;
    m_itemWidth_landscape = width_landscape;
    m_itemHeight_landscape = height_landscape;
    [self init];
    return self;
}

- (id)      initWithWidth:          (int)   width
               withHeight:          (int)   height
              withSpacing:          (int)   spacing
             isHorizontal:          (BOOL)  isHorizontal {
    
    m_itemWidth = width;
    m_itemHeight= height;
    m_itemSpacing = spacing;
    m_isHorizontalOrientation   = isHorizontal;
    [self init];
    return self;
}

- (id)    init {
    
//    self = [super init];
    
    if (self != nil) {
        // Setup paging scrolling view
        CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
        
        self.pagingScrollView = [[UIKlinkScrollView alloc] initWithFrame:pagingScrollViewFrame];
        self.pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.pagingScrollView.userInteractionEnabled = YES;
        self.pagingScrollView.pagingEnabled = YES;
        self.pagingScrollView.delegate = self;
        self.pagingScrollView.showsHorizontalScrollIndicator = NO;
        self.pagingScrollView.showsVerticalScrollIndicator = NO;
        self.pagingScrollView.backgroundColor = nil;
        self.pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
        self.pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:m_currentPageIndex];        
        [self addSubview:self.pagingScrollView];
        
        
        // Setup pages
        self.visiblePages = [[NSMutableSet alloc] init];
        self.recycledPages = [[NSMutableSet alloc] init];
        [self goToPage:0];
        
        
        
    }
    return self;
}

#pragma mark -
#pragma mark Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);    
    return frame;
}

- (CGRect)  frameForPageAtIndex:            (NSUInteger)    index {
    if (m_isHorizontalOrientation) {
        return CGRectMake((m_itemWidth + m_itemSpacing) * index, 0, m_itemWidth,  m_itemHeight);
    }
    else {
        return CGRectMake(0,(m_itemHeight+m_itemSpacing)*index, m_itemWidth, m_itemHeight);
    }
}



// Layout
- (void)    performLayout {
    // Flag
	m_performingLayout = YES;
	
//	// Toolbar
//	toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
	
	// Remember index
	NSUInteger indexPriorToLayout = self.currentPageIndex;
	
	// Get paging scroll view frame to determine if anything needs changing
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
	// Frame needs changing
    self.pagingScrollView.frame = pagingScrollViewFrame;
	
	// Recalculate contentSize based on current orientation
	self.pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	
	// Adjust frames and configuration of each visible page
	for (UIPagedViewItem *page in self.visiblePages) {
		page.frame = [self frameForPageAtIndex:page.index];
		[page setMaxMinZoomScalesForCurrentBounds];
	}
	
	// Adjust contentOffset to preserve page location based on values collected prior to location
	self.pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
	
	// Reset
	self.currentPageIndex = indexPriorToLayout;
	m_performingLayout = NO;
}

- (int) getIndex {
    CGPoint offset = self.pagingScrollView.contentOffset;
    if (m_isHorizontalOrientation) {
        return (int)floorf(offset.x/(m_itemSpacing+m_itemWidth));
    }
    else {
        return (int)floorf(offset.y/(m_itemSpacing+m_itemHeight));
    }
    
//    
//    UIDeviceOrientation orientation = [[UIDevice currentDevice]orientation];
//    CGPoint offset = self.pagingScrollView.contentOffset;
//    if (UIInterfaceOrientationIsLandscape(orientation)) {
//        return (int)floorf(offset.x/(m_itemSpacing+m_itemWidth_landscape));
//    }
//    else {
//        return (int)floorf(offset.x/(m_itemSpacing+m_itemWidth));
//    }
}

- (int) getLastVisibleIndex {
    
    CGRect visibleBounds = self.pagingScrollView.bounds;
//    UIDeviceOrientation orientation = [[UIDevice currentDevice]orientation];
//    
//    
//    
//    if (UIInterfaceOrientationIsLandscape(orientation)) {
//        return leftIndex + ceilf(visibleBounds.size.width / (m_itemSpacing+m_itemWidth_landscape));
//    }
//    else {
//        return leftIndex + ceilf(visibleBounds.size.width / (m_itemSpacing+m_itemWidth));
//    }
    
    if (m_isHorizontalOrientation) {
        int leftIndex = [self getIndex];
        return leftIndex + ceilf(visibleBounds.size.width/ (m_itemSpacing+m_itemWidth));
    }
    else {
        int topIndex = [self getIndex];
        return topIndex + ceilf(visibleBounds.size.height / (m_itemSpacing + m_itemHeight));
    }
}

- (BOOL) isVisible:(int)index {
    int leftIndex = [self getIndex];
    int rightIndex = [self getLastVisibleIndex];
    
    return (index >= leftIndex && index <= rightIndex);
}

- (void)    onNewItemInsertedAt:(int)index {
    
   
    CGSize newSize = [self contentSizeForPagingScrollView];
    self.pagingScrollView.contentSize = newSize;
    
    
    
    if ([self isVisible:index]) {
        [self tilePages];
    }
    
}
// Paging
- (void)    tilePages {
    // Calculate which pages should be visible
	// Ignore padding as paging bounces encroach on that
	// and lead to false page loads
    int count = [self.delegate itemCountFor:self];
    self.pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    if (count > 0) {
    
        
        int iFirstIndex = [self getIndex];
        int iLastIndex = [self getLastVisibleIndex];
        
        iFirstIndex = iFirstIndex - kNumberOfPagesBeforeFirstVisibleIndexToLoad;
        iLastIndex = iLastIndex + kNumberOfPagesAfterLastVisibleIndexToLoad;
        
        if (iFirstIndex < 0) iFirstIndex = 0;
        if (iFirstIndex > count - 1) iFirstIndex = count - 1;
        if (iLastIndex < 0) iLastIndex = 0;
        if (iLastIndex > count - 1) iLastIndex = count - 1;
        
        // Recycle no longer needed pages
        for (UIPagedViewItem *page in self.visiblePages) {
            
            //TODO: implement better view recycling methods
            if (page.index < (NSUInteger)iFirstIndex || page.index > (NSUInteger)iLastIndex) {
               [self.recycledPages addObject:page];
                page.index = NSNotFound; // empty
               [page.view removeFromSuperview];
            }
        }
        [self.visiblePages minusSet:self.recycledPages];
        
        // Add missing pages
        for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
            if (![self isDisplayingPageForIndex:index]) {
                UIPagedViewItem *page = [self dequeueRecycledPage];
                if (!page) {
                    page = [[[UIPagedViewItem alloc] init] autorelease];
                    page.userInteractionEnabled = YES;
                    //				page.photoBrowser = self;
                }
                [self configurePage:page forIndex:index];
                [self.visiblePages addObject:page];
                //[self.pagingScrollView addSubview:page];
                /*NSLog(@"Added page at index %i", page.index);*/
            }
        }
    }
}

- (void)configurePage:(UIPagedViewItem *)page forIndex:(NSUInteger)index {
	page.frame = [self frameForPageAtIndex:index];
	page.index = index;
    
    if (page.view == nil) {
        UIView* subview = [self.delegate viewSlider:self cellForRowAtIndex:index withFrame:page.frame];
        [self.pagingScrollView addSubview:subview];  
        page.view = subview;
    }
    else {
        UIView* existingView = page.view;
        [self.delegate viewSlider:self configure:page.view forRowAtIndex:index withFrame:page.frame];
        [self.pagingScrollView addSubview:existingView];
        
    }
 
}

- (void) reset  {
    [self.recycledPages removeAllObjects];
    NSArray* visiblePagesArray = [self.visiblePages allObjects];
    for (int i = 0; i < [visiblePagesArray count];i++) {
        UIPagedViewItem* item = [visiblePagesArray objectAtIndex:i];
        [item.view removeFromSuperview];
    }
    
    [self.visiblePages removeAllObjects];
    [self tilePages];
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
	for (UIPagedViewItem *page in self.visiblePages)
		if (page.index == index) return YES;
	return NO;
}

- (UIPagedViewItem *)dequeueRecycledPage {
	UIPagedViewItem *page = [self.recycledPages anyObject];
	if (page) {
		[[page retain] autorelease];
		[self.recycledPages removeObject:page];
	}
	return page;
}
// Properties
- (void)    setInitialPageIndex:    (NSUInteger)    index {
    self.currentPageIndex = index;
    [self performLayout];
    [self tilePages];
}

//Frames
- (CGSize)  contentSizeForPagingScrollView {
    int count = [self.delegate itemCountFor:self];
    if (m_isHorizontalOrientation) {
        return CGSizeMake((m_itemWidth+m_itemSpacing)*count,m_itemHeight);
    }
    else {
        return CGSizeMake(m_itemWidth,(m_itemHeight + m_itemSpacing)*count);
    }

    
}



- (CGPoint) contentOffsetForPageAtIndex:    (NSUInteger)    index {
    if (m_isHorizontalOrientation) {
        return CGPointMake((m_itemWidth+m_itemSpacing) * index, 0);
    }
    else {
        return CGPointMake(0,(m_itemHeight+m_itemSpacing)*index);
    }
    

}

#pragma mark -
#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
	if (m_performingLayout || m_rotating) return;
	
	// Tile pages
	[self tilePages];
	
	// Calculate current page
//	CGRect visibleBounds = self.pagingScrollView.bounds;
//	int index = (int)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    int count = [self.delegate itemCountFor:self];
    
//    if (index < 0) index = 0;
//	if (index > count - 1) index = count - 1;
	
    int index = [self getIndex];
    if (index < 0) index =0 ;
    
    if (index > count - 1) index = count - 1;
    int oldIndex = m_currentPageIndex;
    
    m_currentPageIndex = index;
    if (index != oldIndex) {
        [self.delegate viewSlider:self isAtIndex:m_currentPageIndex withCellsRemaining:count-m_currentPageIndex];
    }
    
    
//    
//    
//    NSUInteger previousCurrentPage = m_currentPageIndex;
//	self.currentPageIndex = index;
//	if (self.currentPageIndex != previousCurrentPage) {
//        
//        
//    }
	
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// Hide controls when dragging begins
    //TODO: make a call to view controller to do this
    //	[self setControlsHidden:YES];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// Update nav when page changes
    
    //TODO make a call to the view controller to do this
	[self updateNavigation];
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    
    //TODO: figure out whats supposed to happen here
}



- (void)goToPage:(int)index {
    int currentIndex = self.currentPageIndex;\
    int count = [self.delegate itemCountFor:self];
    CGPoint offset = CGPointMake((m_itemWidth+m_itemSpacing)*index, 0);
    self.pagingScrollView.contentOffset = offset;
    [self tilePages];

    
        [self.delegate viewSlider:self isAtIndex:self.currentPageIndex withCellsRemaining:count-m_currentPageIndex];
    
}

#pragma mark -
#pragma mark Navigation

- (void)updateNavigation {

	
}

#pragma mark - Tap Handler
#pragma mark - Scroll tap handler
- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event 
{
    
    // Process the single tap here
    if ([touches count]==1) { 
        
        
        UITouch* touch = [[touches allObjects]objectAtIndex:0];
        CGPoint touchLocation = [touch locationInView:self.pagingScrollView];
        int index = 0;
        int x = touchLocation.x;
        int y = touchLocation.y;
        
        if (m_isHorizontalOrientation) {
            index = (x) / (m_itemSpacing + m_itemWidth);
        }
        else {
            index = (y) / (m_itemSpacing + m_itemHeight); 
        }
        

   
        [self.delegate viewSlider:self selectIndex:index];
    }
    
    
}

#pragma mark - Layout
-(NSArray*) getVisibleViews {
    
    NSMutableArray* retVal = [[NSMutableArray alloc]init];
    NSArray* array  = [self.visiblePages allObjects];
    
    for (int i = 0 ; i < [self.visiblePages count];i++) {
        UIPagedViewItem* page = [array objectAtIndex:i];
        [retVal insertObject:page.view atIndex:i];
    }
    return retVal;
    
}

@end
