#import "EnrichedMarkdown.h"
#import "AccessibilityInfo.h"
#import "AttributedRenderer.h"
#import "ENRMMarkdownParser.h"
#import "EditMenuUtils.h"
#import "EnrichedMarkdownInternalText.h"
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
#import "TableContainerView.h"
#import "TaskListTapUtils.h"
#import "TextViewLayoutManager.h"
#import <React/RCTUtils.h>
#import <objc/runtime.h>

#import <ReactNativeEnrichedMarkdown/EnrichedMarkdownComponentDescriptor.h>
#import <ReactNativeEnrichedMarkdown/EventEmitters.h>
#import <ReactNativeEnrichedMarkdown/Props.h>
#import <ReactNativeEnrichedMarkdown/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <React/RCTConversions.h>
#import <React/RCTFont.h>
#import <react/utils/ManagedObjectWrapper.h>

using namespace facebook::react;

@interface EMTextSegment : NSObject
@property (nonatomic, strong) NSArray<MarkdownASTNode *> *nodes;
+ (instancetype)segmentWithNodes:(NSArray<MarkdownASTNode *> *)nodes;
@end

@implementation EMTextSegment
+ (instancetype)segmentWithNodes:(NSArray<MarkdownASTNode *> *)nodes
{
  EMTextSegment *segment = [[EMTextSegment alloc] init];
  segment.nodes = [nodes copy];
  return segment;
}
@end

@interface EMTableSegment : NSObject
@property (nonatomic, strong) MarkdownASTNode *tableNode;
+ (instancetype)segmentWithTableNode:(MarkdownASTNode *)node;
@end

@implementation EMTableSegment
+ (instancetype)segmentWithTableNode:(MarkdownASTNode *)node
{
  EMTableSegment *segment = [[EMTableSegment alloc] init];
  segment.tableNode = node;
  return segment;
}
@end

@interface EMRenderedTextSegment : NSObject
@property (nonatomic, strong) NSMutableAttributedString *attributedText;
@property (nonatomic, strong) RenderContext *context;
@property (nonatomic, strong) AccessibilityInfo *accessibilityInfo;
@property (nonatomic, assign) CGFloat lastElementMarginBottom;
+ (instancetype)withAttributedText:(NSMutableAttributedString *)text
                           context:(RenderContext *)context
                 accessibilityInfo:(AccessibilityInfo *)info
           lastElementMarginBottom:(CGFloat)marginBottom;
@end

@implementation EMRenderedTextSegment
+ (instancetype)withAttributedText:(NSMutableAttributedString *)text
                           context:(RenderContext *)context
                 accessibilityInfo:(AccessibilityInfo *)info
           lastElementMarginBottom:(CGFloat)marginBottom
{
  EMRenderedTextSegment *segment = [[EMRenderedTextSegment alloc] init];
  segment.attributedText = text;
  segment.context = context;
  segment.accessibilityInfo = info;
  segment.lastElementMarginBottom = marginBottom;
  return segment;
}
@end

@interface EnrichedMarkdown () <RCTEnrichedMarkdownViewProtocol, UITextViewDelegate>
@end

@implementation EnrichedMarkdown {
  ENRMMarkdownParser *_parser;
  StyleConfig *_config;
  ENRMMd4cFlags *_md4cFlags;
  NSString *_cachedMarkdown;
  NSMutableArray<UIView *> *_segmentViews;

  dispatch_queue_t _renderQueue;
  NSUInteger _currentRenderId;
  BOOL _blockAsyncRender;

  EnrichedMarkdownShadowNode::ConcreteState::Shared _state;
  int _heightUpdateCounter;

  FontScaleObserver *_fontScaleObserver;
  CGFloat _maxFontSizeMultiplier;

  BOOL _allowTrailingMargin;
  BOOL _selectable;
  BOOL _enableLinkPreview;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<EnrichedMarkdownComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const EnrichedMarkdownProps>();
    _props = defaultProps;

    self.backgroundColor = [UIColor clearColor];
    _parser = [[ENRMMarkdownParser alloc] init];
    _md4cFlags = [ENRMMd4cFlags defaultFlags];
    _segmentViews = [NSMutableArray array];

    _renderQueue = dispatch_queue_create("com.swmansion.enriched.markdown.container.render", DISPATCH_QUEUE_SERIAL);
    _currentRenderId = 0;

    _maxFontSizeMultiplier = 0;
    _allowTrailingMargin = NO;
    _selectable = YES;
    _enableLinkPreview = YES;

    _fontScaleObserver = [[FontScaleObserver alloc] init];
    __weak EnrichedMarkdown *weakSelf = self;
    _fontScaleObserver.onChange = ^{
      EnrichedMarkdown *strongSelf = weakSelf;
      if (!strongSelf)
        return;
      if (strongSelf->_config != nil) {
        [strongSelf->_config setFontScaleMultiplier:strongSelf->_fontScaleObserver.effectiveFontScale];
      }
      if (strongSelf->_cachedMarkdown != nil && strongSelf->_cachedMarkdown.length > 0) {
        [strongSelf renderMarkdownContent:strongSelf->_cachedMarkdown];
      }
    };
  }
  return self;
}

