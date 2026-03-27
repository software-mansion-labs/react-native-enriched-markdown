#import "EnrichedMarkdownInternalText.h"
#import "AccessibilityInfo.h"
#import "ENRMContextMenuTextView+macOS.h"
#import "ENRMUIKit.h"
#import "LastElementUtils.h"
#import "MarkdownAccessibilityElementBuilder.h"
#import "RenderContext.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"
#import "TextViewLayoutManager.h"
#import <React/RCTUtils.h>
#include <TargetConditionals.h>
#import <objc/runtime.h>

@implementation EnrichedMarkdownInternalText {
  ENRMPlatformTextView *_textView;
#if !TARGET_OS_OSX
  NSMutableArray<UIAccessibilityElement *> *_accessibilityElements;
#else
  NSMutableArray *_accessibilityElements;
#endif
  BOOL _accessibilityNeedsRebuild;
}

@synthesize textView = _textView;

- (instancetype)initWithConfig:(StyleConfig *)config
{
  if (self = [super init]) {
    _config = config;
    _allowTrailingMargin = NO;
    _lastElementMarginBottom = 0;
    [self setupTextView];
  }
  return self;
}

- (void)setupTextView
{
#if !TARGET_OS_OSX
  _textView = [[ENRMPlatformTextView alloc] init];
  _textView.text = @"";
#else
  _textView = [[ENRMContextMenuTextView alloc] init];
  _textView.string = @"";
#endif
  ENRMConfigureMarkdownTextView(_textView);

  [self addSubview:_textView];

  [self setupLayoutManager];
}

- (void)setupLayoutManager
{
  NSLayoutManager *layoutManager = _textView.layoutManager;
  if (layoutManager != nil) {
    layoutManager.allowsNonContiguousLayout = NO;
    object_setClass(layoutManager, [TextViewLayoutManager class]);
    if (_config != nil) {
      [layoutManager setValue:_config forKey:@"config"];
    }
  }
}

- (void)applyAttributedText:(NSMutableAttributedString *)text context:(RenderContext *)context
{
  [context applyLinkAttributesToString:text];

  NSLayoutManager *layoutManager = _textView.layoutManager;
  if ([layoutManager isKindOfClass:[TextViewLayoutManager class]]) {
    [layoutManager setValue:_config forKey:@"config"];
  }

  objc_setAssociatedObject(_textView.textContainer, kTextViewKey, _textView, OBJC_ASSOCIATION_ASSIGN);

  _accessibilityElements = nil;
  _accessibilityNeedsRebuild = YES;

  ENRMSetAttributedText(_textView, text);

  [_textView.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, text.length) actualCharacterRange:NULL];

#if !TARGET_OS_OSX
  [_textView setNeedsLayout];
#endif
  ENRMSetNeedsDisplay(_textView);
}

- (CGFloat)measureHeight:(CGFloat)maxWidth
{
  return [self measureSize:maxWidth].height;
}

- (CGSize)measureSize:(CGFloat)maxWidth
{
  NSAttributedString *text = ENRMGetAttributedText(_textView);
  if (text.length == 0) {
    return CGSizeZero;
  }

  ENRMTextLayoutResult layout = ENRMMeasureTextLayout(_textView, maxWidth);

  CGFloat measuredHeight = layout.usedRect.size.height;
  CGFloat measuredWidth = layout.usedRect.size.width;

  if (!CGRectIsEmpty(layout.extraLineFragmentRect)) {
    measuredHeight -= layout.extraLineFragmentRect.size.height;
  }

  if (isLastElementCodeBlock(text)) {
    measuredHeight += [_config codeBlockPadding];
  }

  if (_allowTrailingMargin && _lastElementMarginBottom > 0) {
    measuredHeight += _lastElementMarginBottom;
  }

  CGFloat scale = RCTScreenScale();
  return CGSizeMake(ceil(measuredWidth * scale) / scale, ceil(measuredHeight * scale) / scale);
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _textView.frame = self.bounds;
}

#pragma mark - Accessibility

- (void)rebuildAccessibilityElementsIfNeeded
{
  if (!_accessibilityNeedsRebuild) {
    return;
  }
  _accessibilityNeedsRebuild = NO;
#if !TARGET_OS_OSX
  _accessibilityElements = [MarkdownAccessibilityElementBuilder buildElementsForTextView:_textView
                                                                                    info:_accessibilityInfo
                                                                               container:self];
#endif
}

- (BOOL)isAccessibilityElement
{
  return NO;
}

- (NSInteger)accessibilityElementCount
{
  [self rebuildAccessibilityElementsIfNeeded];
  return _accessibilityElements.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
  [self rebuildAccessibilityElementsIfNeeded];
  if (index < 0 || index >= (NSInteger)_accessibilityElements.count) {
    return nil;
  }
  return _accessibilityElements[index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
  [self rebuildAccessibilityElementsIfNeeded];
  return [_accessibilityElements indexOfObject:element];
}

- (NSArray *)accessibilityElements
{
  [self rebuildAccessibilityElementsIfNeeded];
  return _accessibilityElements;
}

#if TARGET_OS_OSX
- (void)setContextMenuProvider:(ENRMContextMenuProvider)provider
{
  ((ENRMContextMenuTextView *)_textView).contextMenuProvider = provider;
}
#endif

@end
