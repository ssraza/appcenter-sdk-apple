// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAuthTokenContextV2.h"
#import "MSAuthTokenHistoryInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAuthTokenContextV2 ()

/**
 * Reset singleton instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
