// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

typedef void (^MSHttpRequestCompletionHandler)(NSData *responseBody, NSHTTPURLResponse *response, NSError *error);

@protocol MSHttpClientProtocol

@required

/**
 * Make an HTTP call.
 *
 * @param url The endpoint to use in the HTTP request.
 * @param method The HTTP method (verb) to use for the HTTP request (e.g. GET, POST, etc.).
 * @param headers HTTP headers.
 * @param data A data instance that will be transformed request body.
 * @param handler Completion handler.
 */
- (void)sendAsync:(NSURL *)url
               method:(NSString *)method
              headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                 data:(nullable NSData *)data
    completionHandler:(MSHttpRequestCompletionHandler)handler;

@end
