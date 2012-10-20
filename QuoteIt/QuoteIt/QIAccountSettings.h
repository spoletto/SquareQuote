//
//  QIAccountSettings.h
//  QuoteIt
//
//  Created by Stephen Poletto on 2/27/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QIAccountSettings : UIViewController

@property (retain, nonatomic) IBOutlet UITableView *settingsTableView;
@property (retain, nonatomic) IBOutlet UILabel *accountNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *signedInAsLabel;
@property (retain, nonatomic) IBOutlet UIButton *disconnectButton;

@end
