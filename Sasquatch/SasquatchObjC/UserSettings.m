// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "UserSettings.h"

@implementation UserSettings

- (instancetype)initWithText:(NSString *)text
                         color:(NSString *)color {
  
  if (self = [super init]) {
    _text = text;
    _color = color;
  }
  return self;
}

- (NSDictionary *)serializeToDictionary {
  return @{@"text" : _text ,
           @"color" : _color
           };
}

- (instancetype)initFromDictionary:(NSDictionary *)dictionary {
  if (self = [super init]) {
    _text = dictionary[@"text"];
    _color = dictionary[@"color"];
  }
  return self;
}

@end
