//
//  QIBucketPhotosCache.h
//  QuoteIt
//
//  Created by Stephen Poletto on 2/21/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QIBucketPhotosCache : NSObject {
    NSArray *bucketPhotos;
    NSDate *lastFetchedFromServer;
}

- (NSArray *)cachedBucketPhotos;
+ (QIBucketPhotosCache *)sharedBucketPhotosCache;

@end
