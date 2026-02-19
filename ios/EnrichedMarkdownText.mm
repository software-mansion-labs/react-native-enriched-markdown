#import "EnrichedMarkdownText.h"
#import "AccessibilityInfo.h"
#import "AttributedRenderer.h"
#import "CodeBlockBackground.h"
#import "ENRMMarkdownParser.h"
#import "EditMenuUtils.h"
#import "EnrichedMarkdownImageAttachment.h"
#import "FontScaleObserver.h"
#import "FontUtils.h"
#import "LastElementUtils.h"
#import "LinkTapUtils.h"
#import "MarkdownASTNode.h"
#import "MarkdownAccessibilityElementBuilder.h"
#import "MarkdownExtractor.h"
#import "ParagraphStyleUtils.h"
#import "RenderContext.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"
#import "StylePropsUtils.h"
#import "TextViewLayoutManager.h"
#import <React/RCTUtils.h>
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
  ENRMMarkdownParser *_parser;
  NSString *_cachedMarkdown;
  StyleConfig *_config;
  ENRMMd4cFlags *_md4cFlags;

  dispatch_queue_t _renderQueue;
  NSUInteger _currentRenderId;
  BOOL _blockAsyncRender;

  EnrichedMarkdownTextShadowNode::ConcreteState::Shared _state;
  int _heightUpdateCounter;

  FontScaleObserver *_fontScaleObserver;
  CGFloat _maxFontSizeMultiplier;

  CGFloat _lastElementMarginBottom;
  BOOL _allowTrailingMargin;
  BOOL _enableLinkPreview;

  AccessibilityInfo *_accessibilityInfo;
  NSMutableArray<UIAccessibilityElement *> *_accessibilityElements;
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

  if (text.length == 0) {
    return CGSizeMake(maxWidth, defaultHeight);
  }

  // Use UITextView's layout manager for measurement to avoid
  // boundingRectWithSize: height discrepancies with NSTextAttachment objects.
  _textView.textContainer.size = CGSizeMake(maxWidth, CGFLOAT_MAX);
  [_textView.layoutManager ensureLayoutForTextContainer:_textView.textContainer];
  CGRect usedRect = [_textView.layoutManager usedRectForTextContainer:_textView.textContainer];

  CGFloat measuredWidth = ceil(usedRect.size.width);
  CGFloat measuredHeight = usedRect.size.height;

  // When text ends with \n (e.g. code block's bottom padding spacer),
  // TextKit creates an "extra line fragment" after it that adds unwanted height.
  CGRect extraFragment = _textView.layoutManager.extraLineFragmentRect;
  if (!CGRectIsEmpty(extraFragment)) {
    measuredHeight -= extraFragment.size.height;
  }

  // Code block's bottom padding is a spacer \n with minimumLineHeight = codeBlockPadding.
  // The layout manager may not size it accurately, so add the padding explicitly.
  if (isLastElementCodeBlock(text)) {
    measuredHeight += [_config codeBlockPadding];
  }

  if (_allowTrailingMargin && _lastElementMarginBottom > 0) {
    measuredHeight += _lastElementMarginBottom;
  }

  return CGSizeMake(measuredWidth, ceil(measuredHeight));
}

- (void)updateState:(const facebook::react::State::Shared &)state
           oldState:(const facebook::react::State::Shared &)oldState
{
  _state = std::static_pointer_cast<const EnrichedMarkdownTextShadowNode::ConcreteState>(state);

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
    _parser = [[ENRMMarkdownParser alloc] init];
    _md4cFlags = [ENRMMd4cFlags defaultFlags];

    _renderQueue = dispatch_queue_create("com.swmansion.enriched.markdown.render", DISPATCH_QUEUE_SERIAL);
    _currentRenderId = 0;

    _maxFontSizeMultiplier = 0;
    _allowTrailingMargin = NO;
    _enableLinkPreview = YES;

    _fontScaleObserver = [[FontScaleObserver alloc] init];
    __weak EnrichedMarkdownText *weakSelf = self;
    _fontScaleObserver.onChange = ^{
      EnrichedMarkdownText *strongSelf = weakSelf;
      if (!strongSelf)
        return;
      if (strongSelf->_config != nil) {
        [strongSelf->_config setFontScaleMultiplier:strongSelf->_fontScaleObserver.effectiveFontScale];
      }
      if (strongSelf->_cachedMarkdown != nil && strongSelf->_cachedMarkdown.length > 0) {
        [strongSelf renderMarkdownContent:strongSelf->_cachedMarkdown];
      }
    };

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
  _textView.showsVerticalScrollIndicator = NO;
  _textView.showsHorizontalScrollIndicator = NO;
  _textView.textContainerInset = UIEdgeInsetsZero;
  _textView.textContainer.lineFragmentPadding = 0;
  // Disable UITextView's default link styling - we handle it directly in attributed strings
  _textView.linkTextAttributes = @{};
  _textView.selectable = YES;
  // Prevent flash before content is rendered
  _textView.hidden = YES;
  // We provide custom accessibility elements with proper traits
  _textView.accessibilityElementsHidden = YES;

  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(textTapped:)];
  [_textView addGestureRecognizer:tapRecognizer];

  self.contentView = _textView;
}

