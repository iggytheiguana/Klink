//
//  CloudEnumerator.m
//  Klink V2
//
//  Created by Bobby Gill on 8/4/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "CloudEnumerator.h"
#import "NSStringGUIDCategory.h"

@implementation CloudEnumerator
@synthesize enumerationContext = m_enumerationContext;
@synthesize query = m_query;
@synthesize queryOptions = m_queryOptions;
@synthesize isDone = m_isDone;
@synthesize delegate = m_delegate;
@synthesize lastExecutedTime = m_lastExecutedTime;
@synthesize secondsBetweenConsecutiveSearches = m_secondsBetweenConsecutiveSearches;
@synthesize identifier = m_identifier;
@synthesize isLoading = m_isEnumerationPending;
- (id) initWithEnumerationContext:(EnumerationContext *)enumerationContext withQuery:(Query *)query withQueryOptions:(QueryOptions *)queryOptions {
    
    self = [super init];
    if (self != nil) {
        self.enumerationContext = enumerationContext;
        self.query = query;
        
        self.queryOptions = queryOptions;
        m_isEnumerationPending = NO;
    }
    
    return self;
}

- (id) initWithQuery:(Query *)query withQueryOptions:(QueryOptions *)queryOptions {
    
    self = [super init];
    if (self != nil) {
        self.enumerationContext = [[EnumerationContext alloc]init];
        self.query = query;
        self.queryOptions = queryOptions;
         m_isEnumerationPending = NO;
    }
    return self;
}

- (BOOL) hasEnoughTimeLapsedBetweenConsecutiveSearches {
    long secondsSinceLastSearch = 0;
    bool hasEnoughTimeLapsedBetweenConsecutiveSearches;
    
    hasEnoughTimeLapsedBetweenConsecutiveSearches = YES;
    NSDate* currentDate = [NSDate date];
    secondsSinceLastSearch = [currentDate timeIntervalSinceDate:self.lastExecutedTime];
    
    if (self.lastExecutedTime != nil) {
        if (secondsSinceLastSearch > self.secondsBetweenConsecutiveSearches) {
            hasEnoughTimeLapsedBetweenConsecutiveSearches = YES;
        }
        else {
            hasEnoughTimeLapsedBetweenConsecutiveSearches = NO;
        }
    }
    return hasEnoughTimeLapsedBetweenConsecutiveSearches;
}



- (void) enumerateNextPage {
    WS_EnumerationManager* enumerationManager = [WS_EnumerationManager getInstance];
    AuthenticationContext* authenticationContext = [[AuthenticationManager getInstance]getAuthenticationContext];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    BOOL hasEnoughTimeLapsedBetweenConsecutiveSearches = [self hasEnoughTimeLapsedBetweenConsecutiveSearches];
    
    if (!m_isEnumerationPending &&
        hasEnoughTimeLapsedBetweenConsecutiveSearches) {
        
        self.lastExecutedTime = [NSDate date];
        m_isEnumerationPending = YES;
        NSString* notificationID = [NSString GetGUID];    
        [notificationCenter addObserver:self selector:@selector(onEnumerateComplete:) name:notificationID object:nil];
        
        
        NSURL* url = [UrlManager getEnumerateURLForQuery:self.query withEnumerationContext:self.enumerationContext withAuthenticationContext:authenticationContext];
        [enumerationManager enumerate:url withQuery:self.query withEnumerationContext:self.enumerationContext onFinishNotify:notificationID shouldEnumerateSinglePage:YES];
    }
    
}


- (void) enumerateUntilEnd {
    WS_EnumerationManager* enumerationManager = [WS_EnumerationManager getInstance];
    AuthenticationContext* authenticationContext = [[AuthenticationManager getInstance]getAuthenticationContext];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    BOOL hasEnoughTimeLapsedBetweenConsecutiveSearches = [self hasEnoughTimeLapsedBetweenConsecutiveSearches];
    
   
       
    if (!m_isEnumerationPending &&
        hasEnoughTimeLapsedBetweenConsecutiveSearches) {
        
        self.lastExecutedTime = [NSDate date];
        m_isEnumerationPending = YES;
        NSString* notificationID = [NSString GetGUID];    
        [notificationCenter addObserver:self selector:@selector(onEnumerateComplete:) name:notificationID object:nil];
        
        
        NSURL* url = [UrlManager getEnumerateURLForQuery:self.query withEnumerationContext:self.enumerationContext withAuthenticationContext:authenticationContext];
        [enumerationManager enumerate:url withQuery:self.query withEnumerationContext:self.enumerationContext onFinishNotify:notificationID shouldEnumerateSinglePage:NO];
    }
}


