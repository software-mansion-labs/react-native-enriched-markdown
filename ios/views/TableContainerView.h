#pragma once
#import "StyleConfig.h"
#import <UIKit/UIKit.h>

@class MarkdownASTNode;

NS_ASSUME_NONNULL_BEGIN

typedef void (^TableLinkPressBlock)(NSString *url);

@interface TableContainerView : UIView

- (instancetype)initWithConfig:(StyleConfig *)config;

- (void)applyTableNode:(MarkdownASTNode *)tableNode;

- (CGFloat)measureHeight:(CGFloat)maxWidth;

@property (nonatomic, strong) StyleConfig *config;

@property (nonatomic, assign) BOOL allowFontScaling;
@property (nonatomic, assign) CGFloat maxFontSizeMultiplier;

@property (nonatomic, copy, nullable) TableLinkPressBlock onLinkPress;
@property (nonatomic, copy, nullable) TableLinkPressBlock onLinkLongPress;

@property (nonatomic, assign) BOOL enableLinkPreview;

@end

NS_ASSUME_NONNULL_END
