// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextV2.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSLogger.h"
#import "MSUserInformation.h"
#import "MSUtility.h"

/**
 * Storage key for history data.
 */
static NSString *const kMSAuthTokenHistoryKeyV2 = @"AuthTokenHistory";

/*
 * Length of accountId in home accountId.
 */
static NSUInteger const kMSAccountIdLengthInHomeAccount = 36;

/**
 * If the given number of seconds is left until the token expires, it indicates that it needs refreshing.
 */
static NSTimeInterval const kMSSecBeforeExpireToRefresh = 10 * 60;

/**
 * Singleton.
 */
static MSAuthTokenContextV2 *sharedInstance;
static dispatch_once_t onceToken;

// TODO: Remove V2 and replace old one. Expose static way to call methods instead of calling `sharedInstance`?
@implementation MSAuthTokenContextV2

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSAuthTokenContextV2 alloc] init];
    }
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _delegates = [NSHashTable new];
    NSData *data = [MS_USER_DEFAULTS objectForKey:kMSAuthTokenHistoryKeyV2];
    if (data != nil) {

      // TODO: Decrypt before assigning history.
      _authTokenHistory = (NSMutableArray *)[(NSObject *)[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
    }
    if (!_authTokenHistory) {
      _authTokenHistory = [NSMutableArray<MSAuthTokenHistoryInfo *> new];
    }
    NSUInteger count = [_authTokenHistory count];
    MSLogDebug([MSAppCenter logTag], @"%tu auth token(s) in the history.", count);

    NSDate *startTime = [NSDate date];
    MSAuthTokenHistoryInfo *lastObject = nil;
    if ([_authTokenHistory count] > 0) {
      [_authTokenHistory lastObject];
    }
    if (lastObject == nil) {
      _currentAuthTokenInfo = [[MSAuthTokenHistoryInfo alloc] initWithAuthToken:nil accountId:nil startTime:startTime expiresOn:nil];
      [_authTokenHistory addObject:_currentAuthTokenInfo];
    } else if (!lastObject.expiresOn && [startTime compare:(NSDate * __nonnull) lastObject.expiresOn] == NSOrderedAscending) {
      _currentAuthTokenInfo = [[MSAuthTokenHistoryInfo alloc] initWithAuthToken:nil
                                                                      accountId:nil
                                                                      startTime:startTime
                                                                      expiresOn:lastObject.expiresOn];
      lastObject.expiresOn = startTime;
      _currentAuthTokenInfo.temporary = YES;
      [_authTokenHistory addObject:_currentAuthTokenInfo];
    } else {
      _currentAuthTokenInfo = [[MSAuthTokenHistoryInfo alloc] initWithAuthToken:nil
                                                                      accountId:nil
                                                                      startTime:lastObject.expiresOn
                                                                      expiresOn:nil];
      [_authTokenHistory addObject:_currentAuthTokenInfo];
      [self persistAuthTokenHistory];
    }
  }
  return self;
}

+ (void)resetSharedInstance {
  onceToken = 0;
  sharedInstance = nil;
}

- (void)addDelegate:(id<MSAuthTokenContextDelegateV2>)delegate {
  @synchronized(self) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<MSAuthTokenContextDelegateV2>)delegate {
  @synchronized(self) {
    [self.delegates removeObject:delegate];
  }
}

- (void)start {
  @synchronized(self) {
    if (!self.currentAuthTokenInfo.temporary) {
      return;
    }
    NSDate *startTime = [NSDate date];
    MSAuthTokenHistoryInfo *lastObjectBeforeTemporary = nil;
    NSUInteger historyCount = [self.authTokenHistory count];

    // The history count always be more than 1. If it is less than or equal to 1, there is no temporary.
    lastObjectBeforeTemporary = [self.authTokenHistory objectAtIndex:historyCount - 2];
    lastObjectBeforeTemporary.expiresOn = self.currentAuthTokenInfo.expiresOn;
    if ([lastObjectBeforeTemporary.expiresOn compare:startTime] == NSOrderedAscending) {
      self.currentAuthTokenInfo.temporary = NO;
      [self persistAuthTokenHistory];
    } else {
      self.currentAuthTokenInfo = lastObjectBeforeTemporary;
      [self.authTokenHistory removeLastObject];
    }
  }
}

