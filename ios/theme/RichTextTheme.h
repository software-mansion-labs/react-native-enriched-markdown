#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HeaderConfig.h"

@interface RichTextTheme : NSObject

@property (nonatomic, strong) UIFont *baseFont;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) HeaderConfig *headerConfig;

+ (instancetype)defaultTheme;

@end
