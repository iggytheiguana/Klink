//
//  HomeViewController.m
//  Platform
//
//  Created by Bobby Gill on 10/28/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#import "HomeViewController.h"
#import "PageViewController.h"
#import "DraftViewController.h"
#import "ContributeViewController.h"
#import "CallbackResult.h"

#import "AuthenticationManager.h"
@implementation HomeViewController
@synthesize contributeButton    = m_contributeButton;
@synthesize newDraftButton      = m_newDraftButton;
@synthesize readButton          = m_readButton;
@synthesize loginButton         = m_loginButton;
@synthesize loginTwitterButton  = m_loginTwitterButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //let's refresh the feed
    [self.feedManager refreshFeedOnFinish:nil];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.authenticationManager isUserAuthenticated]) {
        [self.loginButton setTitle:@"Logoff" forState:UIControlStateNormal];
        [self.loginButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
        [self.loginButton addTarget:self action:@selector(onLogoffButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
        [self.loginButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
        [self.loginButton addTarget:self action:@selector(onLoginButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - System Event Handlers 
- (void) onUserLoggedIn:(CallbackResult*)result {
    [super onUserLoggedIn:result];
    
    [self.loginButton setTitle:@"Logoff" forState:UIControlStateNormal];
    [self.loginButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    [self.loginButton addTarget:self action:@selector(onLogoffButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) onUserLoggedOut:(CallbackResult*)result {
    [super onUserLoggedOut:result];
    
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [self.loginButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    [self.loginButton addTarget:self action:@selector(onLoginButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark UI Event Handlers
- (IBAction) onReadButtonClicked:(id)sender {
    //called when the read button is pressed
    PageViewController* pageController = [[PageViewController alloc]initWithNibName:@"PageViewController" bundle:nil];
    
    //TODO: calculate the page ID which the view controller should open to
    NSNumber* pageID = [NSNumber numberWithInt:0];
    pageController.pageID = pageID;
    
    [self.navigationController pushViewController:pageController animated:YES];
    [pageController release];
    
}

- (IBAction) onContributeButtonClicked:(id)sender {
    //called when the contribute button is pressed
    DraftViewController* draftController = [[DraftViewController alloc]initWithNibName:@"DraftViewController" bundle:nil];
    
    //TODO: calculate the page ID which the view controller should open to
    NSNumber* pageID = [NSNumber numberWithInt:0];
    draftController.pageID = pageID;
    
    [self.navigationController pushViewController:draftController animated:YES];
    [draftController release];
}

- (IBAction) onNewDraftButtonClicked:(id)sender {
    //called when the new draft button is pressed
    ContributeViewController* contributeViewController = [[ContributeViewController alloc]initWithNibName:@"ContributeViewController" bundle:nil];
    contributeViewController.delegate = self;
    contributeViewController.configurationType = PAGE;
    
    UINavigationController* navigationController = [[UINavigationController alloc]initWithRootViewController:contributeViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navigationController animated:YES];
    
    [navigationController release];
    [contributeViewController release];
}

- (IBAction) onLoginButtonClicked:(id)sender {
    if (![self.authenticationManager isUserAuthenticated]) {
        //no user is logged in currently
        [self authenticate:YES withTwitter:NO onFinishSelector:NULL onTargetObject:nil withObject:nil];
        
    }
   }

- (IBAction) onLogoffButtonClicked:(id)sender {
    if ([self.authenticationManager isUserAuthenticated]) {
        [self.authenticationManager logoff];
    }
    
    
}

- (IBAction) onLoginTwitterButtonClicked:(id)sender {
    [self authenticate:NO withTwitter:YES onFinishSelector:NULL onTargetObject:nil withObject:nil];

}

#pragma mark - ConrtibuteViewControllerDelegate methods
- (void)onSubmitButtonPressed:(id)sender {
    
}

+ (HomeViewController*)createInstance {
    HomeViewController* homeViewController = [[HomeViewController alloc]initWithNibName:@"HomeViewController" bundle:nil];
    return homeViewController;
}

@end
