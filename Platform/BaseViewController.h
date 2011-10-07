//
//  BaseViewController.h
//  Platform
//
//  Created by Bobby Gill on 10/7/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface BaseViewController : UIViewController {
    
}

@property (nonatomic, retain) NSManagedObjectContext*   managedObjectContext;

@end
