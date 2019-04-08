// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextDelegateV2.h"
#import "MSAuthTokenContextPrivateV2.h"
#import "MSAuthTokenContextV2.h"
#import "MSAuthTokenInfo.h"
#import "MSConstants+Internal.h"
#import "MSConstants.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUserInformation.h"
#import "MSUtility+File.h"

@interface MSAuthTokenContextTestsV2 : XCTestCase

@property(nonatomic) MSAuthTokenContextV2 *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) id utilityMock;
@property(nonatomic) id keychainUtilMock;

@end

@implementation MSAuthTokenContextTestsV2

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSAuthTokenContextV2 sharedInstance];
  self.settingsMock = [MSMockUserDefaults new];
  self.utilityMock = OCMClassMock([MSUtility class]);
  self.keychainUtilMock = [MSMockKeychainUtil new];
}

- (void)tearDown {
  [MSAuthTokenContextV2 resetSharedInstance];
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
  [self.keychainUtilMock stopMocking];
}

#pragma mark - Tests

- (void)testSetAuthToken {

  // TODO: Also want to verify storage.

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  id<MSAuthTokenContextDelegateV2> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegateV2));
  [self.sut addDelegate:delegateMock];
  NSDate *expiresOn = [self dateAfterAnHour];
  NSDate *now = [NSDate date];
  id dateMock = OCMClassMock([NSDate class]);
  OCMStub([dateMock date]).andReturn(now);

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:expiresOn];

  // Then
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.authToken, expectedAuthToken);
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.accountId, expectedAccountId);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].authToken, expectedAuthToken);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].accountId, expectedAccountId);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].startTime, now);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].expiresOn, expiresOn);
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId];
                  }]]);
  [dateMock stopMocking];
}

- (void)testSetAuthTokenWhenTokenIsEmpty {

  // TODO: Also want to verify storage.

  // If
  id<MSAuthTokenContextDelegateV2> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegateV2));
  [self.sut addDelegate:delegateMock];
  NSDate *expiresOn = [self dateAfterAnHour];
  NSDate *now = [NSDate date];
  id dateMock = OCMClassMock([NSDate class]);
  OCMStub([dateMock date]).andReturn(now);

  // When
  [self.sut setAuthToken:@"authToken1" withAccountId:@"account1" expiresOn:expiresOn];
  [self.sut setAuthToken:nil withAccountId:nil expiresOn:nil];

  // Then
  XCTAssertNil(self.sut.currentAuthTokenInfo.authToken);
  XCTAssertNil(self.sut.currentAuthTokenInfo.accountId);
  XCTAssertNil([self.sut.authTokenHistory lastObject].authToken);
  XCTAssertNil([self.sut.authTokenHistory lastObject].accountId);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].startTime, now);
  XCTAssertNil([self.sut.authTokenHistory lastObject].expiresOn);
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return ((MSUserInformation *)obj).accountId == nil;
                  }]]);
  [dateMock stopMocking];
}

- (void)testSetAuthTokenDoesNotTriggerNewUserOnSameAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  id<MSAuthTokenContextDelegateV2> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegateV2));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:[self dateAfterAnHour]];

  // Then
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.authToken, expectedAuthToken);
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.accountId, expectedAccountId);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].authToken, expectedAuthToken);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].accountId, expectedAccountId);
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId];
                  }]]);

  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:expectedAuthToken]);

  // If
  NSUInteger currentHistorySize = [self.sut.authTokenHistory count];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:[self dateAfterAnHour]];

  // Then
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.authToken, expectedAuthToken);
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.accountId, expectedAccountId);
  XCTAssertEqual(currentHistorySize, [self.sut.authTokenHistory count]);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].authToken, expectedAuthToken);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].accountId, expectedAccountId);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:expectedAuthToken]);
  OCMReject([delegateMock authTokenContext:self.sut didUpdateUserInformation:OCMOCK_ANY]);
}

