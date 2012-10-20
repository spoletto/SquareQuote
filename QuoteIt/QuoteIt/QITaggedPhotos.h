//
//  QITaggedPhotos.h
//  QuoteIt
//
//  Created by Stephen Poletto on 2/19/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "KTThumbsViewController.h"
#import "QIChooseQuotePhoto.h"
#import "QIFacebookConnect.h"

@interface QITaggedPhotos : KTThumbsViewController <KTPhotoBrowserDataSource, FBRequestDelegate> {
    FBRequest *taggedFQLQuery;
    FBRequest *profilePhotosFQLQuery;
    NSArray *taggedPhotos;
    NSArray *profilePhotos;
    
    NSArray *images;
    
    UIImageView *noDataImage;
    UIImageView *loadingImageView;
}

@property (assign, nonatomic) id <QIChoosePhotoDelegate> delegate;
@property (retain, nonatomic) NSDictionary *quoteSource;

@end