- (CGFloat)computeSegmentLayoutForWidth:(CGFloat)width applyFrames:(BOOL)applyFrames
{
  if (_segmentViews.count == 0)
    return 0.0;

  __block CGFloat yOffset = 0.0;
  const NSUInteger lastIndex = _segmentViews.count - 1;

  [_segmentViews enumerateObjectsUsingBlock:^(UIView *segment, NSUInteger i, BOOL *stop) {
    const BOOL isLast = (i == lastIndex);
    const BOOL shouldAddBottomMargin = (!isLast || _allowTrailingMargin);

    CGFloat segmentHeight = 0;

    if ([segment isKindOfClass:[EnrichedMarkdownInternalText class]]) {
      EnrichedMarkdownInternalText *textView = (EnrichedMarkdownInternalText *)segment;
      textView.allowTrailingMargin = shouldAddBottomMargin;
      segmentHeight = [textView measureHeight:width];

    } else if ([segment isKindOfClass:[TableContainerView class]]) {
      yOffset += _config.tableMarginTop;
      segmentHeight = [(TableContainerView *)segment measureHeight:width];
    }

    if (applyFrames) {
      segment.frame = CGRectMake(0, yOffset, width, segmentHeight);
    }

    yOffset += segmentHeight;

    if ([segment isKindOfClass:[TableContainerView class]] && shouldAddBottomMargin) {
      yOffset += _config.tableMarginBottom;
    }
  }];

  return yOffset;
}

- (CGSize)measureSize:(CGFloat)maxWidth
{
  CGFloat defaultHeight = [UIFont systemFontOfSize:16.0].lineHeight;
  CGFloat totalHeight = [self computeSegmentLayoutForWidth:maxWidth applyFrames:NO];
  if (totalHeight == 0)
    return CGSizeMake(maxWidth, defaultHeight);

  // Round to pixel boundaries to match React Native's <Text> measurement
  CGFloat scale = [UIScreen mainScreen].scale;
  return CGSizeMake(maxWidth, ceil(totalHeight * scale) / scale);
}

- (void)updateState:(const facebook::react::State::Shared &)state
           oldState:(const facebook::react::State::Shared &)oldState
{
  _state = std::static_pointer_cast<const EnrichedMarkdownShadowNode::ConcreteState>(state);

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
  _state->updateState(EnrichedMarkdownState(_heightUpdateCounter, selfRef));
}

- (NSArray *)splitASTIntoSegments:(MarkdownASTNode *)root
{
  NSMutableArray *segments = [NSMutableArray array];
  NSMutableArray *currentTextNodes = [NSMutableArray array];

  for (MarkdownASTNode *child in root.children) {
    if (child.type == MarkdownNodeTypeTable) {
      if (currentTextNodes.count > 0) {
        [segments addObject:[EMTextSegment segmentWithNodes:[currentTextNodes copy]]];
        [currentTextNodes removeAllObjects];
      }
      [segments addObject:[EMTableSegment segmentWithTableNode:child]];
    } else {
      [currentTextNodes addObject:child];
    }
  }

  if (currentTextNodes.count > 0) {
    [segments addObject:[EMTextSegment segmentWithNodes:currentTextNodes]];
  }

  return segments;
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

    NSArray *segments = [self splitASTIntoSegments:ast];

    NSMutableArray *renderedSegments = [NSMutableArray array];

    for (id segment in segments) {
      if ([segment isKindOfClass:[EMTextSegment class]]) {
        EMRenderedTextSegment *rendered = [self renderTextSegment:(EMTextSegment *)segment
                                                           config:config
                                              allowTrailingMargin:allowTrailingMargin
                                                 allowFontScaling:allowFontScaling
                                            maxFontSizeMultiplier:maxFontSizeMultiplier];
        [renderedSegments addObject:rendered];
      } else if ([segment isKindOfClass:[EMTableSegment class]]) {
        [renderedSegments addObject:segment];
      }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      if (renderId != self->_currentRenderId) {
        return;
      }

      [self applyRenderedSegments:renderedSegments];
    });
  });
}

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

  NSArray *segments = [self splitASTIntoSegments:ast];

  for (id segment in segments) {
    if ([segment isKindOfClass:[EMTextSegment class]]) {
      EMRenderedTextSegment *rendered = [self renderTextSegment:(EMTextSegment *)segment
                                                         config:_config
                                            allowTrailingMargin:_allowTrailingMargin
                                               allowFontScaling:_fontScaleObserver.allowFontScaling
                                          maxFontSizeMultiplier:_maxFontSizeMultiplier];
      EnrichedMarkdownInternalText *view = [self createTextViewForRenderedSegment:rendered];
      [_segmentViews addObject:view];
      [self addSubview:view];
    } else if ([segment isKindOfClass:[EMTableSegment class]]) {
      EMTableSegment *tableSegment = (EMTableSegment *)segment;
      TableContainerView *tableView = [self createTableViewForSegment:tableSegment];
      [_segmentViews addObject:tableView];
      [self addSubview:tableView];
    }
  }
}

