#import "HeadingStyle.h"

@implementation HeadingStyle {
    NSInteger _level;
    RichTextConfig *_config;
}

- (instancetype)initWithLevel:(NSInteger)level config:(RichTextConfig *)config {
    self = [super init];
    if (self) {
        _level = level;
        _config = config;
    }
    return self;
}

- (CGFloat)fontSize {
    switch (_level) {
        case 1: return [_config h1FontSize];
        case 2: return [_config h2FontSize];
        case 3: return [_config h3FontSize];
        case 4: return [_config h4FontSize];
        case 5: return [_config h5FontSize];
        // Future: Add H6 support
        // case 6: return [_config h6FontSize];
        default: return 32.0; // Default heading size
    }
}

- (NSString *)fontFamily {
    switch (_level) {
        case 1: return [_config h1FontFamily];
        case 2: return [_config h2FontFamily];
        case 3: return [_config h3FontFamily];
        case 4: return [_config h4FontFamily];
        case 5: return [_config h5FontFamily];
        // Future: Add H6 support
        // case 6: return [_config h6FontFamily];
        default: return nil;
    }
}

@end

