#import "EnrichedMarkdownText.h"
#import "AttributedRenderer.h"
#import "EditMenuUtils.h"
#import "FontUtils.h"
#import "ImageAttachment.h"
#import "MarkdownASTNode.h"
#import "MarkdownExtractor.h"
#import "MarkdownParser.h"
#import "RenderContext.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"
#import "TextViewLayoutManager.h"
#import <objc/runtime.h>

#import <ReactNativeEnrichedMarkdown/EnrichedMarkdownTextComponentDescriptor.h>
#import <ReactNativeEnrichedMarkdown/EventEmitters.h>
#import <ReactNativeEnrichedMarkdown/Props.h>
#import <ReactNativeEnrichedMarkdown/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <React/RCTConversions.h>
#import <React/RCTFont.h>
#import <react/utils/ManagedObjectWrapper.h>

using namespace facebook::react;

@interface EnrichedMarkdownText () <RCTEnrichedMarkdownTextViewProtocol, UITextViewDelegate>
- (void)setupTextView;
- (void)renderMarkdownContent:(NSString *)markdownString;
- (void)applyRenderedText:(NSMutableAttributedString *)attributedText;
- (void)textTapped:(UITapGestureRecognizer *)recognizer;
- (void)setupLayoutManager;
@end

@implementation EnrichedMarkdownText {
  UITextView *_textView;
  MarkdownParser *_parser;
  NSString *_cachedMarkdown;
  StyleConfig *_config;

  // Background rendering support
  dispatch_queue_t _renderQueue;
  NSUInteger _currentRenderId;
  BOOL _blockAsyncRender;

  EnrichedMarkdownTextShadowNode::ConcreteState::Shared _state;
  int _heightUpdateCounter;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<EnrichedMarkdownTextComponentDescriptor>();
}

#pragma mark - Measuring and State

- (CGSize)measureSize:(CGFloat)maxWidth
{
  NSAttributedString *text = _textView.attributedText;
  CGFloat defaultHeight = [UIFont systemFontOfSize:16.0].lineHeight;

  if (!text || text.length == 0) {
    return CGSizeMake(maxWidth, defaultHeight);
  }

  // Find last non-newline character to exclude trailing spacing from measurement
  NSRange lastContent = [text.string rangeOfCharacterFromSet:[[NSCharacterSet newlineCharacterSet] invertedSet]
                                                     options:NSBackwardsSearch];
  if (lastContent.location == NSNotFound) {
    return CGSizeMake(maxWidth, defaultHeight);
  }

  NSAttributedString *contentToMeasure = [text attributedSubstringFromRange:NSMakeRange(0, NSMaxRange(lastContent))];
  CGRect boundingRect =
      [contentToMeasure boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     context:nil];

  return CGSizeMake(maxWidth, ceil(boundingRect.size.height));
}

- (void)updateState:(const facebook::react::State::Shared &)state
           oldState:(const facebook::react::State::Shared &)oldState
{
  _state = std::static_pointer_cast<const EnrichedMarkdownTextShadowNode::ConcreteState>(state);

  // Trigger initial height calculation when state is first set
  if (oldState == nullptr) {
    [self requestHeightUpdate];
  }
}

- (void)requestHeightUpdate
{
  if (_state == nullptr) {
    return;
  }

  _heightUpdateCounter++;
  auto selfRef = wrapManagedObjectWeakly(self);
  _state->updateState(EnrichedMarkdownTextState(_heightUpdateCounter, selfRef));
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const EnrichedMarkdownTextProps>();
    _props = defaultProps;

    self.backgroundColor = [UIColor clearColor];
    _parser = [[MarkdownParser alloc] init];

    // Serial queue for background rendering
    _renderQueue = dispatch_queue_create("com.swmansion.enriched.markdown.render", DISPATCH_QUEUE_SERIAL);
    _currentRenderId = 0;

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
  _textView.delegate = self;
  _textView.scrollEnabled = NO;
  _textView.textContainerInset = UIEdgeInsetsZero;
  _textView.textContainer.lineFragmentPadding = 0;
  // Disable UITextView's default link styling - we handle it directly in attributed strings
  _textView.linkTextAttributes = @{};
  // isSelectable controls text selection and link previews
  // Default to YES to match the prop default
  _textView.selectable = YES;
  // Hide initially to prevent flash before content is rendered
  _textView.hidden = YES;

  // Add tap gesture recognizer
  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(textTapped:)];
  [_textView addGestureRecognizer:tapRecognizer];

  // Use RCTViewComponentView's contentView for automatic sizing
  self.contentView = _textView;
}

