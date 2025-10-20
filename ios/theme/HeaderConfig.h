#import <Foundation/Foundation.h>

@interface HeaderConfig : NSObject

@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) BOOL isBold;

+ (instancetype)defaultConfig;

@end