- (void)applyRenderedSegments:(NSArray *)renderedSegments
{
  for (UIView *view in _segmentViews) {
    [view removeFromSuperview];
  }
  [_segmentViews removeAllObjects];

  for (id segment in renderedSegments) {
    if ([segment isKindOfClass:[EMRenderedTextSegment class]]) {
      EnrichedMarkdownInternalText *view = [self createTextViewForRenderedSegment:(EMRenderedTextSegment *)segment];
      [_segmentViews addObject:view];
      [self addSubview:view];
    } else if ([segment isKindOfClass:[EMTableSegment class]]) {
      EMTableSegment *tableSegment = (EMTableSegment *)segment;
      TableContainerView *tableView = [self createTableViewForSegment:tableSegment];
      [_segmentViews addObject:tableView];
      [self addSubview:tableView];
    }
  }

  [self requestHeightUpdate];
  [self setNeedsLayout];
}

- (EMRenderedTextSegment *)renderTextSegment:(EMTextSegment *)textSegment
                                      config:(StyleConfig *)config
                         allowTrailingMargin:(BOOL)allowTrailingMargin
                            allowFontScaling:(BOOL)allowFontScaling
                       maxFontSizeMultiplier:(CGFloat)maxFontSizeMultiplier
{
  MarkdownASTNode *temporaryRoot = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
  for (MarkdownASTNode *node in textSegment.nodes) {
    [temporaryRoot addChild:node];
  }

  AttributedRenderer *renderer = [[AttributedRenderer alloc] initWithConfig:config];
  [renderer setAllowTrailingMargin:allowTrailingMargin];
  RenderContext *context = [RenderContext new];
  context.allowFontScaling = allowFontScaling;
  context.maxFontSizeMultiplier = maxFontSizeMultiplier;
  NSMutableAttributedString *attributedText = [renderer renderRoot:temporaryRoot context:context];

  CGFloat lastMarginBottom = [renderer getLastElementMarginBottom];
  AccessibilityInfo *accessibilityInfo = [AccessibilityInfo infoFromContext:context];

  return [EMRenderedTextSegment withAttributedText:attributedText
                                           context:context
                                 accessibilityInfo:accessibilityInfo
                           lastElementMarginBottom:lastMarginBottom];
}

- (EnrichedMarkdownInternalText *)createTextViewForRenderedSegment:(EMRenderedTextSegment *)segment
{
  EnrichedMarkdownInternalText *view = [[EnrichedMarkdownInternalText alloc] initWithConfig:_config];
  view.allowTrailingMargin = _allowTrailingMargin;
  view.lastElementMarginBottom = segment.lastElementMarginBottom;
  view.accessibilityInfo = segment.accessibilityInfo;
  view.textView.selectable = _selectable;
  [view applyAttributedText:segment.attributedText context:segment.context];

  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(textTapped:)];
  [view.textView addGestureRecognizer:tapRecognizer];
  view.textView.delegate = self;

  return view;
}

