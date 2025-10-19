#import <Foundation/Foundation.h>

@interface RenderContext : NSObject
@property (nonatomic, strong) NSMutableArray<NSValue *> *linkRanges; // NSRange boxed
@property (nonatomic, strong) NSMutableArray<NSString *> *linkURLs;

- (instancetype)init;
- (void)registerLinkRange:(NSRange)range url:(NSString *)url;
@end