- (void)didAddSubview:(UIView *)subview
{
  [super didAddSubview:subview];

  // Set up layout manager when text view is added
  if (subview == _textView) {
    [self setupLayoutManager];
  }
}

- (void)willRemoveSubview:(UIView *)subview
{
  // Clean up layout manager when text view is removed
  if (subview == _textView && _textView.layoutManager != nil) {
    NSLayoutManager *layoutManager = _textView.layoutManager;
    if ([object_getClass(layoutManager) isEqual:[TextViewLayoutManager class]]) {
      [layoutManager setValue:nil forKey:@"config"];
      object_setClass(layoutManager, [NSLayoutManager class]);
    }
  }
  [super willRemoveSubview:subview];
}

- (void)setupLayoutManager
{
  // Set up custom layout manager for rich text custom drawing (code, blockquotes, etc.)
  // This single manager can handle multiple element types
  NSLayoutManager *layoutManager = _textView.layoutManager;
  if (layoutManager != nil) {
    layoutManager.allowsNonContiguousLayout = NO; // workaround for onScroll issue (like react-native-live-markdown)
    object_setClass(layoutManager, [TextViewLayoutManager class]);

    // Set config on layout manager (like react-native-live-markdown sets markdownUtils)
    if (_config != nil) {
      [layoutManager setValue:_config forKey:@"config"];
    }
  }
}

- (void)renderMarkdownContent:(NSString *)markdownString
{
  // Skip async render for mock views (they use renderMarkdownSynchronously)
  if (_blockAsyncRender) {
    return;
  }

  _cachedMarkdown = [markdownString copy];

  // Increment render ID to invalidate any in-flight renders
  NSUInteger renderId = ++_currentRenderId;

  // Capture state needed for background rendering
  StyleConfig *config = [_config copy];
  MarkdownParser *parser = _parser;
  NSUInteger inputLength = markdownString.length;
  NSDate *scheduleStart = [NSDate date];

  // Dispatch heavy work to background queue
  dispatch_async(_renderQueue, ^{
    // 1. Parse Markdown → AST (C++ md4c parser)
    NSDate *parseStart = [NSDate date];
    MarkdownASTNode *ast = [parser parseMarkdown:markdownString];
    if (!ast) {
      return;
    }
    NSTimeInterval parseTime = [[NSDate date] timeIntervalSinceDate:parseStart] * 1000;
    NSUInteger nodeCount = ast.children.count;

    // 2. Render AST → NSAttributedString
    NSDate *renderStart = [NSDate date];
    AttributedRenderer *renderer = [[AttributedRenderer alloc] initWithConfig:config];
    RenderContext *context = [RenderContext new];
    NSMutableAttributedString *attributedText = [renderer renderRoot:ast context:context];

    // Add link attributes
    for (NSUInteger i = 0; i < context.linkRanges.count; i++) {
      NSValue *rangeValue = context.linkRanges[i];
      NSRange range = [rangeValue rangeValue];
      NSString *url = context.linkURLs[i];
      [attributedText addAttribute:@"linkURL" value:url range:range];
    }
    NSTimeInterval renderTime = [[NSDate date] timeIntervalSinceDate:renderStart] * 1000;
    NSUInteger styledLength = attributedText.length;

    NSLog(@"┌──────────────────────────────────────────────");
    NSLog(@"│ 📝 Input: %lu chars of Markdown", (unsigned long)inputLength);
    NSLog(@"│ ⚡ md4c (C++ native): %.0fms → %lu AST nodes", parseTime, (unsigned long)nodeCount);
    NSLog(@"│ 🎨 NSAttributedString render: %.0fms → %lu styled chars", renderTime, (unsigned long)styledLength);
    NSLog(@"└──────────────────────────────────────────────");

    // Apply result on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
      // Check if this render is still current
      if (renderId != self->_currentRenderId) {
        return;
      }

      [self applyRenderedText:attributedText];

      NSTimeInterval totalTime = [[NSDate date] timeIntervalSinceDate:scheduleStart] * 1000;
      NSLog(@"✅ Total time to display: %.0fms", totalTime);
    });
  });
}