- (TableContainerView *)createTableViewForSegment:(EMTableSegment *)tableSegment
{
  TableContainerView *tableView = [[TableContainerView alloc] initWithConfig:_config];

  tableView.allowFontScaling = _fontScaleObserver.allowFontScaling;
  tableView.maxFontSizeMultiplier = _maxFontSizeMultiplier;
  tableView.enableLinkPreview = _enableLinkPreview;

  __weak EnrichedMarkdown *weakSelf = self;

  tableView.onLinkPress = ^(NSString *url) {
    EnrichedMarkdown *strongSelf = weakSelf;
    if (!strongSelf || !url)
      return;

    auto eventEmitter = std::static_pointer_cast<EnrichedMarkdownEventEmitter const>(strongSelf->_eventEmitter);
    if (eventEmitter) {
      eventEmitter->onLinkPress({.url = std::string([url UTF8String])});
    }
  };

  tableView.onLinkLongPress = ^(NSString *url) {
    EnrichedMarkdown *strongSelf = weakSelf;
    if (!strongSelf || !url)
      return;

    auto eventEmitter = std::static_pointer_cast<EnrichedMarkdownEventEmitter const>(strongSelf->_eventEmitter);
    if (eventEmitter) {
      eventEmitter->onLinkLongPress({.url = std::string([url UTF8String])});
    }
  };

  [tableView applyTableNode:tableSegment.tableNode];

  return tableView;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [self computeSegmentLayoutForWidth:self.bounds.size.width applyFrames:YES];
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<EnrichedMarkdownProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<EnrichedMarkdownProps const>(props);

  BOOL stylePropChanged = NO;

  if (_config == nil) {
    _config = [[StyleConfig alloc] init];
    [_config setFontScaleMultiplier:_fontScaleObserver.effectiveFontScale];
  }

  stylePropChanged = applyMarkdownStyleToConfig(_config, newViewProps.markdownStyle, oldViewProps.markdownStyle);

  _selectable = newViewProps.selectable;

  for (UIView *segment in _segmentViews) {
    if ([segment isKindOfClass:[EnrichedMarkdownInternalText class]]) {
      EnrichedMarkdownInternalText *textSegment = (EnrichedMarkdownInternalText *)segment;
      if (textSegment.textView.selectable != newViewProps.selectable) {
        textSegment.textView.selectable = newViewProps.selectable;
      }
    }
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

Class<RCTComponentViewProtocol> EnrichedMarkdownCls(void)
{
  return EnrichedMarkdown.class;
}

- (void)textTapped:(UITapGestureRecognizer *)recognizer
{
  UITextView *textView = (UITextView *)recognizer.view;

  if (handleTaskListTapWithSharedLogic(
          textView, recognizer, &self->_cachedMarkdown, self->_config,
          ^(NSInteger index, BOOL checked, NSString *itemText) {
            auto eventEmitter = std::static_pointer_cast<EnrichedMarkdownEventEmitter const>(self->_eventEmitter);
            if (eventEmitter) {
              eventEmitter->onTaskListItemPress({
                  .index = (int)index,
                  .checked = checked,
                  .text = std::string([itemText UTF8String] ?: ""),
              });
            }
          },
          ^(NSString *updatedMarkdown) { [self renderMarkdownContent:updatedMarkdown]; })) {
    return;
  }

  NSString *url = linkURLAtTapLocation(textView, recognizer);
  if (url) {
    auto eventEmitter = std::static_pointer_cast<EnrichedMarkdownEventEmitter const>(_eventEmitter);
    if (eventEmitter) {
      eventEmitter->onLinkPress({.url = std::string([url UTF8String])});
    }
  }
}

- (UIMenu *)textView:(UITextView *)textView
    editMenuForTextInRange:(NSRange)range
          suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
  NSString *segmentMarkdown = extractMarkdownFromAttributedString(textView.attributedText, range);
  return buildEditMenuForSelection(textView.attributedText, range, segmentMarkdown, _config, suggestedActions);
}

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

  auto eventEmitter = std::static_pointer_cast<EnrichedMarkdownEventEmitter const>(_eventEmitter);
  if (eventEmitter) {
    eventEmitter->onLinkLongPress({.url = std::string([urlString UTF8String])});
  }
  return NO;
}

- (BOOL)isAccessibilityElement
{
  return NO;
}

- (NSArray *)accessibilityElements
{
  NSMutableArray *allElements = [NSMutableArray array];
  for (UIView *segment in _segmentViews) {
    if ([segment isKindOfClass:[EnrichedMarkdownInternalText class]]) {
      NSArray *elements = [(EnrichedMarkdownInternalText *)segment accessibilityElements];
      if (elements) {
        [allElements addObjectsFromArray:elements];
      }
    } else if ([segment isKindOfClass:[TableContainerView class]]) {
      NSArray *elements = [(TableContainerView *)segment accessibilityElements];
      if (elements) {
        [allElements addObjectsFromArray:elements];
      }
    }
  }
  return allElements;
}

- (NSInteger)accessibilityElementCount
{
  return [self accessibilityElements].count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
  NSArray *elements = [self accessibilityElements];
  if (index < 0 || index >= (NSInteger)elements.count) {
    return nil;
  }
  return elements[index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
  return [[self accessibilityElements] indexOfObject:element];
}

- (NSArray<UIAccessibilityCustomRotor *> *)accessibilityCustomRotors
{
  return [MarkdownAccessibilityElementBuilder buildRotorsFromElements:[self accessibilityElements]];
}

@end
