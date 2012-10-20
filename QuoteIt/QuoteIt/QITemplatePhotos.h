//
//  QITemplatePhotos.h
//  QuoteIt
//
//  Created by Stephen Poletto on 2/19/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "KTThumbsViewController.h"
#import "QIChooseQuotePhoto.h"

@interface QITemplatePhotos : KTThumbsViewController <KTPhotoBrowserDataSource> {
    NSArray *images;
}

@property (assign, nonatomic) id <QIChoosePhotoDelegate> delegate;

@end