// Synchronous rendering for mock view measurement (no UI updates needed)
- (void)renderMarkdownSynchronously:(NSString *)markdownString
{
  if (!markdownString || markdownString.length == 0) {
    return;
  }

  // Block any async renders triggered by updateProps
  _blockAsyncRender = YES;
  _cachedMarkdown = [markdownString copy];

  MarkdownASTNode *ast = [_parser parseMarkdown:markdownString];
  if (!ast) {
    return;
  }

  AttributedRenderer *renderer = [[AttributedRenderer alloc] initWithConfig:_config];
  RenderContext *context = [RenderContext new];
  NSMutableAttributedString *attributedText = [renderer renderRoot:ast context:context];

  for (NSUInteger i = 0; i < context.linkRanges.count; i++) {
    NSValue *rangeValue = context.linkRanges[i];
    NSRange range = [rangeValue rangeValue];
    NSString *url = context.linkURLs[i];
    [attributedText addAttribute:@"linkURL" value:url range:range];
  }

  _textView.attributedText = attributedText;
}

- (void)applyRenderedText:(NSMutableAttributedString *)attributedText
{
  // Set config on the layout manager
  NSLayoutManager *layoutManager = _textView.layoutManager;
  if ([layoutManager isKindOfClass:[TextViewLayoutManager class]]) {
    [layoutManager setValue:_config forKey:@"config"];
  }

  // Store text view on text container so attachments can access it
  objc_setAssociatedObject(_textView.textContainer, kTextViewKey, _textView, OBJC_ASSOCIATION_ASSIGN);

  _textView.attributedText = attributedText;

  // Ensure layout is updated
  [_textView.layoutManager ensureLayoutForTextContainer:_textView.textContainer];
  [_textView.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, attributedText.length)
                                        actualCharacterRange:NULL];

  [_textView setNeedsLayout];
  [_textView setNeedsDisplay];
  [self setNeedsLayout];

  // Request height recalculation from shadow node FIRST
  [self requestHeightUpdate];

  // Show text view on next run loop, after layout has settled
  if (_textView.hidden) {
    dispatch_async(dispatch_get_main_queue(), ^{ self->_textView.hidden = NO; });
  }
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<EnrichedMarkdownTextProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<EnrichedMarkdownTextProps const>(props);

  BOOL stylePropChanged = NO;

  if (_config == nil) {
    _config = [[StyleConfig alloc] init];
  }

  // Paragraph style
  if (newViewProps.markdownStyle.paragraph.fontSize != oldViewProps.markdownStyle.paragraph.fontSize) {
    [_config setParagraphFontSize:newViewProps.markdownStyle.paragraph.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.paragraph.fontFamily != oldViewProps.markdownStyle.paragraph.fontFamily) {
    if (!newViewProps.markdownStyle.paragraph.fontFamily.empty()) {
      NSString *fontFamily =
          [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.paragraph.fontFamily.c_str()];
      [_config setParagraphFontFamily:fontFamily];
    } else {
      [_config setParagraphFontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.paragraph.fontWeight != oldViewProps.markdownStyle.paragraph.fontWeight) {
    if (!newViewProps.markdownStyle.paragraph.fontWeight.empty()) {
      NSString *fontWeight =
          [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.paragraph.fontWeight.c_str()];
      [_config setParagraphFontWeight:fontWeight];
    } else {
      [_config setParagraphFontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.paragraph.color != oldViewProps.markdownStyle.paragraph.color) {
    if (newViewProps.markdownStyle.paragraph.color) {
      UIColor *paragraphColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.paragraph.color);
      [_config setParagraphColor:paragraphColor];
    } else {
      [_config setParagraphColor:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.paragraph.marginBottom != oldViewProps.markdownStyle.paragraph.marginBottom) {
    [_config setParagraphMarginBottom:newViewProps.markdownStyle.paragraph.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.paragraph.lineHeight != oldViewProps.markdownStyle.paragraph.lineHeight) {
    [_config setParagraphLineHeight:newViewProps.markdownStyle.paragraph.lineHeight];
    stylePropChanged = YES;
  }

  // H1 style
  if (newViewProps.markdownStyle.h1.fontSize != oldViewProps.markdownStyle.h1.fontSize) {
    [_config setH1FontSize:newViewProps.markdownStyle.h1.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h1.fontFamily != oldViewProps.markdownStyle.h1.fontFamily) {
    if (!newViewProps.markdownStyle.h1.fontFamily.empty()) {
      NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h1.fontFamily.c_str()];
      [_config setH1FontFamily:fontFamily];
    } else {
      [_config setH1FontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h1.fontWeight != oldViewProps.markdownStyle.h1.fontWeight) {
    if (!newViewProps.markdownStyle.h1.fontWeight.empty()) {
      NSString *fontWeight = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h1.fontWeight.c_str()];
      [_config setH1FontWeight:fontWeight];
    } else {
      [_config setH1FontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h1.color != oldViewProps.markdownStyle.h1.color) {
    if (newViewProps.markdownStyle.h1.color) {
      UIColor *h1Color = RCTUIColorFromSharedColor(newViewProps.markdownStyle.h1.color);
      [_config setH1Color:h1Color];
    } else {
      [_config setH1Color:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h1.marginBottom != oldViewProps.markdownStyle.h1.marginBottom) {
    [_config setH1MarginBottom:newViewProps.markdownStyle.h1.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h1.lineHeight != oldViewProps.markdownStyle.h1.lineHeight) {
    [_config setH1LineHeight:newViewProps.markdownStyle.h1.lineHeight];
    stylePropChanged = YES;
  }

  // H2 style
  if (newViewProps.markdownStyle.h2.fontSize != oldViewProps.markdownStyle.h2.fontSize) {
    [_config setH2FontSize:newViewProps.markdownStyle.h2.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h2.fontFamily != oldViewProps.markdownStyle.h2.fontFamily) {
    if (!newViewProps.markdownStyle.h2.fontFamily.empty()) {
      NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h2.fontFamily.c_str()];
      [_config setH2FontFamily:fontFamily];
    } else {
      [_config setH2FontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h2.fontWeight != oldViewProps.markdownStyle.h2.fontWeight) {
    if (!newViewProps.markdownStyle.h2.fontWeight.empty()) {
      NSString *fontWeight = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h2.fontWeight.c_str()];
      [_config setH2FontWeight:fontWeight];
    } else {
      [_config setH2FontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h2.color != oldViewProps.markdownStyle.h2.color) {
    if (newViewProps.markdownStyle.h2.color) {
      UIColor *h2Color = RCTUIColorFromSharedColor(newViewProps.markdownStyle.h2.color);
      [_config setH2Color:h2Color];
    } else {
      [_config setH2Color:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h2.marginBottom != oldViewProps.markdownStyle.h2.marginBottom) {
    [_config setH2MarginBottom:newViewProps.markdownStyle.h2.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h2.lineHeight != oldViewProps.markdownStyle.h2.lineHeight) {
    [_config setH2LineHeight:newViewProps.markdownStyle.h2.lineHeight];
    stylePropChanged = YES;
  }

  // H3 style
  if (newViewProps.markdownStyle.h3.fontSize != oldViewProps.markdownStyle.h3.fontSize) {
    [_config setH3FontSize:newViewProps.markdownStyle.h3.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h3.fontFamily != oldViewProps.markdownStyle.h3.fontFamily) {
    if (!newViewProps.markdownStyle.h3.fontFamily.empty()) {
      NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h3.fontFamily.c_str()];
      [_config setH3FontFamily:fontFamily];
    } else {
      [_config setH3FontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h3.fontWeight != oldViewProps.markdownStyle.h3.fontWeight) {
    if (!newViewProps.markdownStyle.h3.fontWeight.empty()) {
      NSString *fontWeight = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h3.fontWeight.c_str()];
      [_config setH3FontWeight:fontWeight];
    } else {
      [_config setH3FontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h3.color != oldViewProps.markdownStyle.h3.color) {
    if (newViewProps.markdownStyle.h3.color) {
      UIColor *h3Color = RCTUIColorFromSharedColor(newViewProps.markdownStyle.h3.color);
      [_config setH3Color:h3Color];
    } else {
      [_config setH3Color:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h3.marginBottom != oldViewProps.markdownStyle.h3.marginBottom) {
    [_config setH3MarginBottom:newViewProps.markdownStyle.h3.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h3.lineHeight != oldViewProps.markdownStyle.h3.lineHeight) {
    [_config setH3LineHeight:newViewProps.markdownStyle.h3.lineHeight];
    stylePropChanged = YES;
  }

  // H4 style
  if (newViewProps.markdownStyle.h4.fontSize != oldViewProps.markdownStyle.h4.fontSize) {
    [_config setH4FontSize:newViewProps.markdownStyle.h4.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h4.fontFamily != oldViewProps.markdownStyle.h4.fontFamily) {
    if (!newViewProps.markdownStyle.h4.fontFamily.empty()) {
      NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h4.fontFamily.c_str()];
      [_config setH4FontFamily:fontFamily];
    } else {
      [_config setH4FontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h4.fontWeight != oldViewProps.markdownStyle.h4.fontWeight) {
    if (!newViewProps.markdownStyle.h4.fontWeight.empty()) {
      NSString *fontWeight = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h4.fontWeight.c_str()];
      [_config setH4FontWeight:fontWeight];
    } else {
      [_config setH4FontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h4.color != oldViewProps.markdownStyle.h4.color) {
    if (newViewProps.markdownStyle.h4.color) {
      UIColor *h4Color = RCTUIColorFromSharedColor(newViewProps.markdownStyle.h4.color);
      [_config setH4Color:h4Color];
    } else {
      [_config setH4Color:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h4.marginBottom != oldViewProps.markdownStyle.h4.marginBottom) {
    [_config setH4MarginBottom:newViewProps.markdownStyle.h4.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h4.lineHeight != oldViewProps.markdownStyle.h4.lineHeight) {
    [_config setH4LineHeight:newViewProps.markdownStyle.h4.lineHeight];
    stylePropChanged = YES;
  }

  // H5 style
  if (newViewProps.markdownStyle.h5.fontSize != oldViewProps.markdownStyle.h5.fontSize) {
    [_config setH5FontSize:newViewProps.markdownStyle.h5.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h5.fontFamily != oldViewProps.markdownStyle.h5.fontFamily) {
    if (!newViewProps.markdownStyle.h5.fontFamily.empty()) {
      NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h5.fontFamily.c_str()];
      [_config setH5FontFamily:fontFamily];
    } else {
      [_config setH5FontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h5.fontWeight != oldViewProps.markdownStyle.h5.fontWeight) {
    if (!newViewProps.markdownStyle.h5.fontWeight.empty()) {
      NSString *fontWeight = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h5.fontWeight.c_str()];
      [_config setH5FontWeight:fontWeight];
    } else {
      [_config setH5FontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h5.color != oldViewProps.markdownStyle.h5.color) {
    if (newViewProps.markdownStyle.h5.color) {
      UIColor *h5Color = RCTUIColorFromSharedColor(newViewProps.markdownStyle.h5.color);
      [_config setH5Color:h5Color];
    } else {
      [_config setH5Color:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h5.marginBottom != oldViewProps.markdownStyle.h5.marginBottom) {
    [_config setH5MarginBottom:newViewProps.markdownStyle.h5.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h5.lineHeight != oldViewProps.markdownStyle.h5.lineHeight) {
    [_config setH5LineHeight:newViewProps.markdownStyle.h5.lineHeight];
    stylePropChanged = YES;
  }

  // H6 style
  if (newViewProps.markdownStyle.h6.fontSize != oldViewProps.markdownStyle.h6.fontSize) {
    [_config setH6FontSize:newViewProps.markdownStyle.h6.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h6.fontFamily != oldViewProps.markdownStyle.h6.fontFamily) {
    if (!newViewProps.markdownStyle.h6.fontFamily.empty()) {
      NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h6.fontFamily.c_str()];
      [_config setH6FontFamily:fontFamily];
    } else {
      [_config setH6FontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h6.fontWeight != oldViewProps.markdownStyle.h6.fontWeight) {
    if (!newViewProps.markdownStyle.h6.fontWeight.empty()) {
      NSString *fontWeight = [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.h6.fontWeight.c_str()];
      [_config setH6FontWeight:fontWeight];
    } else {
      [_config setH6FontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h6.color != oldViewProps.markdownStyle.h6.color) {
    if (newViewProps.markdownStyle.h6.color) {
      UIColor *h6Color = RCTUIColorFromSharedColor(newViewProps.markdownStyle.h6.color);
      [_config setH6Color:h6Color];
    } else {
      [_config setH6Color:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h6.marginBottom != oldViewProps.markdownStyle.h6.marginBottom) {
    [_config setH6MarginBottom:newViewProps.markdownStyle.h6.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.h6.lineHeight != oldViewProps.markdownStyle.h6.lineHeight) {
    [_config setH6LineHeight:newViewProps.markdownStyle.h6.lineHeight];
    stylePropChanged = YES;
  }

  // Blockquote style
  if (newViewProps.markdownStyle.blockquote.fontSize != oldViewProps.markdownStyle.blockquote.fontSize) {
    [_config setBlockquoteFontSize:newViewProps.markdownStyle.blockquote.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.fontFamily != oldViewProps.markdownStyle.blockquote.fontFamily) {
    NSString *fontFamily =
        [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.blockquote.fontFamily.c_str()];
    [_config setBlockquoteFontFamily:fontFamily];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.fontWeight != oldViewProps.markdownStyle.blockquote.fontWeight) {
    NSString *fontWeight =
        [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.blockquote.fontWeight.c_str()];
    [_config setBlockquoteFontWeight:fontWeight];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.color != oldViewProps.markdownStyle.blockquote.color) {
    UIColor *blockquoteColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.blockquote.color);
    [_config setBlockquoteColor:blockquoteColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.marginBottom != oldViewProps.markdownStyle.blockquote.marginBottom) {
    [_config setBlockquoteMarginBottom:newViewProps.markdownStyle.blockquote.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.nestedMarginBottom !=
      oldViewProps.markdownStyle.blockquote.nestedMarginBottom) {
    [_config setBlockquoteNestedMarginBottom:newViewProps.markdownStyle.blockquote.nestedMarginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.lineHeight != oldViewProps.markdownStyle.blockquote.lineHeight) {
    [_config setBlockquoteLineHeight:newViewProps.markdownStyle.blockquote.lineHeight];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.borderColor != oldViewProps.markdownStyle.blockquote.borderColor) {
    UIColor *blockquoteBorderColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.blockquote.borderColor);
    [_config setBlockquoteBorderColor:blockquoteBorderColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.borderWidth != oldViewProps.markdownStyle.blockquote.borderWidth) {
    [_config setBlockquoteBorderWidth:newViewProps.markdownStyle.blockquote.borderWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.gapWidth != oldViewProps.markdownStyle.blockquote.gapWidth) {
    [_config setBlockquoteGapWidth:newViewProps.markdownStyle.blockquote.gapWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.blockquote.backgroundColor != oldViewProps.markdownStyle.blockquote.backgroundColor) {
    UIColor *blockquoteBackgroundColor =
        RCTUIColorFromSharedColor(newViewProps.markdownStyle.blockquote.backgroundColor);
    [_config setBlockquoteBackgroundColor:blockquoteBackgroundColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.link.color != oldViewProps.markdownStyle.link.color) {
    UIColor *linkColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.link.color);
    [_config setLinkColor:linkColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.link.underline != oldViewProps.markdownStyle.link.underline) {
    [_config setLinkUnderline:newViewProps.markdownStyle.link.underline];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.strong.color != oldViewProps.markdownStyle.strong.color) {
    if (newViewProps.markdownStyle.strong.color) {
      UIColor *strongColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.strong.color);
      [_config setStrongColor:strongColor];
    } else {
      [_config setStrongColor:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.em.color != oldViewProps.markdownStyle.em.color) {
    if (newViewProps.markdownStyle.em.color) {
      UIColor *emphasisColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.em.color);
      [_config setEmphasisColor:emphasisColor];
    } else {
      [_config setEmphasisColor:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.code.color != oldViewProps.markdownStyle.code.color) {
    if (newViewProps.markdownStyle.code.color) {
      UIColor *codeColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.code.color);
      [_config setCodeColor:codeColor];
    } else {
      [_config setCodeColor:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.code.backgroundColor != oldViewProps.markdownStyle.code.backgroundColor) {
    if (newViewProps.markdownStyle.code.backgroundColor) {
      UIColor *codeBackgroundColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.code.backgroundColor);
      [_config setCodeBackgroundColor:codeBackgroundColor];
    } else {
      [_config setCodeBackgroundColor:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.code.borderColor != oldViewProps.markdownStyle.code.borderColor) {
    if (newViewProps.markdownStyle.code.borderColor) {
      UIColor *codeBorderColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.code.borderColor);
      [_config setCodeBorderColor:codeBorderColor];
    } else {
      [_config setCodeBorderColor:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.image.height != oldViewProps.markdownStyle.image.height) {
    [_config setImageHeight:newViewProps.markdownStyle.image.height];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.image.borderRadius != oldViewProps.markdownStyle.image.borderRadius) {
    [_config setImageBorderRadius:newViewProps.markdownStyle.image.borderRadius];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.image.marginBottom != oldViewProps.markdownStyle.image.marginBottom) {
    [_config setImageMarginBottom:newViewProps.markdownStyle.image.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.inlineImage.size != oldViewProps.markdownStyle.inlineImage.size) {
    [_config setInlineImageSize:newViewProps.markdownStyle.inlineImage.size];
    stylePropChanged = YES;
  }

  // List style
  if (newViewProps.markdownStyle.listStyle.fontSize != oldViewProps.markdownStyle.listStyle.fontSize) {
    [_config setListStyleFontSize:newViewProps.markdownStyle.listStyle.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.fontFamily != oldViewProps.markdownStyle.listStyle.fontFamily) {
    NSString *fontFamily =
        [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.listStyle.fontFamily.c_str()];
    [_config setListStyleFontFamily:fontFamily];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.fontWeight != oldViewProps.markdownStyle.listStyle.fontWeight) {
    NSString *fontWeight =
        [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.listStyle.fontWeight.c_str()];
    [_config setListStyleFontWeight:fontWeight];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.color != oldViewProps.markdownStyle.listStyle.color) {
    UIColor *listColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.listStyle.color);
    [_config setListStyleColor:listColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.marginBottom != oldViewProps.markdownStyle.listStyle.marginBottom) {
    [_config setListStyleMarginBottom:newViewProps.markdownStyle.listStyle.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.lineHeight != oldViewProps.markdownStyle.listStyle.lineHeight) {
    [_config setListStyleLineHeight:newViewProps.markdownStyle.listStyle.lineHeight];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.bulletColor != oldViewProps.markdownStyle.listStyle.bulletColor) {
    UIColor *bulletColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.listStyle.bulletColor);
    [_config setListStyleBulletColor:bulletColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.bulletSize != oldViewProps.markdownStyle.listStyle.bulletSize) {
    [_config setListStyleBulletSize:newViewProps.markdownStyle.listStyle.bulletSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.markerColor != oldViewProps.markdownStyle.listStyle.markerColor) {
    UIColor *markerColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.listStyle.markerColor);
    [_config setListStyleMarkerColor:markerColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.markerFontWeight != oldViewProps.markdownStyle.listStyle.markerFontWeight) {
    NSString *markerFontWeight =
        [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.listStyle.markerFontWeight.c_str()];
    [_config setListStyleMarkerFontWeight:markerFontWeight];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.gapWidth != oldViewProps.markdownStyle.listStyle.gapWidth) {
    [_config setListStyleGapWidth:newViewProps.markdownStyle.listStyle.gapWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.listStyle.marginLeft != oldViewProps.markdownStyle.listStyle.marginLeft) {
    [_config setListStyleMarginLeft:newViewProps.markdownStyle.listStyle.marginLeft];
    stylePropChanged = YES;
  }

  // Code block style
  if (newViewProps.markdownStyle.codeBlock.fontSize != oldViewProps.markdownStyle.codeBlock.fontSize) {
    [_config setCodeBlockFontSize:newViewProps.markdownStyle.codeBlock.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.fontFamily != oldViewProps.markdownStyle.codeBlock.fontFamily) {
    NSString *fontFamily =
        [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.codeBlock.fontFamily.c_str()];
    [_config setCodeBlockFontFamily:fontFamily];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.fontWeight != oldViewProps.markdownStyle.codeBlock.fontWeight) {
    NSString *fontWeight =
        [[NSString alloc] initWithUTF8String:newViewProps.markdownStyle.codeBlock.fontWeight.c_str()];
    [_config setCodeBlockFontWeight:fontWeight];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.color != oldViewProps.markdownStyle.codeBlock.color) {
    UIColor *codeBlockColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.codeBlock.color);
    [_config setCodeBlockColor:codeBlockColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.marginBottom != oldViewProps.markdownStyle.codeBlock.marginBottom) {
    [_config setCodeBlockMarginBottom:newViewProps.markdownStyle.codeBlock.marginBottom];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.lineHeight != oldViewProps.markdownStyle.codeBlock.lineHeight) {
    [_config setCodeBlockLineHeight:newViewProps.markdownStyle.codeBlock.lineHeight];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.backgroundColor != oldViewProps.markdownStyle.codeBlock.backgroundColor) {
    UIColor *codeBlockBackgroundColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.codeBlock.backgroundColor);
    [_config setCodeBlockBackgroundColor:codeBlockBackgroundColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.borderColor != oldViewProps.markdownStyle.codeBlock.borderColor) {
    UIColor *codeBlockBorderColor = RCTUIColorFromSharedColor(newViewProps.markdownStyle.codeBlock.borderColor);
    [_config setCodeBlockBorderColor:codeBlockBorderColor];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.borderRadius != oldViewProps.markdownStyle.codeBlock.borderRadius) {
    [_config setCodeBlockBorderRadius:newViewProps.markdownStyle.codeBlock.borderRadius];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.borderWidth != oldViewProps.markdownStyle.codeBlock.borderWidth) {
    [_config setCodeBlockBorderWidth:newViewProps.markdownStyle.codeBlock.borderWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.markdownStyle.codeBlock.padding != oldViewProps.markdownStyle.codeBlock.padding) {
    [_config setCodeBlockPadding:newViewProps.markdownStyle.codeBlock.padding];
    stylePropChanged = YES;
  }

  // Update config reference on layout manager if it's not already set
  NSLayoutManager *layoutManager = _textView.layoutManager;
  if ([layoutManager isKindOfClass:[TextViewLayoutManager class]]) {
    StyleConfig *currentConfig = [layoutManager valueForKey:@"config"];
    if (currentConfig != _config) {
      // Only update reference if it's different (first time setup)
      [layoutManager setValue:_config forKey:@"config"];
    }
  }

  // Control text selection and link previews via isSelectable property
  // According to Apple docs, isSelectable controls whether text selection and link previews work
  // https://developer.apple.com/documentation/uikit/uitextview/isselectable
  if (_textView.selectable != newViewProps.isSelectable) {
    _textView.selectable = newViewProps.isSelectable;
  }

  BOOL markdownChanged = oldViewProps.markdown != newViewProps.markdown;

  if (markdownChanged || stylePropChanged) {
    NSString *markdownString = [[NSString alloc] initWithUTF8String:newViewProps.markdown.c_str()];
    [self renderMarkdownContent:markdownString];
  }

  [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> EnrichedMarkdownTextCls(void)
{
  return EnrichedMarkdownText.class;
}

- (void)textTapped:(UITapGestureRecognizer *)recognizer
{
  /*
   * HOW LINK TAPPING WORKS:
   *
   * 1. SETUP PHASE (During Rendering):
   *    - Each link gets a custom @"linkURL" attribute attached to its text range
   *    - The URL is stored as the attribute's value
   *    - This creates an "invisible map" of where links are in the text
   *
   *    Example:
   *    Text: "Check out this [link to React Native](https://reactnative.dev)"
   *          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   *          |     |     |     |     |     |     |     |     |     |     |
   *          0     5    10    15    20    25    30    35    40    45    50
   *
   *    Attributes:
   *    - Characters 15-29: @"linkURL" = "https://reactnative.dev"
   *    - Characters 0-14: no special attributes
   *    - Characters 30-50: no special attributes
   *
   * 2. TOUCH DETECTION PHASE (When User Taps):
   *    - UITapGestureRecognizer detects the tap
   *    - We get the tap coordinates relative to the text view
   *    - We adjust for text container insets to get precise text coordinates
   */

  UITextView *textView = (UITextView *)recognizer.view;

  // Location of the tap in text-container coordinates
  NSLayoutManager *layoutManager = textView.layoutManager;
  CGPoint location = [recognizer locationInView:textView];
  location.x -= textView.textContainerInset.left;
  location.y -= textView.textContainerInset.top;

  /*
   * 3. CHARACTER INDEX LOOKUP:
   *    - NSLayoutManager converts the tap coordinates to a character index
   *    - This tells us exactly which character in the text was tapped
   *    - Uses UIKit's built-in text layout system (very accurate)
   */
  NSUInteger characterIndex;
  characterIndex = [layoutManager characterIndexForPoint:location
                                         inTextContainer:textView.textContainer
                fractionOfDistanceBetweenInsertionPoints:NULL];

  /*
   * 4. LINK DETECTION:
   *    - We check if there's a @"linkURL" attribute at the tapped character
   *    - If found, we get the URL value and the effective range
   *    - If it's a link, we emit the onLinkPress event to React Native
   *
   * COMPLETE FLOW:
   * 1. User taps → UITapGestureRecognizer fires
   * 2. Get coordinates → Convert to text container coordinates
   * 3. Find character → NSLayoutManager.characterIndexForPoint
   * 4. Check attributes → Look for @"linkURL" at that character
   * 5. If link found → Emit onLinkPress event with URL
   * 6. React Native → Receives event and shows alert
   */
  if (characterIndex < textView.textStorage.length) {
    NSRange range;
    NSString *url = [textView.attributedText attribute:@"linkURL" atIndex:characterIndex effectiveRange:&range];

    if (url) {
      // Emit onLinkPress event to React Native
      const auto &eventEmitter = *std::static_pointer_cast<EnrichedMarkdownTextEventEmitter const>(_eventEmitter);
      eventEmitter.onLinkPress({.url = std::string([url UTF8String])});
    }
  }
}

#pragma mark - UITextViewDelegate (Edit Menu)

// Customizes the edit menu
- (UIMenu *)textView:(UITextView *)textView
    editMenuForTextInRange:(NSRange)range
          suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
  return buildEditMenuForSelection(_textView.attributedText, range, _cachedMarkdown, _config, suggestedActions);
}

@end