- (void)testSetAuthTokenDoesTriggerNewUserOnNewAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAuthToken2 = @"authToken2";
  NSString *expectedAccountId = @"account1";
  NSString *expectedAccountId2 = @"account2";
  id<MSAuthTokenContextDelegateV2> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegateV2));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:[self dateAfterAnHour]];

  // Then
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.authToken, expectedAuthToken);
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.accountId, expectedAccountId);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].authToken, expectedAuthToken);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].accountId, expectedAccountId);
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId];
                  }]]);

  // If
  NSUInteger currentHistorySize = [self.sut.authTokenHistory count];

  // When
  [self.sut setAuthToken:expectedAuthToken2 withAccountId:expectedAccountId2 expiresOn:[self dateAfterAnHour]];

  // Then
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.authToken, expectedAuthToken2);
  XCTAssertEqualObjects(self.sut.currentAuthTokenInfo.accountId, expectedAccountId2);
  XCTAssertEqual(currentHistorySize + 1, [self.sut.authTokenHistory count]);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].authToken, expectedAuthToken2);
  XCTAssertEqualObjects([self.sut.authTokenHistory lastObject].accountId, expectedAccountId2);
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId2];
                  }]]);
}

- (void)testRemoveDelegate {

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegateV2));
  [self.sut addDelegate:delegateMock];

  // Then
  OCMReject([delegateMock authTokenContext:self.sut didUpdateUserInformation:OCMOCK_ANY]);

  // When
  [self.sut removeDelegate:delegateMock];
  [self.sut setAuthToken:@"some-token" withAccountId:@"someome" expiresOn:nil];

  // Then
  OCMVerifyAll(delegateMock);
}

- (void)testUpdatingExpiresOnForNewAccountId {

  // If
  NSString *expectedAuthToken1 = @"expectedAuthToken1";
  NSString *expectedAccountId1 = @"expectedAccountId1";
  NSString *expectedAuthToken2 = @"expectedAuthToken2";
  NSString *expectedAccountId2 = @"expectedAccountId2";
  NSString *expectedAuthToken3 = @"expectedAuthToken3";
  NSString *expectedAccountId3 = @"expectedAccountId3";
  NSUInteger count = [self.sut.authTokenHistory count];
  NSArray<NSDate *> *startTime = @[
    [NSDate dateWithTimeIntervalSince1970:0], [NSDate dateWithTimeIntervalSince1970:10000], [NSDate dateWithTimeIntervalSince1970:20000]
  ];
  NSArray<NSDate *> *expiresOn = @[
    [NSDate dateWithTimeIntervalSince1970:15000], [NSDate dateWithTimeIntervalSince1970:25000], [NSDate dateWithTimeIntervalSince1970:35000]
  ];

  // TODO: Date mock isn't working properly so this is a workaround.
  __block id dateMock = OCMClassMock([NSDate class]);
  __block NSUInteger i = 0;
  OCMStub([dateMock date]).andDo(^(NSInvocation *invocation) {
    NSDate *result = startTime[i++];
    [invocation setReturnValue:&result];
    if (i >= [startTime count]) {
      [dateMock stopMocking];
    }
  });

  // When
  [self.sut setAuthToken:expectedAuthToken1 withAccountId:expectedAccountId1 expiresOn:expiresOn[0]];
  [self.sut setAuthToken:expectedAuthToken2 withAccountId:expectedAccountId2 expiresOn:expiresOn[1]];
  [self.sut setAuthToken:expectedAuthToken3 withAccountId:expectedAccountId3 expiresOn:expiresOn[2]];

  // Then
  XCTAssertEqual(count + 3, [self.sut.authTokenHistory count]);
  MSAuthTokenHistoryInfo *lastObject = self.sut.authTokenHistory.lastObject;
  XCTAssertEqualObjects(expectedAuthToken3, lastObject.authToken);
  XCTAssertEqualObjects(expectedAccountId3, lastObject.accountId);
  XCTAssertEqualObjects(startTime[2], lastObject.startTime);
  XCTAssertEqualObjects(expiresOn[2], lastObject.expiresOn);

  MSAuthTokenHistoryInfo *secondObject = [self.sut.authTokenHistory objectAtIndex:[self.sut.authTokenHistory count] - 2];
  XCTAssertEqualObjects(expectedAuthToken2, secondObject.authToken);
  XCTAssertEqualObjects(expectedAccountId2, secondObject.accountId);
  XCTAssertEqualObjects(startTime[1], secondObject.startTime);
  XCTAssertEqualObjects(startTime[2], secondObject.expiresOn);

  MSAuthTokenHistoryInfo *firstObject = [self.sut.authTokenHistory objectAtIndex:[self.sut.authTokenHistory count] - 3];
  XCTAssertEqualObjects(expectedAuthToken1, firstObject.authToken);
  XCTAssertEqualObjects(expectedAccountId1, firstObject.accountId);
  XCTAssertEqualObjects(startTime[0], firstObject.startTime);
  XCTAssertEqualObjects(startTime[1], firstObject.expiresOn);

  [dateMock stopMocking];
}

