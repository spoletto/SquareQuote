//
//  QISplashScreen.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBProgressHUD.h"

@interface QISplashScreen : UIViewController <MBProgressHUDDelegate> {
    MBProgressHUD *progressHUD;
    BOOL loginSuccessful;
}

@property (retain, nonatomic) IBOutlet UIButton *connectWithFBButton;

@end
