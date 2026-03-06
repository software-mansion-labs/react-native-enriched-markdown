#import "ENRMMathContainerView.h"
#import <IosMath/IosMath.h>

@interface ENRMMathContainerView () <UIContextMenuInteractionDelegate>
@property (nonatomic, strong, readonly) MTMathUILabel *mathLabel;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, copy, readwrite) NSString *cachedLatex;
@end

@implementation ENRMMathContainerView

- (instancetype)initWithConfig:(StyleConfig *)config
{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _config = config;
    _cachedLatex = @"";

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = YES;
    _scrollView.bounces = YES;
    _scrollView.alwaysBounceHorizontal = NO;
    [self addSubview:_scrollView];

    _mathLabel = [[MTMathUILabel alloc] init];
    _mathLabel.labelMode = kMTMathUILabelModeDisplay;
    [_scrollView addSubview:_mathLabel];

    self.isAccessibilityElement = YES;

    UIContextMenuInteraction *contextMenu = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [self addInteraction:contextMenu];
  }
  return self;
}

- (void)applyLatex:(NSString *)latex
{
  _cachedLatex = [latex copy];

  StyleConfig *config = self.config;

  _mathLabel.latex = latex;
  _mathLabel.fontSize = config.mathFontSize;
  _mathLabel.textColor = config.mathColor;
  _mathLabel.textAlignment = [self mapAlignment:config.mathTextAlign];

  CGFloat padding = config.mathPadding;
  _mathLabel.contentInsets = UIEdgeInsetsMake(padding, padding, padding, padding);

  self.backgroundColor = config.mathBackgroundColor ?: [UIColor clearColor];

  [self setNeedsLayout];
}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction
                        configurationForMenuAtLocation:(CGPoint)location
{
  return [UIContextMenuConfiguration
      configurationWithIdentifier:nil
                  previewProvider:nil
                   actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
                     UIAction *copyPlainText =
                         [UIAction actionWithTitle:@"Copy"
                                             image:[UIImage systemImageNamed:@"doc.on.doc"]
                                        identifier:nil
                                           handler:^(__kindof UIAction *action) { [self copyLatexToPasteboard]; }];

                     UIAction *copyMarkdown =
                         [UIAction actionWithTitle:@"Copy as Markdown"
                                             image:[UIImage systemImageNamed:@"doc.text"]
                                        identifier:nil
                                           handler:^(__kindof UIAction *action) { [self copyMarkdownToPasteboard]; }];

                     return [UIMenu menuWithTitle:@"" children:@[ copyPlainText, copyMarkdown ]];
                   }];
}

- (void)copyLatexToPasteboard
{
  [[UIPasteboard generalPasteboard] setString:_cachedLatex];
}

- (void)copyMarkdownToPasteboard
{
  NSString *markdown = [NSString stringWithFormat:@"$$\n%@\n$$", _cachedLatex];
  [[UIPasteboard generalPasteboard] setString:markdown];
}

- (MTTextAlignment)mapAlignment:(NSString *)align
{
  if ([align isEqualToString:@"left"])
    return kMTTextAlignmentLeft;
  if ([align isEqualToString:@"right"])
    return kMTTextAlignmentRight;
  return kMTTextAlignmentCenter;
}

- (CGFloat)measureHeight:(CGFloat)maxWidth
{
  CGSize intrinsicSize = [_mathLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
  return intrinsicSize.height;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGSize intrinsicSize = [_mathLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
  CGFloat contentWidth = MAX(intrinsicSize.width, self.bounds.size.width);
  CGFloat contentHeight = self.bounds.size.height;

  _scrollView.frame = self.bounds;
  _scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
  _scrollView.scrollEnabled = (intrinsicSize.width > self.bounds.size.width);
  _mathLabel.frame = CGRectMake(0, 0, contentWidth, contentHeight);
}

- (NSString *)accessibilityLabel
{
  return [NSString stringWithFormat:@"Math equation: %@", _cachedLatex];
}

- (UIAccessibilityTraits)accessibilityTraits
{
  return UIAccessibilityTraitStaticText;
}

@end