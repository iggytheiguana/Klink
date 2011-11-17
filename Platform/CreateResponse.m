//
//  CreateResponse.m
//  Test Project 2
//
//  Created by Bobby Gill on 6/25/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "CreateResponse.h"
#import "JSONKit.h"
#import "Resource.h"
@implementation CreateResponse
@synthesize createdResources;



- (id) initFromJSONDictionary:(NSDictionary*)jsonDictionary {
   
    
    self = [super initFromJSONDictionary:jsonDictionary]; 
    
    if (self != nil &&
        [self.didSucceed boolValue] == YES) {
        
        NSArray* jsonCreatedResource = [jsonDictionary valueForKey:CREATEDRESOURCES];
        NSMutableArray *newObjects = [[NSMutableArray alloc]initWithCapacity:[jsonCreatedResource count]];
        for (int i = 0; i < [jsonCreatedResource count];i++) {
            id obj = [jsonCreatedResource objectAtIndex:i];
            Resource *object = [Resource createInstanceOfTypeFromJSON:obj];
            [newObjects insertObject:object atIndex:i];
        }
        self.createdResources = newObjects;
        [newObjects release];
     
               
    }
    return self;
}

//this method will return the representation of a created resource
//within this response object whcih matches the specified parameters
-(Resource*) createdResourceWith:(NSNumber*)resourceid 
          withTargetResourceType:(NSString*)targetresourcetype 
{   
    Resource* retVal = nil;
    
    
    for (Resource* createdResource in self.createdResources) {
        if ([createdResource.objectid isEqualToNumber:resourceid] &&
            [createdResource.objecttype isEqualToString:targetresourcetype]) {
            
            //found a match
            retVal = createdResource;
            break;
        }
    }
    
    return retVal;
}


@end
