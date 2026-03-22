#import "ENRMStyleMergingConfig.h"

@implementation ENRMStyleMergingConfig

+ (instancetype)configWithConflicting:(NSSet<NSNumber *> *)conflicting blocking:(NSSet<NSNumber *> *)blocking
{
  ENRMStyleMergingConfig *config = [[ENRMStyleMergingConfig alloc] init];
  config.conflictingStyles = conflicting;
  config.blockingStyles = blocking;
  return config;
}

@end
