//
//  QIAccountSettings.m
//  QuoteIt
//
//  Created by Stephen Poletto on 2/27/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "QIFacebookConnect.h"
#import "QICoreDataManager.h"
#import "QIAccountSettings.h"
#import "QILegalText.h"
#import "QIUtilities.h"

@implementation QIAccountSettings
@synthesize settingsTableView;
@synthesize accountNameLabel;
@synthesize signedInAsLabel;
@synthesize disconnectButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Account Settings";
        
        UIBarButtonItem *doneItem = [UIBarButtonItem barItemWithImage:[QIUtilities cancelButtonImage] highlightedImage:[QIUtilities cancelButtonPressed] title:@"Done" target:self action:@selector(dismissAccountSettings:)];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
    return self;
}

- (void)dismissAccountSettings:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.settingsTableView deselectRowAtIndexPath:[self.settingsTableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    QIRenderNavigationBarTitle();
    
    UIImageView *backgroundImage = [[UIImageView alloc] initWithFrame:self.view.frame];
    [backgroundImage setImage:[QIUtilities bookImage]];
    [self.view insertSubview:backgroundImage atIndex:0];
    [backgroundImage release];
    
    self.settingsTableView.backgroundView = nil;
    self.settingsTableView.backgroundColor = [UIColor clearColor];
    self.settingsTableView.scrollEnabled = NO;
    self.signedInAsLabel.textColor = [QIUtilities myQuotesSourceLabelColor];
    self.accountNameLabel.textColor = [QIUtilities myQuotesSourceLabelColor];
    self.accountNameLabel.text = QIFullNameForUser([[QICoreDataManager sharedDataManger] loggedInUser]);
    
    [self.disconnectButton setImage:[UIImage imageNamed:@"fb_disconnect_press"] forState:UIControlStateHighlighted];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"QIAccountSettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        cell.backgroundColor = [QIUtilities textEditorFontSelectorBackgroundColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [QIUtilities myQuotesSourceLabelColor];
        cell.textLabel.font = [UIFont fontWithName:@"Georgia" size:16.0];
    }
    
    NSString *cellLabel = nil;
    switch (indexPath.row) {
        case 0:
            cellLabel = @"About/FAQ";
            break;
        case 1:
            cellLabel = @"Terms of Service";
            break;
        case 2:
            cellLabel = @"Privacy Policy";
            break;
        default:
            break;
    }
    
    [[cell textLabel] setText:cellLabel];
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    QILegalText *legalText = [[QILegalText alloc] initWithNibName:@"QILegalText" bundle:nil];
    NSString *title = nil;
    NSString *url = nil;
    switch (indexPath.row) {
        case 0:
            title = @"About/FAQ";
            url = @"https://squarequote.it/legal/about.html";
            break;
        case 1:
            title = @"Terms of Service";
            url = @"https://squarequote.it/legal/tos.html";
            break;
        case 2:
            title = @"Privacy Policy";
            url = @"https://squarequote.it/legal/privacy.html";
            break;
        default:
            break;
    }
    legalText.title = title;
    legalText.urlToDisplay = url;
    [QIUtilities navigationController:self.navigationController animteWithPageCurlToViewController:legalText];
    [legalText release];
}

- (IBAction)disconnectFacebook:(id)sender {
    [[[QIFacebookConnect sharedFacebookConnect] facebook] logout];
}

- (void)dealloc {
    [settingsTableView release];
    [accountNameLabel release];
    [signedInAsLabel release];
    [disconnectButton release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setSettingsTableView:nil];
    [self setAccountNameLabel:nil];
    [self setSignedInAsLabel:nil];
    [self setDisconnectButton:nil];
    [super viewDidUnload];
}

@end
