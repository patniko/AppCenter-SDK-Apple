#import "MSOneCollectorChannelDelegatePrivate.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"

static NSString *const kMSOneCollectorGroupIdSuffix = @"/one";

@implementation MSOneCollectorChannelDelegate

- (id)init {
  self = [super init];
  if (self) {
    _oneCollectorChannels = [NSMutableDictionary new];
  }

  return self;
}

- (void)channelGroup:(id<MSChannelGroupProtocol>)channelGroup didAddChannelUnit:(id<MSChannelUnitProtocol>)channel {

  // Add OneCollector group based on the given channel's group id.
  NSString *groupId = channel.configuration.groupId;
  if (![self isOneCollectorGroup:groupId]) {
    NSString *oneCollectorGroupId =
        [NSString stringWithFormat:@"%@%@", channel.configuration.groupId, kMSOneCollectorGroupIdSuffix];
    MSChannelUnitConfiguration *channelUnitConfiguration =
        [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:oneCollectorGroupId];
    id<MSChannelUnitProtocol> channelUnit = [channelGroup addChannelUnitWithConfiguration:channelUnitConfiguration];
    self.oneCollectorChannels[groupId] = channelUnit;
  }
}

- (BOOL)shouldFilterLog:(id<MSLog>)log {
  (void)log;
  return NO;
}

- (void)channel:(id<MSChannelUnitProtocol>)channel didEnqueueLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (void)log;
  (void)internalId;
  (void)channel;
}

- (BOOL)isOneCollectorGroup:(NSString *)groupId {
  return [groupId hasSuffix:kMSOneCollectorGroupIdSuffix];
}

@end
