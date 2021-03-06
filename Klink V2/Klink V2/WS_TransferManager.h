//
//  WS_TransferManager.h
//  Test Project 2
//
//  Created by Bobby Gill on 6/24/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "BLLog.h"
#import "ServerManagedResource.h"
#import "AttributeNames.h"
#import "TypeNames.h"
#import "UrlManager.h"
#import "JSONKit.h"
#import "ASIFormDataRequest.h"
#import "CreateResponse.h"
#import "PutResponse.h"
#import "DataLayer.h"
#import "Attachment.h"
#import "SharingOptions.h"

@interface WS_TransferManager : NSObject {
        NSOperationQueue *putQueue;
}

@property (nonatomic,retain) NSOperationQueue *putQueue;
+ (WS_TransferManager*)getInstance;
- (id)init;

- (void) shareCaptionViaCloud:(NSNumber*)captionid
        withOptions:(SharingOptions*)sharingOptions;

- (void) updateAuthenticatorInCloud:
        (NSString*)twitterID
        withToken:(NSString*)twitterAccessToken
  withTokenSecret:(NSString*)twitterAccessTokenSecret
        withExpiry:(NSString*)twitterTokenExpiryDate
        onFinishNotify:(NSString*)notificationID;

- (void) updateObjectInCloud:
        (NSNumber*)objectid 
        withObjectType:(NSString*)objectType;

- (void) createObjectsInCloud:
        (NSArray*)objectids 
        withObjectTypes:(NSArray*)objectTypes 
        withAttachments:(NSArray*)attachments
        useProgressView:(UIProgressView*)progressView
        onFinishNotify:(NSString*)notificationID;

- (void) createObjectsInCloud:
            (NSArray*)objectids 
              withObjectTypes:(NSArray*)objectTypes 
              withAttachments:(NSArray*)attachments
               onFinishNotify:(NSString*)notificationID;


- (void) createObjectInCloud:
            (NSNumber*)objectid
            withObjectType:(NSString*)objecttype
              onFinishNotify:(NSString*)notificationID;

- (void) createObjectInCloud:
        (NSNumber*) objectid 
        withObjectType:(NSString*)objecttype 
        withAttachmentFor:(NSString*)attributeName 
        atFileLocation:(NSString*)path;


- (void) deleteObjectInCloud:(NSNumber*)objectid withObjectType:(NSString*)objectType;

- (void) updateAttributeInCloud:
                    (NSNumber*)objectid 
                    withObjectType:(NSString*)objectType 
                   forAttribute:(NSString*)attributeName 
                        byValue:(NSString*)value 
                 onFinishNotify:(NSString*)notificationID;

- (void) uploadAttachementToCloud:
        (NSNumber*)objectid 
        withObjectType:(NSString*)objectType 
        forAttributeName:(NSString*)attributeName 
        atFileLocation:(NSString*)path
        onFinishNotify:(NSString*)notificationID;




@end
