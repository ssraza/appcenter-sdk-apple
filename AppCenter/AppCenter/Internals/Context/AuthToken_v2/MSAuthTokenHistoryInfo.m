// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenHistoryInfo.h"

static NSString *const kMSAuthTokenKey = @"authTokenKey";
static NSString *const kMSAccountIdKey = @"accountIdKey";
static NSString *const kMSStartTimeKey = @"startTimeKey";
static NSString *const kMSExpiresOnKey = @"expiresOnKey";
static NSString *const kMSTemporaryKey = @"temporaryKey";

@implementation MSAuthTokenHistoryInfo

- (instancetype)initWithAuthToken:(nullable NSString *)authToken
                        accountId:(nullable NSString *)accountId
                        startTime:(nullable NSDate *)startTime
                        expiresOn:(nullable NSDate *)expiresOn {
  self = [super init];
  if (self) {
    _authToken = authToken;
    _accountId = accountId;
    _startTime = startTime;
    _expiresOn = expiresOn;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _authToken = [coder decodeObjectForKey:kMSAuthTokenKey];
    _accountId = [coder decodeObjectForKey:kMSAccountIdKey];
    _startTime = [coder decodeObjectForKey:kMSStartTimeKey];
    _expiresOn = [coder decodeObjectForKey:kMSExpiresOnKey];
    _temporary = [coder decodeBoolForKey:kMSTemporaryKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.authToken forKey:kMSAuthTokenKey];
  [coder encodeObject:self.accountId forKey:kMSAccountIdKey];
  [coder encodeObject:self.startTime forKey:kMSStartTimeKey];
  [coder encodeObject:self.expiresOn forKey:kMSExpiresOnKey];
  [coder encodeBool:self.temporary forKey:kMSTemporaryKey];
}

- (id)copyWithZone:(NSZone *)__unused zone {
  id copy = [[[self class] alloc] initWithAuthToken:self.authToken accountId:self.accountId startTime:self.startTime expiresOn:self.expiresOn];
  return copy;
}

@end
