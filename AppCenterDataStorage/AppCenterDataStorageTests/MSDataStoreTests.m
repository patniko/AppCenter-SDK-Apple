// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSCosmosDb.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentWrapper.h"
#import "MSPage.h"
#import "MSSerializableDocument.h"
#import "MSTestFrameworks.h"
#import "MSTokenExchange.h"
#import "MSTokenResult.h"
#import "MSTokensResponse.h"
#import "MSUserIdContextPrivate.h"
#import "MSWriteOptions.h"
#import "MSPage.h"
#import "MSSerializableDocument.h"

/**
* Service storage key name.
*/
static NSString *const kMSServiceName = @"DataStorage";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupId = @"DataStorage";

/**
 * CosmosDb document timestamp key.
 */
static NSString *const kMSDocumentTimestampKey = @"_ts";

/**
 * CosmosDb document eTag key.
 */
static NSString *const kMSDocumentEtagKey = @"_etag";

/**
 * CosmosDb document key.
 */
static NSString *const kMSDocumentKey = @"document";

@interface MSDataStore (Test)

+ (instancetype)sharedInstance;

+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
               writeOptions:(MSWriteOptions *)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                       writeOptions:(MSWriteOptions *)__unused writeOptions
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler;
@end

@interface MSDataStoreTests : XCTestCase

@end

@interface MSFakeSerializableDocument: NSObject
- (instancetype)initFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)serializeToDictionary;
@end

@implementation MSFakeSerializableDocument: NSObject

- (NSDictionary *)serializeToDictionary {
    return [NSDictionary new];
}

- (instancetype)initFromDictionary:(NSDictionary *)dictionary{
    (self = [super init]);
    return self;
//    if ((self = [super init])) {
////        _deserializedValue = dictionary["deserializedValue"];
////        _partition = dictionary["partition"];
////        _documentId = dictionary["documentId"];
////        _eTag = dictionary"[eTag]";
////        _lastUpdatedDate = dictionary["lastUpdatedDate"];
//    }
//    return self;
}

@end

@implementation MSDataStoreTests


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCreateWithPartitionWithoutWriteOptionsGoldenTest {
    
    // If
    NSString *partition = @"partition";
    NSString *documentId = @"documentId";
    NSString *httpMethod = @"POST";
    NSData *body = nil;
    NSDictionary *additionalHeaders = nil;
    id mockSerializableDocument = [MSFakeSerializableDocument new];
//    OCMStub([mockSerializableDocument serializeToDictionary]).andReturn([NSDictionary new]);
//    OCMStub([mockSerializableDocument initFromDictionary:OCMOCK_ANY]).andReturn([MSDocumentWrapper class]);
    
    // Mock tokens fetching.
    MSTokensResponse *testTokensResponse = [[MSTokensResponse alloc] initWithTokens:@ [[MSTokenResult new]]];
    id tokenExchangeMock = OCMClassMock([MSTokenExchange class]);
    OCMStub([tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY partition:OCMOCK_ANY completionHandler:OCMOCK_ANY])
    .andDo(^(NSInvocation *invocation) {
        MSGetTokenAsyncCompletionHandler getTokenCallback;
        [invocation retainArguments];
        [invocation getArgument:&getTokenCallback atIndex:4];
        getTokenCallback(testTokensResponse, nil);
    });
    
    // Mock CosmosDB requests.
    NSDictionary *dic = @{kMSDocumentKey:@{}, kMSDocumentTimestampKey:@1, kMSDocumentEtagKey:@""};
    
    __block NSData *testResponse = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    
    id mockMSCosmosDb = OCMClassMock([MSCosmosDb class]);
    OCMStub([mockMSCosmosDb
             performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
             tokenResult:OCMOCK_ANY
             documentId:OCMOCK_ANY
             httpMethod:OCMOCK_ANY
             body:OCMOCK_ANY // we need to double check what body is allowed here, defined as nil for now
             additionalHeaders:OCMOCK_ANY // the same for headers, but we have a reference here and need
             // to check values using [OCMArg checkWithBlock]
             completionHandler:OCMOCK_ANY])
    .andDo(^(NSInvocation *invocation) {
        MSCosmosDbCompletionHandler cosmosdbOperationCallback;
        [invocation retainArguments];
        [invocation getArgument:&cosmosdbOperationCallback atIndex:8];
        cosmosdbOperationCallback(testResponse, nil);
    });
    
//     __weak BOOL completionHandlerCalled = NO;
     __weak XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
    
    // When
    [MSDataStore createWithPartition:partition documentId:documentId document:mockSerializableDocument completionHandler:^(MSDocumentWrapper *data) {
//        completionHandlerCalled = YES;
        [completeExpectation fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:5
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail(@"Expectation Failed with error: %@", error);
                                     }
                                 }];
    XCTAssertTrue(completeExpectation);
}

- (void)testCreateWithPartitionWithWriteOptionsGoldenTest {
    
    // If
    NSString *partition = @"partition";
    NSString *documentId = @"documentId";
    MSWriteOptions *options = [MSWriteOptions new];
    
    id mockSerializableDocument = OCMProtocolMock(@protocol(MSSerializableDocument));
    OCMStub([mockSerializableDocument serializeToDictionary]).andReturn([NSDictionary new]);
    
    __block BOOL completionHandlerCalled = NO;
    XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
    MSDocumentWrapperCompletionHandler completionHandler = ^(MSDocumentWrapper *data) {
        completionHandlerCalled = YES;
        [completionHandler fulfill];
    };
    
    // When
    [MSDataStore createWithPartition:partition
                          documentId:documentId
                            document:mockSerializableDocument
                        writeOptions:options
                   completionHandler:completionHandler];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    // Then
    XCTAssertTrue([completeExpectation assertForOverFulfill]);
    XCTAssertTrue(completionHandlerCalled);
}

- (void)testDeleteDocumentWithPartitionWithoutWriteOptions {
    
    // If
    NSString *partition = @"partition";
    NSString *documentId = @"documentId";
    
    __block BOOL completionHandlerCalled = NO;
    XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
    MSDataSourceErrorCompletionHandler completionHandler = ^(MSDataSourceError *error) {
        completionHandlerCalled = YES;
        [completionHandler fulfill];
    };
    
    // When
    [MSDataStore deleteDocumentWithPartition:partition documentId:documentId completionHandler:completionHandler];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    // Then
    XCTAssertTrue([completeExpectation assertForOverFulfill]);
    XCTAssertTrue(completionHandlerCalled);
}

- (void)testDeleteDocumentWithPartitionWithWriteOptions {
    
    // If
    NSString *partition = @"partition";
    NSString *documentId = @"documentId";
    MSWriteOptions *options = [MSWriteOptions new];
    
    __block BOOL completionHandlerCalled = NO;
    XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
    MSDataSourceErrorCompletionHandler completionHandler = ^(MSDataSourceError *error) {
        completionHandlerCalled = YES;
        [completionHandler fulfill];
    };
    
    // When
    [MSDataStore deleteDocumentWithPartition:partition documentId:documentId writeOptions:options completionHandler:completionHandler];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    // Then
    XCTAssertTrue([completeExpectation assertForOverFulfill]);
    XCTAssertTrue(completionHandlerCalled);
}
@end