- (void)didAddSubview:(UIView *)subview
{
  [super didAddSubview:subview];

  if (subview == _textView) {
    [self setupLayoutManager];
  }
}

- (void)willRemoveSubview:(UIView *)subview
{
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
  // Custom layout manager handles drawing for code blocks, blockquotes, etc.
  NSLayoutManager *layoutManager = _textView.layoutManager;
  if (layoutManager != nil) {
    layoutManager.allowsNonContiguousLayout = NO; // workaround for onScroll issue
    object_setClass(layoutManager, [TextViewLayoutManager class]);

    if (_config != nil) {
      [layoutManager setValue:_config forKey:@"config"];
    }
  }
}

- (void)renderMarkdownContent:(NSString *)markdownString
{
  if (_blockAsyncRender) {
    return;
  }

  _cachedMarkdown = [markdownString copy];

  NSUInteger renderId = ++_currentRenderId;

  StyleConfig *config = [_config copy];
  ENRMMarkdownParser *parser = _parser;
  ENRMMd4cFlags *md4cFlags = [_md4cFlags copy];

  BOOL allowFontScaling = _fontScaleObserver.allowFontScaling;
  CGFloat maxFontSizeMultiplier = _maxFontSizeMultiplier;
  BOOL allowTrailingMargin = _allowTrailingMargin;

  dispatch_async(_renderQueue, ^{
    MarkdownASTNode *ast = [parser parseMarkdown:markdownString flags:md4cFlags];
    if (!ast) {
      return;
    }

    AttributedRenderer *renderer = [[AttributedRenderer alloc] initWithConfig:config];
    [renderer setAllowTrailingMargin:allowTrailingMargin];
    RenderContext *context = [RenderContext new];
    context.allowFontScaling = allowFontScaling;
    context.maxFontSizeMultiplier = maxFontSizeMultiplier;
    NSMutableAttributedString *attributedText = [renderer renderRoot:ast context:context];

    CGFloat lastElementMarginBottom = [renderer getLastElementMarginBottom];

    [context applyLinkAttributesToString:attributedText];

    AccessibilityInfo *accessibilityInfo = [AccessibilityInfo infoFromContext:context];

    dispatch_async(dispatch_get_main_queue(), ^{
      if (renderId != self->_currentRenderId) {
        return;
      }

      self->_lastElementMarginBottom = lastElementMarginBottom;
      self->_accessibilityInfo = accessibilityInfo;

      [self applyRenderedText:attributedText];
    });
  });
}

// Synchronous rendering for mock view measurement (no UI updates needed)
- (void)renderMarkdownSynchronously:(NSString *)markdownString
{
  if (!markdownString || markdownString.length == 0) {
    return;
  }

  _blockAsyncRender = YES;
  _cachedMarkdown = [markdownString copy];

  MarkdownASTNode *ast = [_parser parseMarkdown:markdownString flags:_md4cFlags];
  if (!ast) {
    return;
  }

  AttributedRenderer *renderer = [[AttributedRenderer alloc] initWithConfig:_config];
  [renderer setAllowTrailingMargin:_allowTrailingMargin];
  RenderContext *context = [RenderContext new];
  context.allowFontScaling = _fontScaleObserver.allowFontScaling;
  context.maxFontSizeMultiplier = _maxFontSizeMultiplier;
  NSMutableAttributedString *attributedText = [renderer renderRoot:ast context:context];

  _lastElementMarginBottom = [renderer getLastElementMarginBottom];

  [context applyLinkAttributesToString:attributedText];

  _accessibilityInfo = [AccessibilityInfo infoFromContext:context];

  _textView.attributedText = attributedText;
}

