// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpCall.h"
#import "MSAppCenterInternal.h"
#import "MSLogger.h"
#import <Foundation/Foundation.h>

@implementation MSHttpCall

- (instancetype)initWithUrl:(NSURL *)url
                     method:(NSString *)method
                    headers:(NSDictionary<NSString *, NSString *> *)headers
                       data:(NSData *)data
             retryIntervals:(NSArray *)retryIntervals
          completionHandler:(MSHttpRequestCompletionHandler)completionHandler {
  _url = url;
  _method = method;
  _headers = headers;
  _data = data;
  _retryIntervals = retryIntervals;
  _completionHandler = completionHandler;
  _retryCount = 0;
  return self;
}

- (BOOL)hasReachedMaxRetries {
  return self.retryCount >= (int)[self.retryIntervals count];
}

- (void)resetRetry {
  // TODO synchronize this
  if (self.timerSource) {
    dispatch_source_cancel(self.timerSource);
  }
  self.retryCount = 0;
}

- (void)startRetryTimerWithStatusCode:(NSUInteger)statusCode event:(dispatch_block_t)event {

  // Create queue.
  self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
  uint32_t millisecondsDelta = [self delayForRetryCount:self.retryCount];
  MSLogWarning([MSAppCenter logTag], @"Call attempt #%tu failed with status code: %tu, it will be retried in %d ms.", self.retryCount,
               statusCode, millisecondsDelta);
  uint64_t nanosecondsDelta = NSEC_PER_MSEC * millisecondsDelta;
  self.retryCount++;
  dispatch_source_set_timer(self.timerSource, dispatch_walltime(NULL, nanosecondsDelta), DISPATCH_TIME_FOREVER, 1ull * NSEC_PER_SEC);
  dispatch_source_set_event_handler(self.timerSource, event);
  dispatch_resume(self.timerSource);
}

- (uint32_t)delayForRetryCount:(NSUInteger)retryCount {

  // Create a random delay.
  uint32_t millisecondsDelay =
      (uint32_t)((NSEC_PER_SEC * [(NSNumber *)self.retryIntervals[retryCount] doubleValue] / 2.0) / (double)NSEC_PER_MSEC);
  millisecondsDelay += arc4random_uniform(millisecondsDelay);
  return millisecondsDelay;
}

@end