- (void)testUpdatingExpiresOnForSameAccountId {

  // If
  NSString *expectedAuthToken = @"expectedAuthToken3";
  NSString *expectedAccountId = @"expectedAccountId";
  NSUInteger count = [self.sut.authTokenHistory count];
  NSArray<NSDate *> *startTime = @[
    [NSDate dateWithTimeIntervalSince1970:0], [NSDate dateWithTimeIntervalSince1970:10000], [NSDate dateWithTimeIntervalSince1970:20000]
  ];
  NSArray<NSDate *> *expiresOn = @[
    [NSDate dateWithTimeIntervalSince1970:15000], [NSDate dateWithTimeIntervalSince1970:25000], [NSDate dateWithTimeIntervalSince1970:35000]
  ];
  id dateMock = OCMClassMock([NSDate class]);
  NSUInteger i = 0;
  OCMStub([dateMock date]).andReturn(startTime[i++]);

  // When
  [self.sut setAuthToken:@"expectedAuthToken1" withAccountId:expectedAccountId expiresOn:expiresOn[0]];
  [self.sut setAuthToken:@"expectedAuthToken2" withAccountId:expectedAccountId expiresOn:expiresOn[1]];
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:expiresOn[2]];

  // Then
  XCTAssertEqual(count + 1, [self.sut.authTokenHistory count]);
  MSAuthTokenHistoryInfo *lastObject = self.sut.authTokenHistory.lastObject;
  XCTAssertEqualObjects(expectedAuthToken, lastObject.authToken);
  XCTAssertEqualObjects(expectedAccountId, lastObject.accountId);
  XCTAssertEqualObjects(startTime[0], lastObject.startTime);
  XCTAssertEqualObjects(expiresOn[2], lastObject.expiresOn);
  [dateMock stopMocking];
}

- (void)testUpdatingExpiresOnForSameAccountIdEvenThoughPreviousAuthTokenExpired {

  // If
  NSString *expectedAuthToken = @"expectedAuthToken3";
  NSString *expectedAccountId = @"expectedAccountId";
  NSUInteger count = [self.sut.authTokenHistory count];
  NSArray<NSDate *> *startTime = @[
    [NSDate dateWithTimeIntervalSince1970:0], [NSDate dateWithTimeIntervalSince1970:10000], [NSDate dateWithTimeIntervalSince1970:20000]
  ];
  NSArray<NSDate *> *expiresOn = @[
    [NSDate dateWithTimeIntervalSince1970:5000], [NSDate dateWithTimeIntervalSince1970:15000], [NSDate dateWithTimeIntervalSince1970:25000]
  ];
  id dateMock = OCMClassMock([NSDate class]);
  NSUInteger i = 0;
  OCMStub([dateMock date]).andReturn(startTime[i++]);

  // When
  [self.sut setAuthToken:@"expectedAuthToken1" withAccountId:expectedAccountId expiresOn:expiresOn[0]];
  [self.sut setAuthToken:@"expectedAuthToken2" withAccountId:expectedAccountId expiresOn:expiresOn[1]];
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:expiresOn[2]];

  // Then
  XCTAssertEqual(count + 1, [self.sut.authTokenHistory count]);
  MSAuthTokenHistoryInfo *lastObject = self.sut.authTokenHistory.lastObject;
  XCTAssertEqualObjects(expectedAuthToken, lastObject.authToken);
  XCTAssertEqualObjects(expectedAccountId, lastObject.accountId);
  XCTAssertEqualObjects(startTime[0], lastObject.startTime);
  XCTAssertEqualObjects(expiresOn[2], lastObject.expiresOn);
  [dateMock stopMocking];
}

