//
//  DraftViewController2.h
//  Platform
//
//  Created by Jordan Gurrieri on 12/6/11.
//  Copyright (c) 2011 Blue Label Solutions LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "EventManager.h"
#import "CloudEnumerator.h"
#import "EGORefreshTableHeaderView.h"

@interface DraftViewController : BaseViewController <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, EGORefreshTableHeaderDelegate, CloudEnumeratorDelegate> {
    NSNumber*               m_pageID;
    UIView*                 m_view;
    UILabel*                m_draftTitle;
    UITableView*            m_tbl_draftTableView;
    UITableViewCell*        m_draftTableViewCellLeft;
    CloudEnumerator*        m_cloudPhotoEnumerator;
    EGORefreshTableHeaderView* m_refreshHeader;
}

@property (nonatomic, retain) NSFetchedResultsController*    frc_photos;
@property (nonatomic, retain) NSNumber*                      pageID;
@property (nonatomic, retain) IBOutlet UILabel*              draftTitle;
@property (nonatomic, retain) IBOutlet UITableView*          tbl_draftTableView;
@property (nonatomic, retain) IBOutlet UITableViewCell*      draftTableViewCellLeft;
@property (nonatomic, retain) CloudEnumerator*               cloudPhotoEnumerator;
@property (nonatomic, retain) EGORefreshTableHeaderView*     refreshHeader;

+ (DraftViewController*)createInstanceWithPageID:(NSNumber*)pageID;

@end
