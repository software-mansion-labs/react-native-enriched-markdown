#import "RenderContext.h"

@implementation RenderContext

- (instancetype)init {
    if (self = [super init]) {
        _linkRanges = [NSMutableArray array];
        _linkURLs = [NSMutableArray array];
    }
    return self;
}

- (void)registerLinkRange:(NSRange)range 
                      url:(NSString *)url {
    [self.linkRanges addObject:[NSValue valueWithRange:range]];
    [self.linkURLs addObject:url ?: @""];
}

@end


