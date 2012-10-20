//
//  QITopQuotes.h
//  QuoteIt
//
//  Created by Stephen Poletto on 12/29/11.
//  Copyright (c) 2011 QuoteIt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QITopQuotes : UIViewController <UIScrollViewDelegate> {
    NSArray *buckets;
}

@property (retain, nonatomic) IBOutlet UIScrollView *bucketsScrollView;
@property (retain, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (retain, nonatomic) IBOutlet UIImageView *navBarShadow;

@end
