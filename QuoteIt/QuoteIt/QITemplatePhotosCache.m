//
//  QITemplatePhotosCache.m
//  QuoteIt
//
//  Created by Stephen Poletto on 2/20/12.
//  Copyright (c) 2012 QuoteIt. All rights reserved.
//

#import "QITemplatePhotosCache.h"
#import "QIUtilities.h"
#import "QIAFClient.h"

@implementation QITemplatePhotosCache

- (NSString *)persistedTemplatesPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"Templates.dat"];
}

- (void)persistTemplatesToDisk:(NSArray *)templates {
    [NSKeyedArchiver archiveRootObject:templates toFile:[self persistedTemplatesPath]];
}

- (NSArray *)loadPersistedTemplates {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self persistedTemplatesPath]];
}

- (void)prefetchImagesForTemplates {
    for (NSDictionary *template in templatePhotos) {
        [QIUtilities cacheImageAtURL:[NSURL URLWithString:[template objectForKey:@"src_small"]]];
        [QIUtilities cacheImageAtURL:[NSURL URLWithString:[template objectForKey:@"src_big"]]];
    }
}

- (void)requestTemplatePhotos {
    [[QIAFClient sharedClient] getPath:@"/api/image-templates" parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonObject) {
        if ([[jsonObject objectForKey:@"status"] isEqualToString:@"ok"]) {
            [templatePhotos release];
            templatePhotos = [[jsonObject objectForKey:@"results"] retain];
            [self prefetchImagesForTemplates];
            [self persistTemplatesToDisk:templatePhotos];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (![error code] == NSURLErrorNotConnectedToInternet) {
            TFLog(@"Failed to Fetch Template Images: %@", error);
        }
    }];
}

- (id)init {
    self = [super init];
    if (self) {
        templatePhotos = [[self loadPersistedTemplates] retain];
        [self requestTemplatePhotos];
    }
    return self;
}

+ (QITemplatePhotosCache *)sharedTemplatePhotosCache {
    static QITemplatePhotosCache *sharedCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

- (NSArray *)cachedTemplatePhotos {
    NSArray *staleTemplatePhotos = templatePhotos;
    [self requestTemplatePhotos];
    return staleTemplatePhotos;
}

@end
