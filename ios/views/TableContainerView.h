#pragma once
#import "ENRMUIKit.h"
#import "StyleConfig.h"

@class MarkdownASTNode;

NS_ASSUME_NONNULL_BEGIN

typedef void (^TableLinkPressBlock)(NSString *url);
typedef void (^TableMentionPressBlock)(NSString *url, NSString *text);
typedef void (^TableCitationPressBlock)(NSString *url, NSString *text);

@interface TableContainerView : RCTUIView

- (instancetype)initWithConfig:(StyleConfig *)config;

- (void)applyTableNode:(MarkdownASTNode *)tableNode;

- (CGFloat)measureHeight:(CGFloat)maxWidth;

@property (nonatomic, strong) StyleConfig *config;

@property (nonatomic, assign) BOOL allowFontScaling;
@property (nonatomic, assign) CGFloat maxFontSizeMultiplier;

@property (nonatomic, copy, nullable) TableLinkPressBlock onLinkPress;
@property (nonatomic, copy, nullable) TableLinkPressBlock onLinkLongPress;
@property (nonatomic, copy, nullable) TableMentionPressBlock onMentionPress;
@property (nonatomic, copy, nullable) TableCitationPressBlock onCitationPress;

@property (nonatomic, assign) BOOL enableLinkPreview;

@end

NS_ASSUME_NONNULL_END
