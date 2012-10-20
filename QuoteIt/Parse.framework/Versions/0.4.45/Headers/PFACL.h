//  PFACL.h
//  Copyright 2011 Parse, Inc. All rights reserved.

#import <Foundation/Foundation.h>

@class PFUser;

/*!
 The PFACL is an access control list that can apply to a PFObject. The PFACL determines which users have
 read and write permissions to the object.
 */
@interface PFACL : NSObject <NSCopying> {
    NSMutableDictionary *permissionsById;    
}

/*!
 Creates an ACL with no permissions granted.
 */
+ (PFACL *)ACL;

/*!
 Creates an ACL where only the provided user has access.
 */
+ (PFACL *)ACLWithUser:(PFUser *)user;

/*!
 Set whether the public is allowed to read this object.
 */
- (void)setPublicReadAccess:(BOOL)allowed;

/*!
 Gets whether the public is allowed to read this object.
 */
- (BOOL)getPublicReadAccess;

/*!
 Set whether the public is allowed to write this object.
 */
- (void)setPublicWriteAccess:(BOOL)allowed;

/*!
 Gets whether the public is allowed to write this object.
 */
- (BOOL)getPublicWriteAccess;

/*!
 Set whether the given user id is allowed to read this object.
 */
- (void)setReadAccess:(BOOL)allowed forUserId:(NSString *)userId;

/*!
 Gets whether the given user id is *explicitly* allowed to read this object.
 Even if this returns NO, the user may still be able to access it if getPublicReadAccess returns YES.
 */
- (BOOL)getReadAccessForUserId:(NSString *)userId;

/*!
 Set whether the given user id is allowed to write this object.
 */
- (void)setWriteAccess:(BOOL)allowed forUserId:(NSString *)userId;

/*!
 Gets whether the given user id is *explicitly* allowed to write this object.
 Even if this returns NO, the user may still be able to write it if getPublicWriteAccess returns YES.
 */
- (BOOL)getWriteAccessForUserId:(NSString *)userId;

/*!
 Set whether the given user is allowed to read this object.
 */
- (void)setReadAccess:(BOOL)allowed forUser:(PFUser *)user;

/*!
 Gets whether the given user is *explicitly* allowed to read this object.
 Even if this returns NO, the user may still be able to access it if getPublicReadAccess returns YES.
 */
- (BOOL)getReadAccessForUser:(PFUser *)user;

/*!
 Set whether the given user is allowed to write this object.
 */
- (void)setWriteAccess:(BOOL)allowed forUser:(PFUser *)user;

/*!
 Gets whether the given user is *explicitly* allowed to write this object.
 Even if this returns NO, the user may still be able to write it if getPublicWriteAccess returns YES.
 */
- (BOOL)getWriteAccessForUser:(PFUser *)user;

@end