- (void)testSaveAuthTokenLimitsHistorySize {

  // TODO: Also want to verify storage.

  // When
  for (int i = 0; i < kMSMaxAuthTokenArraySize; i++) {
    [self.sut setAuthToken:@"someToken" withAccountId:@"someAccountId" expiresOn:nil];
    [self.sut setAuthToken:nil withAccountId:nil expiresOn:nil];
  }

  // Then
  XCTAssertEqual([[MSAuthTokenContextV2 sharedInstance].authTokenHistory count], kMSMaxAuthTokenArraySize);
}

- (void)testNewLogWithIdentityRemovesTemporaryFlag {

  // TODO: Implement this unit test. This unit test requires to pre-configured history directly in history.
}

// TODO: Refresh isn't implemented yet. Enable unit tests after implementation.
//- (void)testCheckIfTokenNeedsToBeRefreshedTokenIsNotlastTokenEntry {
//  NSString *expectedAuthToken1 = @"authToken1";
//  NSString *expectedAccountId1 = @"account1";
//  NSString *expectedAuthToken2 = @"authToken2";
//  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
//  OCMReject([delegateMock authTokenContext:OCMOCK_ANY refreshAuthTokenForAccountId:OCMOCK_ANY]);
//  [self.sut addDelegate:delegateMock];
//
//  // When
//  [self.sut setAuthToken:expectedAuthToken1 withAccountId:expectedAccountId1 expiresOn:nil];
//  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken2 startTime:nil endTime:nil];
//  [self.sut checkIfTokenNeedsToBeRefreshed:authToken];
//}
//
//- (void)testCheckIfTokenNeedsToBeRefreshed {
//
//  // If
//  NSString *expectedAuthToken = @"authToken1";
//  NSString *expectedAccountId = @"account1";
//  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f))];
//  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:+(60.0f * 60.0f * 24.0f)];
//  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
//  [self.sut addDelegate:delegateMock];
//  OCMReject([delegateMock authTokenContext:OCMOCK_ANY refreshAuthTokenForAccountId:OCMOCK_ANY]);
//  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:expiresDate];
//  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
//                                                                                startTime:startDate
//                                                                                  endTime:expiresDate];
//
//  // When
//  [self.sut checkIfTokenNeedsToBeRefreshed:authToken];
//}
//
//- (void)testExpiresSoonTrue {
//
//  // If
//  NSString *expectedAuthToken = @"authToken1";
//  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f) * 2)];
//  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:-(60.0f * 60.0f * 24.0f)];
//  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
//                                                                                startTime:startDate
//                                                                                  endTime:expiresDate];
//
//  // When
//  bool *isExpiresSoon = [authToken expiresSoon];
//
//  // Then
//  XCTAssertTrue(isExpiresSoon);
//}
//
//- (void)testExpiresSoonFalse {
//
//  // If
//  NSString *expectedAuthToken = @"authToken1";
//  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f))];
//  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:+(60.0f * 60.0f * 24.0f)];
//  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
//                                                                                startTime:startDate
//                                                                                  endTime:expiresDate];
//
//  // When
//  bool *isExpiresSoon = [authToken expiresSoon];
//
//  // Then
//  XCTAssertFalse(isExpiresSoon);
//}
//
//- (void)testRefreshAuthTokenForAccountId {
//
//  // If
//  NSString *expectedAuthToken = @"authToken1";
//  NSString *expectedAccountId = @"account1";
//  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f) * 2)];
//  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:+500];
//  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
//  [self.sut addDelegate:delegateMock];
//  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:expiresDate];
//  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
//                                                                                startTime:startDate
//                                                                                  endTime:expiresDate];
//
//  // When
//  [self.sut checkIfTokenNeedsToBeRefreshed:authToken];
//
//  // Then
//  OCMVerify([delegateMock authTokenContext:OCMOCK_ANY refreshAuthTokenForAccountId:expectedAccountId]);
//}

// TODO: Any other cases to cover in the unit tests?

#pragma mark - Helper

- (NSDate *)dateAfterAnHour {
  NSDate *date = [NSDate date];
  return [date dateByAddingTimeInterval:(1 * 60 * 60)];
}

@end
