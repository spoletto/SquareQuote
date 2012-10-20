// PFPointer.h
// Copyright 2011 Parse, Inc. All rights reserved.

#import <Foundation/Foundation.h>

/*!
 A class that defines a pointer to a PFObject.
 */
@interface PFPointer : NSObject <NSCopying> {
    NSString *objectId;
    NSString *className;
}

/*!
 The object id.
 */
@property (readonly) NSString *objectId;

/*!
 The object's class name.
 */
@property (readonly) NSString *className;

- (id)proxyForJson;

/*!
 Initializes the object with a class name and object id.
 @param newClassName The class name.
 @param newObjectId The object id.
 */
- (id)initWithClassName:(NSString *)newClassName objectId:(NSString *)newObjectId;

/*!
 Helper function to create a pointer.
 @param newClassName The class name.
 @param newObjectId The object id.
 */
+ (PFPointer *)pointerWithClassName:(NSString *)newClassName objectId:(NSString *)newObjectId;

- (id)copyWithZone:(NSZone *)zone;

@end
