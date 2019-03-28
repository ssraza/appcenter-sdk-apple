// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "AppCenterDataStorage.h"
#import "MSSerializableDocument.h"
NS_ASSUME_NONNULL_BEGIN

@interface UserSettings : NSObject<MSSerializableDocument>

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *color;


- (instancetype)initWithText:(NSString *)text
                       color:(NSString *)color;

@end

NS_ASSUME_NONNULL_END
