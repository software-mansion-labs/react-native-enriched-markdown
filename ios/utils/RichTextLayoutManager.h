#pragma once
#import <UIKit/UIKit.h>
@class RichTextConfig;

@interface RichTextLayoutManager : NSLayoutManager

@property (nonatomic, strong) RichTextConfig *config;

@end