- (void) onEnumerateComplete : (NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    if ([userInfo objectForKey:an_ENUMERATIONCONTEXT] != nil) {
        EnumerationContext* returnedContext = [userInfo objectForKey:an_ENUMERATIONCONTEXT];
        self.enumerationContext = returnedContext;
        self.isDone = [self.enumerationContext.isDone boolValue];
    }
    
    if (self.delegate != nil) {
        [self.delegate onEnumerateComplete];
    }
    m_isEnumerationPending = NO;
}

- (void) dealloc {
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
    
    [super dealloc];
}

#pragma mark - Static initializers

+ (CloudEnumerator*) enumeratorForFeeds:(NSNumber *)userid {
    Query* query = [Query queryFeedsForUser:userid];
    QueryOptions* queryOptions = [QueryOptions queryForFeedsForUser:userid];
    EnumerationContext* enumerationContext = [EnumerationContext contextForFeeds:userid];
    query.queryoptions = queryOptions;
    
    CloudEnumerator* enumerator = [[[CloudEnumerator alloc]initWithEnumerationContext:enumerationContext withQuery:query withQueryOptions:queryOptions]autorelease];
    enumerator.identifier = [userid stringValue];
    enumerator.secondsBetweenConsecutiveSearches = threshold_FEED_ENUMERATION_TIME_GAP;
    return enumerator;
}

+ (CloudEnumerator*) enumeratorForCaptions:(NSNumber*)photoid {
    
    Query* query = [Query queryCaptionsForPhoto:photoid];
    QueryOptions* queryOptions = [QueryOptions queryForCaptions:photoid];
    EnumerationContext* enumerationContext = [EnumerationContext contextForCaptions:photoid];
    query.queryoptions = queryOptions;
  
    CloudEnumerator* enumerator = [[[CloudEnumerator alloc]initWithEnumerationContext:enumerationContext withQuery:query withQueryOptions:queryOptions]autorelease];
    enumerator.identifier = [photoid stringValue];
    enumerator.secondsBetweenConsecutiveSearches = threshold_CAPTION_ENUMERATION_TIME_GAP;
    return enumerator;
    
}

+ (CloudEnumerator*) enumeratorForPhotos:(NSNumber*)themeid {
    Query* query = [Query queryPhotosWithTheme:themeid];
    QueryOptions* queryOptions = [QueryOptions queryForPhotosInTheme];
    EnumerationContext* enumerationContext = [EnumerationContext contextForPhotosInTheme:themeid];
    query.queryoptions = queryOptions;
    
    CloudEnumerator* enumerator = [[[CloudEnumerator alloc]initWithEnumerationContext:enumerationContext withQuery:query withQueryOptions:queryOptions]autorelease];
    enumerator.identifier = [themeid stringValue];
    enumerator.secondsBetweenConsecutiveSearches = threshold_PHOTO_ENUMERATION_TIME_GAP;
    return enumerator;
}

+ (CloudEnumerator*) enumeratorForThemes {
    Query* query = [Query queryThemes];
    QueryOptions* queryOptions = [QueryOptions queryForThemes];
    EnumerationContext* enumerationContext = [EnumerationContext contextForThemes];
    query.queryoptions = queryOptions;
    
    CloudEnumerator* enumerator = [[[CloudEnumerator alloc]initWithEnumerationContext:enumerationContext withQuery:query withQueryOptions:queryOptions]autorelease];
    enumerator.secondsBetweenConsecutiveSearches = threshold_THEME_ENUMERATION_TIME_GAP;
    return enumerator;
}


@end
