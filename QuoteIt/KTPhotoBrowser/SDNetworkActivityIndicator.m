/*
 * This file is part of the SDNetworkActivityIndicator package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDNetworkActivityIndicator.h"
#import "RKRequestQueue.h"

static SDNetworkActivityIndicator *instance;

@implementation SDNetworkActivityIndicator

+ (id)sharedActivityIndicator
{
    if (instance == nil)
    {
        instance = [[SDNetworkActivityIndicator alloc] init];
    }

    return instance;
}

- (id)init
{
    if ((self = [super init]))
    {
        counter = 0;
    }

    return self;
}

- (void)startActivity
{
    [[UIApplication sharedApplication] pushNetworkActivity];
}

- (void)stopActivity
{
    [[UIApplication sharedApplication] popNetworkActivity];
}

- (void)stopAllActivity
{
    @synchronized(self)
    {
        counter = 0;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

@end