- (void)logEnqueued {
  @synchronized(self) {
    if (self.currentAuthTokenInfo.temporary) {
      self.currentAuthTokenInfo.temporary = NO;
      [self persistAuthTokenHistory];
    }
  }
}

- (void)setAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn {
  NSHashTable<id<MSAuthTokenContextDelegateV2>> *synchronizedDelegates = nil;
  BOOL newUser = NO;
  @synchronized(self) {
    newUser = ![self.currentAuthTokenInfo.accountId ?: @"" isEqualToString:accountId ?: @""];
    NSDate *startTime = [NSDate date];
    if (newUser) {
      if (self.currentAuthTokenInfo.expiresOn == nil || [self.currentAuthTokenInfo.expiresOn compare:startTime] != NSOrderedAscending) {
        self.currentAuthTokenInfo.expiresOn = startTime;
      }
      self.currentAuthTokenInfo = [[MSAuthTokenHistoryInfo alloc] initWithAuthToken:authToken
                                                                          accountId:accountId
                                                                          startTime:startTime
                                                                          expiresOn:expiresOn];
      [self.authTokenHistory addObject:self.currentAuthTokenInfo];
      MSLogVerbose([MSAppCenter logTag], @"Stored new auth token, startTime: %@, expiresOn: %@.", self.currentAuthTokenInfo.startTime,
                   self.currentAuthTokenInfo.expiresOn);
    } else {
      self.currentAuthTokenInfo.authToken = authToken;
      self.currentAuthTokenInfo.expiresOn = expiresOn;
      MSLogVerbose([MSAppCenter logTag], @"Updated current token, startTime: %@, expiresOn: %@.", self.currentAuthTokenInfo.startTime,
                   self.currentAuthTokenInfo.expiresOn);
    }
    if ([self.authTokenHistory count] > kMSMaxAuthTokenArraySize) {
      [self.authTokenHistory removeObjectAtIndex:0];
      MSLogVerbose([MSAppCenter logTag], @"Deleted oldest auth token from history due to full of history.");
    }
    [self persistAuthTokenHistory];
    synchronizedDelegates = self.delegates;
  }
  for (id<MSAuthTokenContextDelegateV2> delegate in synchronizedDelegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didUpdateAuthToken:)]) {
      [delegate authTokenContext:self didUpdateAuthToken:authToken];
    }
    if (newUser && [delegate respondsToSelector:@selector(authTokenContext:didUpdateUserInformation:)]) {
      MSUserInformation *userInfo = nil;
      if (accountId) {
        if ([accountId length] > kMSAccountIdLengthInHomeAccount) {
          accountId = [accountId substringToIndex:kMSAccountIdLengthInHomeAccount];
        }
        userInfo = [[MSUserInformation alloc] initWithAccountId:(NSString *)accountId];
      }
      [delegate authTokenContext:self didUpdateUserInformation:userInfo];
    }
  }
}

- (void)refreshCurrentAuthToken {
  NSHashTable<id<MSAuthTokenContextDelegateV2>> *synchronizedDelegates = nil;
  @synchronized(self) {
    synchronizedDelegates = self.delegates;
  }
  if ([self.currentAuthTokenInfo.expiresOn compare:[NSDate dateWithTimeIntervalSinceNow:-kMSSecBeforeExpireToRefresh]] ==
      NSOrderedDescending) {
    for (id<MSAuthTokenContextDelegateV2> delegate in synchronizedDelegates) {
      MSLogInfo([MSAppCenter logTag], @"The token needs to be refreshed.");
      if ([delegate respondsToSelector:@selector(authTokenContext:refreshAuthTokenForAccountId:)]) {
        [delegate authTokenContext:self refreshAuthTokenForAccountId:self.currentAuthTokenInfo.accountId];
      }
    }
  }
}

- (void)persistAuthTokenHistory {
  @synchronized(self) {

    // TODO: Encrypt before storing history.
    [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.authTokenHistory] forKey:kMSAuthTokenHistoryKeyV2];
  }
}

@end
