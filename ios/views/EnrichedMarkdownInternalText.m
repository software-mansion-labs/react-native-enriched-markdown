#import "EnrichedMarkdownInternalText.h"
#import "AccessibilityInfo.h"
#import "LastElementUtils.h"
#import "MarkdownAccessibilityElementBuilder.h"
#import "RenderContext.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"
#import "TextViewLayoutManager.h"
#import <objc/runtime.h>

@implementation EnrichedMarkdownInternalText {
  UITextView *_textView;
  NSMutableArray<UIAccessibilityElement *> *_accessibilityElements;
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
  _textView = [[UITextView alloc] init];
  _textView.text = @"";
  _textView.font = [UIFont systemFontOfSize:16.0];
  _textView.backgroundColor = [UIColor clearColor];
  _textView.textColor = [UIColor blackColor];
  _textView.editable = NO;
  _textView.scrollEnabled = NO;
  _textView.showsVerticalScrollIndicator = NO;
  _textView.showsHorizontalScrollIndicator = NO;
  _textView.textContainerInset = UIEdgeInsetsZero;
  _textView.textContainer.lineFragmentPadding = 0;
  _textView.linkTextAttributes = @{};
  _textView.selectable = YES;
  _textView.accessibilityElementsHidden = YES;

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

  _textView.attributedText = text;

  [_textView.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, text.length) actualCharacterRange:NULL];

  [_textView setNeedsLayout];
  [_textView setNeedsDisplay];

  _accessibilityNeedsRebuild = (_accessibilityInfo != nil);
}

- (CGFloat)measureHeight:(CGFloat)maxWidth
{
  NSAttributedString *text = _textView.attributedText;
  if (text.length == 0) {
    return 0;
  }

  _textView.textContainer.size = CGSizeMake(maxWidth, CGFLOAT_MAX);
  [_textView.layoutManager ensureLayoutForTextContainer:_textView.textContainer];
  CGRect usedRect = [_textView.layoutManager usedRectForTextContainer:_textView.textContainer];

  CGFloat measuredHeight = usedRect.size.height;

  // Remove extra line fragment height (same as EnrichedMarkdownText)
  CGRect extraFragment = _textView.layoutManager.extraLineFragmentRect;
  if (!CGRectIsEmpty(extraFragment)) {
    measuredHeight -= extraFragment.size.height;
  }

  // Code block bottom padding compensation (same as EnrichedMarkdownText)
  if (isLastElementCodeBlock(text)) {
    measuredHeight += [_config codeBlockPadding];
  }

  if (_allowTrailingMargin && _lastElementMarginBottom > 0) {
    measuredHeight += _lastElementMarginBottom;
  }

  // Round to pixel boundaries to match React Native's <Text> measurement
  CGFloat scale = [UIScreen mainScreen].scale;
  return ceil(measuredHeight * scale) / scale;
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
  _accessibilityElements = [MarkdownAccessibilityElementBuilder buildElementsForTextView:_textView
                                                                                    info:_accessibilityInfo
                                                                               container:self];
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

@end
