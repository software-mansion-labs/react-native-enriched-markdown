#pragma once
#import "StyleConfig.h"
#import <UIKit/UIKit.h>

@class RenderContext;
@class AccessibilityInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * Internal text segment view used by EnrichedMarkdown container.
 * Thin wrapper around UITextView that reuses the existing rendering pipeline.
 * Not a Fabric component — managed entirely by EnrichedMarkdown.
 */
@interface EnrichedMarkdownInternalText : UIView

- (instancetype)initWithConfig:(StyleConfig *)config;

- (void)applyAttributedText:(NSMutableAttributedString *)text context:(RenderContext *)context;

- (CGFloat)measureHeight:(CGFloat)maxWidth;

@property (nonatomic, readonly) UITextView *textView;

@property (nonatomic, strong, nullable) AccessibilityInfo *accessibilityInfo;

@property (nonatomic, strong) StyleConfig *config;

@property (nonatomic, assign) BOOL allowTrailingMargin;

@property (nonatomic, assign) CGFloat lastElementMarginBottom;

@end

NS_ASSUME_NONNULL_END
