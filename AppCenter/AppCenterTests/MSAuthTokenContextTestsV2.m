// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextDelegateV2.h"
#import "MSAuthTokenContextPrivateV2.h"
#import "MSAuthTokenContextV2.h"
#import "MSAuthTokenInfo.h"
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
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId];
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

//- (void)testSaveAuthToken {
//
//  // If
//  NSString *expectedToken = @"someToken";
//  NSString *expectedAccount = @"someAccountData";
//
//  // When
//  [self.sut setAuthToken:expectedToken withAccountId:expectedAccount expiresOn:nil];
//  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSAuthTokenHistoryKey] lastObject];
//
//  // Then
//  XCTAssertEqual(actualAuthTokenInfo.authToken, expectedToken);
//  XCTAssertNotNil(actualAuthTokenInfo.startTime);
//  XCTAssertNil(actualAuthTokenInfo.expiresOn);
//  XCTAssertTrue([expectedAccount isEqualToString:actualAuthTokenInfo.accountId]);
//}
//
//- (void)testSaveAuthTokenWhenTokenIsEmpty {
//
//  // If
//  MSAuthTokenInfo *authTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:@"someToken"
//                                                                    accountId:@"someAccountId"
//                                                                    startTime:nil
//                                                                    expiresOn:nil];
//  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
//  [authTokenHistory addObject:authTokenInfo];
//  [MSMockKeychainUtil storeArray:authTokenHistory forKey:kMSAuthTokenHistoryKey];
//
//  // When
//  [self.sut setAuthToken:nil withAccountId:@"someNewAccountData" expiresOn:nil];
//  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSAuthTokenHistoryKey] lastObject];
//
//  // Then
//  XCTAssertNil(actualAuthTokenInfo.authToken);
//}
//
//- (void)testSaveAuthTokenWhenAccountIsEmpty {
//
//  // If
//  NSString *expectedToken = @"someNewToken";
//
//  // When
//  [self.sut setAuthToken:expectedToken withAccountId:nil expiresOn:nil];
//  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSAuthTokenHistoryKey] lastObject];
//
//  // Then
//  XCTAssertEqual(actualAuthTokenInfo.authToken, expectedToken);
//  XCTAssertNotNil(actualAuthTokenInfo.startTime);
//  XCTAssertNil(actualAuthTokenInfo.expiresOn);
//  XCTAssertNil(actualAuthTokenInfo.accountId);
//}
//
//- (void)testRetrieveAuthTokenReturnsLatestHistoryElement {
//
//  // If
//  NSString *expectedAuthToken = @"expectedAuthToken";
//  MSAuthTokenInfo *authTokenInfo1 = [[MSAuthTokenInfo alloc] initWithAuthToken:@"someAuthToken"
//                                                                     accountId:@"someAccountId"
//                                                                     startTime:nil
//                                                                     expiresOn:nil];
//  MSAuthTokenInfo *authTokenInfo2 = [[MSAuthTokenInfo alloc] initWithAuthToken:expectedAuthToken
//                                                                     accountId:@"someAccountId"
//                                                                     startTime:nil
//                                                                     expiresOn:nil];
//  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
//  [authTokenHistory addObject:authTokenInfo1];
//  [authTokenHistory addObject:authTokenInfo2];
//  [MSMockKeychainUtil storeArray:authTokenHistory forKey:kMSAuthTokenHistoryKey];
//
//  // When
//  NSString *actualAuthToken = [self.sut authToken];
//
//  // Then
//  XCTAssertTrue([actualAuthToken isEqualToString:expectedAuthToken]);
//}

- (void)testUpdatingExpiresOnForSameAccountId {

  // If
  NSString *expectedAuthToken = @"expectedAuthToken";
  NSUInteger count = [self.sut.authTokenHistory count];
  NSDate *dateAfterTwoHours = [[NSDate date] dateByAddingTimeInterval:(2 * 60 * 60)];

  // When
  [self.sut setAuthToken:@"unexpectedAuthToken1" withAccountId:@"someAccountId" expiresOn:[self dateAfterAnHour]];
  [self.sut setAuthToken:@"unexpectedAuthToken2" withAccountId:@"anotherAccountId" expiresOn:[self dateAfterAnHour]];
  [self.sut setAuthToken:@"unexpectedAuthToken3" withAccountId:@"anotherAccountId" expiresOn:[self dateAfterAnHour]];
  [self.sut setAuthToken:expectedAuthToken withAccountId:@"anotherAccountId" expiresOn:dateAfterTwoHours];

  // Then
  MSAuthTokenHistoryInfo *lastObject = self.sut.authTokenHistory.lastObject;
  XCTAssertEqual(count + 2, [self.sut.authTokenHistory count]);
  XCTAssertEqualObjects(dateAfterTwoHours, lastObject.expiresOn);
  XCTAssertEqualObjects(expectedAuthToken, lastObject.authToken);
}

