//
//  HomeViewController.h
//  Platform
//
//  Created by Bobby Gill on 10/28/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@class CloudEnumerator;
@interface HomeViewController : BaseViewController {
    UIButton*   m_readButton;
    UIButton*   m_contributeButton;
    UIButton*   m_loginButton;
    UIButton*   m_loginTwitterButton;
}

@property (nonatomic,retain) IBOutlet UIButton* readButton;
@property (nonatomic,retain) IBOutlet UIButton* contributeButton;
@property (nonatomic,retain) IBOutlet UIButton* loginButton;
@property (nonatomic,retain) IBOutlet UIButton* loginTwitterButton;

- (IBAction) onReadButtonClicked:(id)sender;
- (IBAction) onContributeButtonClicked:(id)sender;
- (IBAction) onLoginButtonClicked:(id)sender;

+ (HomeViewController*) createInstance;
@end
