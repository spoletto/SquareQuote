//
//  QITemplatePhotosCache.h
//  QuoteIt
//
//  Created by Stephen Poletto on 2/20/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QITemplatePhotosCache : NSObject {
    NSArray *templatePhotos;
}

- (NSArray *)cachedTemplatePhotos;
+ (QITemplatePhotosCache *)sharedTemplatePhotosCache;

@end