//- (void)testRemoveAuthToken {
//
//  // If
//  NSString *tokenExpectedToBeDeleted = @"someAuthToken";
//  [self.sut setAuthToken:tokenExpectedToBeDeleted withAccountId:@"someAccountId" expiresOn:nil];
//  [self.sut setAuthToken:@"someNewAuthToken" withAccountId:@"anotherAccountId" expiresOn:nil];
//
//  // When
//  [self.sut removeAuthToken:nil];
//  [self.sut removeAuthToken:tokenExpectedToBeDeleted];
//  NSArray<MSAuthTokenInfo *> *actualAuthTokenArray = [self.sut authTokenHistory];
//
//  // Then
//  XCTAssertEqual(actualAuthTokenArray.count, 1);
//}
//
//- (void)testDoNotRemoveNotOldestAuthToken {
//
//  // If
//  NSString *tokenExpectedNotToBeDeleted = @"someAuthToken";
//  [self.sut setAuthToken:tokenExpectedNotToBeDeleted withAccountId:@"someAccountId" expiresOn:nil];
//
//  // When
//  [self.sut removeAuthToken:tokenExpectedNotToBeDeleted];
//  NSArray<MSAuthTokenInfo *> *actualAuthTokenArray = [self.sut authTokenHistory];
//
//  // Then
//  XCTAssertEqual(actualAuthTokenArray.count, 1);
//}
//
//- (void)testSaveAuthTokenLimitsHistorySize {
//
//  // If
//  NSString *accountId = @"someAccountId";
//
//  // When
//  for (int i = 0; i < kMSMaxAuthTokenArraySize; ++i) {
//    [self.sut setAuthToken:@"someToken" withAccountId:accountId expiresOn:nil];
//    [self.sut setAuthToken:nil withAccountId:accountId expiresOn:nil];
//  }
//  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSAuthTokenHistoryKey];
//
//  // Then
//  XCTAssertEqual([actualAuthTokensHistory count], kMSMaxAuthTokenArraySize);
//}
//
//- (void)testSaveAuthTokenAddsNewItemOnlyIfDiffersFromLatest {
//
//  // If
//  NSString *authToken = @"someToken";
//  NSString *authToken1 = @"someNewToken";
//  NSString *authToken2 = @"someNewNewToken";
//  NSString *accountId = @"someAccountId";
//
//  // When
//  for (int i = 0; i < 2; ++i) {
//    [self.sut setAuthToken:authToken withAccountId:accountId expiresOn:nil];
//  }
//  for (int i = 0; i < 2; ++i) {
//    [self.sut setAuthToken:authToken1 withAccountId:accountId expiresOn:nil];
//  }
//  for (int i = 0; i < 2; ++i) {
//    [self.sut setAuthToken:authToken2 withAccountId:accountId expiresOn:nil];
//  }
//  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSAuthTokenHistoryKey];
//  MSAuthTokenInfo *latestAuthTokenInfo = [actualAuthTokensHistory lastObject];
//
//  // Then
//  XCTAssertEqual([actualAuthTokensHistory count], 3);
//  XCTAssertEqual(latestAuthTokenInfo.authToken, authToken2);
//}
//
//- (void)testSaveAuthTokenFillsTheGap {
//
//  // If
//  NSString *authToken = @"someToken";
//  NSString *newAuthToken = @"someNewToken";
//  NSString *accountId = @"someAccountId";
//  NSString *newAccountId = @"someNewAccountId";
//  NSDate *expiryFirst = [NSDate dateWithTimeIntervalSince1970:1900];
//  NSDate *expirySecond = [NSDate dateWithTimeIntervalSinceNow:1000];
//
//  // When
//  [self.sut setAuthToken:authToken withAccountId:accountId expiresOn:expiryFirst];
//  [self.sut setAuthToken:newAuthToken withAccountId:newAccountId expiresOn:expirySecond];
//
//  // Then
//  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSAuthTokenHistoryKey];
//  MSAuthTokenInfo *latestAuthTokenInfo = actualAuthTokensHistory[1];
//  XCTAssertNil(latestAuthTokenInfo.authToken);
//}

- (void)testSaveAuthTokenExtendsStartTimeIfAccountTheSame {

  // If
  NSString *authToken = @"someToken";
  NSString *newAuthToken = @"someNewAuthToken";
  NSString *accountId = @"someAccountId";
  NSDate *now = [NSDate date];
  NSDate *expiryFirst = [NSDate dateWithTimeIntervalSinceNow:1000];
  NSDate *expirySecond = [NSDate dateWithTimeIntervalSinceNow:5000];
  id dateMock = OCMClassMock([NSDate class]);
  OCMStub([dateMock date]).andReturn(now);

  // When
  [self.sut setAuthToken:authToken withAccountId:accountId expiresOn:expiryFirst];
  [self.sut setAuthToken:newAuthToken withAccountId:accountId expiresOn:expirySecond];

  // Then
  XCTAssertTrue([[self.sut.authTokenHistory lastObject].startTime isEqualToDate:now]);
  XCTAssertTrue([[self.sut.authTokenHistory lastObject].expiresOn isEqualToDate:expirySecond]);
  [dateMock stopMocking];
}

#pragma mark - Helper

- (NSDate *)dateAfterAnHour {
  NSDate *date = [NSDate date];
  return [date dateByAddingTimeInterval:(1 * 60 * 60)];
}

@end
