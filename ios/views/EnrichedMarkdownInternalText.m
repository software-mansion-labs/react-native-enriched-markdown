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

  [_textView.layoutManager ensureLayoutForTextContainer:_textView.textContainer];
  [_textView.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, text.length) actualCharacterRange:NULL];

  [_textView setNeedsLayout];
  [_textView setNeedsDisplay];

  if (_accessibilityInfo != nil) {
    _accessibilityElements = [MarkdownAccessibilityElementBuilder buildElementsForTextView:_textView
                                                                                      info:_accessibilityInfo
                                                                                 container:self];
  }
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

  return ceil(measuredHeight);
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _textView.frame = self.bounds;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
  return NO;
}

- (NSInteger)accessibilityElementCount
{
  return _accessibilityElements.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
  if (index < 0 || index >= (NSInteger)_accessibilityElements.count) {
    return nil;
  }
  return _accessibilityElements[index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
  return [_accessibilityElements indexOfObject:element];
}

- (NSArray *)accessibilityElements
{
  return _accessibilityElements;
}

@end
