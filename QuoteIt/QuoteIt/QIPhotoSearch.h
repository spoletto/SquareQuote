//
//  QIPhotoSearch.h
//  QuoteIt
//
//  Created by Stephen Poletto on 2/19/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "KTThumbsViewController.h"
#import "QIChooseQuotePhoto.h"

@interface QIPhotoSearch : KTThumbsViewController <KTPhotoBrowserDataSource, UISearchBarDelegate> {
    NSURL *mostRecentPhotoSearchURL;
    BOOL inSearchMode;
    NSArray *images;
    NSString *priorSearchText;
    
    UIImageView *instructionsBackground;
    UILabel *instructionsLabel;
}

@property (assign, nonatomic) id <QIChoosePhotoDelegate> delegate;

@end
