//
//  UIPointsProgressBar.h
//  Platform
//
//  Created by Jordan Gurrieri on 5/18/12.
//  Copyright (c) 2012 Blue Label Solutions LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface UIPointsProgressBar : UIView {
    User*       m_user;
    NSNumber*   m_userID;
    
    UIView*     m_view;
    
    UILabel*    m_lbl_editorMinimumLabel;
    UILabel*    m_lbl_userBestLabel;
    UILabel*    m_lbl_numPoints;
    
    UIImageView* m_iv_progressBarContainer;
    UIImageView* m_iv_progressPoints;
    UIImageView* m_iv_editorMinimumLine;
    UIImageView* m_iv_userBestLine;
    
}

@property (atomic, retain) User*        user;
@property (atomic, retain) NSNumber*    userID;

@property (nonatomic, retain) IBOutlet UIView*  view;

@property (nonatomic, retain) IBOutlet UILabel* lbl_editorMinimumLabel;
@property (nonatomic, retain) IBOutlet UILabel* lbl_userBestLabel;
@property (nonatomic, retain) IBOutlet UILabel* lbl_numPoints;

@property (nonatomic, retain) IBOutlet UIImageView* iv_progressBarContainer;
@property (nonatomic, retain) IBOutlet UIImageView* iv_progressPoints;
@property (nonatomic, retain) IBOutlet UIImageView* iv_editorMinimumLine;
@property (nonatomic, retain) IBOutlet UIImageView* iv_userBestLine;

- (void) renderProgressBarForUserWithID:(NSNumber *)userID;

@end
