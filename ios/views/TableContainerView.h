#pragma once
#import "StyleConfig.h"
#import <UIKit/UIKit.h>

@class MarkdownASTNode;

NS_ASSUME_NONNULL_BEGIN

/// Block called when a link is tapped inside a table cell.
typedef void (^TableLinkPressBlock)(NSString *url);

/**
 * Internal table view used by EnrichedMarkdown container.
 *
 * Renders a markdown table as a horizontally scrollable grid of cells.
 * Each cell is a UITextView with attributed text supporting bold, italic,
 * code, links, strikethrough, etc. via AttributedRenderer.
 * The grid auto-sizes column widths based on content.
 *
 * Not a Fabric component — managed entirely by EnrichedMarkdown.
 */
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
