//
//  Request.m
//  Platform
//
//  Created by Bobby Gill on 10/10/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "Request.h"
#import "Types.h"

@implementation Request
@synthesize onFailCallback      = m_onFailCallback;
@synthesize onSuccessCallback   = m_onSuccessCallback;
@synthesize userInfo            = m_userInfo;

@dynamic targetresourceid;
@dynamic operationcode;
@dynamic statuscode;
@dynamic url;
@dynamic changedattributes;
@dynamic targetresourcetype;

#define kDelimeter @","


#pragma initializers
- (id) initWithEntity:(NSEntityDescription*)entity insertIntoResourceContext:(ResourceContext*)resourceContext {
    self = [super initWithEntity:entity insertIntoManagedObjectContext:resourceContext.managedObjectContext];
    if (self) {
        self.statuscode = [NSNumber numberWithInt:kPENDING];

    }
    return self;
}
- (id) initFor:(NSNumber *)objectid
withTargetObjectType:(NSString*)objecttype
 withOperation:(int)opcode 
  withUserInfo:(NSDictionary *)userInfo 
     onSuccess:(Callback *)onSuccessCallback 
     onFailure:(Callback *)onFailureCallback {
   
    
    if (self) {
        //initialize the request to be pending
        self.statuscode = [NSNumber numberWithInt:kPENDING];
        self.targetresourcetype = objecttype;
        self.targetresourceid = objectid;
        self.operationcode = [NSNumber numberWithInt:opcode];
        self.onFailCallback = onFailureCallback;
        self.onSuccessCallback = onSuccessCallback;
        self.userInfo = userInfo;
    }
    return self;
}

- (NSArray*)changedAttributesList {
    return [self.changedattributes componentsSeparatedByString:kDelimeter];
}
- (void) setChangedAttributesList:(NSArray*)changedAttributeList {
    self.changedattributes =  @"";
    
    for (int i = 0; i < [changedAttributeList count]; i++) {
        self.changedattributes = [NSString stringWithFormat:@"%@%@",self.changedattributes,[changedAttributeList objectAtIndex:i]];
        
        if (i < [changedAttributeList count]-1) {
            self.changedattributes = [NSString stringWithFormat:@"%@%@",self.changedattributes,kDelimeter];
        }
    }
    

}

#pragma mark - Static Initializers

+ (id) createInstanceOfRequest {
    ResourceContext* resourceContext = [ResourceContext instance];
    NSEntityDescription* entity = [NSEntityDescription entityForName:REQUEST inManagedObjectContext:resourceContext.managedObjectContext];
    Request* retVal = [[Request alloc]initWithEntity:entity insertIntoResourceContext:nil];
    [retVal autorelease];
    return retVal;
}

+ (id) createAttachmentRequestFrom:(Request *)request {
    Request* newRequest = [Request createInstanceOfRequest];
    newRequest.onFailCallback = request.onFailCallback;
    newRequest.onSuccessCallback = request.onSuccessCallback;
    newRequest.operationcode =[NSNumber numberWithInt:kMODIFYATTACHMENT];
    newRequest.targetresourceid = request.targetresourceid;
    newRequest.targetresourcetype = request.targetresourcetype;
    newRequest.statuscode =[NSNumber numberWithInt:kPENDING];
    return newRequest;
    
}
@end
