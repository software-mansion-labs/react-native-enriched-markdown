#import "HeaderConfig.h"

@implementation HeaderConfig

+ (instancetype)defaultConfig {
    HeaderConfig *config = [HeaderConfig new];
    config.scale = 2.0;  // Default scaling factor
    config.isBold = YES; // Headers are bold by default
    return config;
}

@end
