#import "RichTextTheme.h"

@implementation RichTextTheme

+ (instancetype)defaultTheme {
    RichTextTheme *theme = [RichTextTheme new];
    theme.baseFont = [UIFont systemFontOfSize:16];  
    theme.textColor = [UIColor blackColor];
    theme.headerConfig = [HeaderConfig defaultConfig];
    return theme;
}

@end