- (void)applyRenderedText:(NSMutableAttributedString *)attributedText
{
  NSLayoutManager *layoutManager = _textView.layoutManager;
  if ([layoutManager isKindOfClass:[TextViewLayoutManager class]]) {
    [layoutManager setValue:_config forKey:@"config"];
  }

  // Attachments access the text view via associated object on the container
  objc_setAssociatedObject(_textView.textContainer, kTextViewKey, _textView, OBJC_ASSOCIATION_ASSIGN);

  _textView.attributedText = attributedText;

  [_textView.layoutManager ensureLayoutForTextContainer:_textView.textContainer];
  [_textView.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, attributedText.length)
                                        actualCharacterRange:NULL];

  [_textView setNeedsLayout];
  [_textView setNeedsDisplay];
  [self setNeedsLayout];

  // Height update must happen before accessibility elements are built
  [self requestHeightUpdate];
  [self buildAccessibilityElements];

  // Next run loop — layout must settle before revealing content
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
    [_config setFontScaleMultiplier:_fontScaleObserver.effectiveFontScale];
  }

  stylePropChanged = applyMarkdownStyleToConfig(_config, newViewProps.markdownStyle, oldViewProps.markdownStyle);

  NSLayoutManager *layoutManager = _textView.layoutManager;
  if ([layoutManager isKindOfClass:[TextViewLayoutManager class]]) {
    StyleConfig *currentConfig = [layoutManager valueForKey:@"config"];
    if (currentConfig != _config) {
      [layoutManager setValue:_config forKey:@"config"];
    }
  }

  if (_textView.selectable != newViewProps.selectable) {
    _textView.selectable = newViewProps.selectable;
  }

  if (newViewProps.allowFontScaling != oldViewProps.allowFontScaling) {
    _fontScaleObserver.allowFontScaling = newViewProps.allowFontScaling;

    if (_config != nil) {
      [_config setFontScaleMultiplier:_fontScaleObserver.effectiveFontScale];
    }

    stylePropChanged = YES;
  }

  if (newViewProps.maxFontSizeMultiplier != oldViewProps.maxFontSizeMultiplier) {
    _maxFontSizeMultiplier = newViewProps.maxFontSizeMultiplier;

    if (_config != nil) {
      [_config setMaxFontSizeMultiplier:_maxFontSizeMultiplier];
    }

    stylePropChanged = YES;
  }

  if (newViewProps.allowTrailingMargin != oldViewProps.allowTrailingMargin) {
    _allowTrailingMargin = newViewProps.allowTrailingMargin;
  }

  BOOL md4cFlagsChanged = NO;
  if (newViewProps.md4cFlags.underline != oldViewProps.md4cFlags.underline) {
    _md4cFlags.underline = newViewProps.md4cFlags.underline;
    md4cFlagsChanged = YES;
  }

  BOOL markdownChanged = oldViewProps.markdown != newViewProps.markdown;
  BOOL allowTrailingMarginChanged = newViewProps.allowTrailingMargin != oldViewProps.allowTrailingMargin;

  _enableLinkPreview = newViewProps.enableLinkPreview;

  if (markdownChanged || stylePropChanged || md4cFlagsChanged || allowTrailingMarginChanged) {
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
  UITextView *textView = (UITextView *)recognizer.view;
  NSString *url = linkURLAtTapLocation(textView, recognizer);
  if (url) {
    auto eventEmitter = std::static_pointer_cast<EnrichedMarkdownTextEventEmitter const>(_eventEmitter);
    if (eventEmitter) {
      eventEmitter->onLinkPress({.url = std::string([url UTF8String])});
    }
  }
}

#pragma mark - UITextViewDelegate (Link Interaction)

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange
              interaction:(UITextItemInteraction)interaction
{
  if (interaction != UITextItemInteractionPresentActions) {
    return YES;
  }

  NSString *urlString = linkURLAtRange(textView, characterRange);

  if (!urlString || _enableLinkPreview) {
    return YES;
  }

  auto eventEmitter = std::static_pointer_cast<EnrichedMarkdownTextEventEmitter const>(_eventEmitter);
  if (eventEmitter) {
    eventEmitter->onLinkLongPress({.url = std::string([urlString UTF8String])});
  }
  return NO;
}

#pragma mark - UITextViewDelegate (Edit Menu)

- (UIMenu *)textView:(UITextView *)textView
    editMenuForTextInRange:(NSRange)range
          suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
  return buildEditMenuForSelection(textView.attributedText, range, _cachedMarkdown, _config, suggestedActions);
}

#pragma mark - Accessibility (VoiceOver Navigation)

- (void)buildAccessibilityElements
{
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

- (NSArray<UIAccessibilityCustomRotor *> *)accessibilityCustomRotors
{
  return [MarkdownAccessibilityElementBuilder buildRotorsFromElements:_accessibilityElements];
}

@end
