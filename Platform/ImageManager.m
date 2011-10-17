//
//  ImageManager.m
//  Test Project 2
//
//  Created by Bobby Gill on 6/20/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "ImageManager.h"
#import "PlatformAppDelegate.h"

@implementation ImageManager
@synthesize imageCache;
@synthesize queue;
static  ImageManager* sharedManager;  

+ (ImageManager*) getInstance {
//    NSString* activityName = @"ImageManager.getInstance:";
    @synchronized(self)
    {
        if (!sharedManager) {
            sharedManager = [[ImageManager alloc]init];
        } 
//        [BLLog v:activityName withMessage:@"completed initialization"];
        return sharedManager;
    }
}

- (id)init{
    self.queue = [[NSOperationQueue alloc] init];
    self.imageCache = [[ASIDownloadCache alloc]init];
    PlatformAppDelegate *appDelegate = (PlatformAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.imageCache setStoragePath:[appDelegate getImageCacheStorageDirectory]];
    
    return self;
}

-(void)dealloc {
    [self.queue release];
    [self.imageCache release];
    [super dealloc];
}


- (id)downloadImage:(NSString*)url withUserInfo:(NSDictionary*)userInfo atCallback:(id<ImageDownloadCallback>)callback {
    //check to see if the url is a file reference or a url reference
    if ([NSURL isValidURL:url]) {
        //its a url
        return [self downloadImageFromURL:url withUserInfo:userInfo atCallback:callback];
        
    }
    else {
        //its a file
        return [self downloadImageFromFile:url withUserInfo:userInfo atCallback:callback];
    }
    
}


- (id)downloadImageFromFile:(NSString*) fileName withUserInfo:(NSDictionary*)userInfo atCallback:(id<ImageDownloadCallback>)callback{
         
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:fileName]) {
         UIImage* image = [UIImage imageWithContentsOfFile:fileName];
         return image;
    }
    else {
               // [BLLog e:activityName withMessage:message];
    }
    return nil;
}

- (id)downloadImageFromURL:(NSString*) url withUserInfo:(NSDictionary*)userInfo atCallback:(id<ImageDownloadCallback>)callback {

    NSURL *urlObject = [NSURL URLWithString:url];
    PlatformAppDelegate *appDelegate = (PlatformAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString* fileName = [urlObject lastPathComponent];
    NSString* directory = [appDelegate getImageCacheStorageDirectory];
    NSString* path = [NSString stringWithFormat:@"%@/%@",directory,fileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:path]) {

        UIImage* retVal = [UIImage imageWithContentsOfFile:path];
        return retVal;
    }
    
    if (callback != nil) {
        
        NSMutableDictionary *requestUserInfo = [NSMutableDictionary dictionaryWithCapacity:2];
        [requestUserInfo setValue:url forKey:@"url"];
        [requestUserInfo setValue:userInfo forKey:@"callbackdata"];
        [requestUserInfo setObject:callback forKey:@"callback"];
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:urlObject];    
        request.userInfo = requestUserInfo;
        request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
        request.delegate = self;
        request.timeOutSeconds = 5;
        [request setNumberOfTimesToRetryOnTimeout:3];
        
        request.downloadDestinationPath = path;
        request.downloadCache = imageCache;
        [request setDidFinishSelector:@selector(onImageDownloaded:)];
        [request setDidFailSelector:@selector(onImageDownloadFail:)] ;
        [self.queue addOperation:request];
    }
    return nil;
}

#pragma mark - ASIHTTPRequest Delegate Handlers
- (void)onImageDownloaded:(ASIHTTPRequest*)request {
   
    
    NSDictionary* requestUserInfo = request.userInfo;
  
    NSDictionary* callbackUserInfo = [requestUserInfo valueForKey:@"callbackdata"];
    
    id<ImageDownloadCallback> callback = [requestUserInfo objectForKey:@"callback"];
    
    NSString* downloadedImagePath = request.downloadDestinationPath;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:downloadedImagePath]) {
        UIImage* image = [UIImage imageWithContentsOfFile:downloadedImagePath];        
        [callback onImageDownload:image withUserInfo:callbackUserInfo];
    }
    else {        
       //TODO: log an image file path that doesn't exist
    }
}

- (void)onImageDownloadFail:(ASIHTTPRequest*)request {
    //TODO: log a message on image download fail
    
}



//Saves the picture on the hard disk in teh cache folder and returns the full path
- (NSString*)saveImage:(UIImage*)image withFileName:(NSString*)fileNameWithoutExtension {
    PlatformAppDelegate *appDelegate = (PlatformAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableString* path =[NSMutableString stringWithString:[appDelegate getImageCacheStorageDirectory]];
    
    [path appendFormat:@"/%@.jpg",fileNameWithoutExtension];
    
    [UIImageJPEGRepresentation(image, 1) writeToFile:path atomically:YES];
    return path;
}


@end
