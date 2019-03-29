// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSSerializableDocument.h"
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;

- (void)requestLocation;

@end

@interface SomeObject : NSObject <MSSerializableDocument>

@property(strong, nonatomic) NSString *key;

@end
