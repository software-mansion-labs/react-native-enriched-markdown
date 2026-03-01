#import "ENRMMathContainerView.h"
#import <IosMath/IosMath.h>

@interface ENRMMathContainerView () <UIContextMenuInteractionDelegate>
@property (nonatomic, strong, readonly) MTMathUILabel *mathLabel;
@property (nonatomic, copy, readwrite) NSString *cachedLatex;
@end

@implementation ENRMMathContainerView

- (instancetype)initWithConfig:(StyleConfig *)config
{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _config = config;
    _cachedLatex = @"";
    _mathLabel = [[MTMathUILabel alloc] init];
    _mathLabel.labelMode = kMTMathUILabelModeDisplay;

    self.isAccessibilityElement = YES;

    UIContextMenuInteraction *contextMenu = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [self addInteraction:contextMenu];

    [self addSubview:_mathLabel];
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

#pragma mark - Context Menu

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
  CGSize fittingSize = [_mathLabel sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
  return fittingSize.height;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _mathLabel.frame = self.bounds;
}

- (NSString *)accessibilityLabel
{
  return [NSString stringWithFormat:@"Math equation: %@", _mathLabel.latex ?: @"empty"];
}

- (UIAccessibilityTraits)accessibilityTraits
{
  return UIAccessibilityTraitStaticText;
}

@end