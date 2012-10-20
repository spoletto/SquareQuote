//
//  QIBucketPhotosCache.m
//  QuoteIt
//
//  Created by Stephen Poletto on 2/21/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "QIBucketPhotosCache.h"
#import "QIUtilities.h"
#import "QIAFClient.h"

@implementation QIBucketPhotosCache

- (NSString *)persistedBucketsPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"Buckets.dat"];
}

- (void)persistBucketsToDisk:(NSArray *)buckets {
    [NSKeyedArchiver archiveRootObject:buckets toFile:[self persistedBucketsPath]];
}

- (NSArray *)loadPersistedBuckets {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self persistedBucketsPath]];
}

- (void)prefetchImages {
    for (NSInteger i = 0; i < [bucketPhotos count]; i++) {
        NSDictionary *bucket = [bucketPhotos objectAtIndex:i];
        NSString *bucketURL = [bucket objectForKey:@"image-iOS"];
        if ([[UIScreen mainScreen] scale] == 2.0f) {
            bucketURL = [bucket objectForKey:@"image-iOS-2x"];
        }
        NSURL *imgURL = [NSURL URLWithString:bucketURL relativeToURL:[[QIAFClient sharedClient] baseURL]];
        [QIUtilities cacheImageAtURL:imgURL];
    }
}

- (void)requestBucketPhotos {
    [[QIAFClient sharedClient] getPath:@"/api/list-buckets" parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        if ([[jsonObject objectForKey:@"status"] isEqualToString:@"ok"]) {
            [bucketPhotos release];
            bucketPhotos = [[jsonObject objectForKey:@"buckets"] retain];
            [self prefetchImages];
            [self persistBucketsToDisk:bucketPhotos];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (![error code] == NSURLErrorNotConnectedToInternet) {
            TFLog(@"Failed to Fetch Buckets: %@", error);
        }
    }];
}

- (id)init {
    self = [super init];
    if (self) {
        bucketPhotos = [[self loadPersistedBuckets] retain];
    }
    return self;
}

+ (QIBucketPhotosCache *)sharedBucketPhotosCache {
    static QIBucketPhotosCache *sharedCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

- (NSArray *)cachedBucketPhotos {
    NSArray *staleBucketPhotos = bucketPhotos;
    [self requestBucketPhotos];
    return staleBucketPhotos;
}

@end
