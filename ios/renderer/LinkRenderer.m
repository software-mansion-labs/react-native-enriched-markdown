#import "LinkRenderer.h"
#import "FontUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"
#import <React/RCTFont.h>

NSString *const ENRMMentionURLAttributeName = @"ENRMMentionURL";
NSString *const ENRMMentionTextAttributeName = @"ENRMMentionText";
NSString *const ENRMCitationURLAttributeName = @"ENRMCitationURL";
NSString *const ENRMCitationTextAttributeName = @"ENRMCitationText";

static NSString *const kMentionScheme = @"mention://";
static NSString *const kCitationScheme = @"citation://";

@implementation LinkRenderer {
  RendererFactory *_rendererFactory;
  StyleConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  self = [super init];
  if (self) {
    _rendererFactory = rendererFactory;
    _config = (StyleConfig *)config;
  }
  return self;
}

#pragma mark - Scheme helpers

static BOOL isMentionURL(NSString *url)
{
  return [url hasPrefix:kMentionScheme];
}

static BOOL isCitationURL(NSString *url)
{
  return [url hasPrefix:kCitationScheme];
}

static NSString *stripScheme(NSString *url, NSString *scheme)
{
  if ([url hasPrefix:scheme]) {
    return [url substringFromIndex:scheme.length];
  }
  return url;
}

#pragma mark - Rendering

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  NSString *url = node.attributes[@"url"] ?: @"";

  if (isMentionURL(url)) {
    [self renderMentionNode:node url:url into:output context:context];
    return;
  }

  if (isCitationURL(url)) {
    [self renderCitationNode:node url:url into:output context:context];
    return;
  }

  [self renderLinkNode:node url:url into:output context:context];
}

#pragma mark - Link (default / existing behavior)

- (void)renderLinkNode:(MarkdownASTNode *)node
                   url:(NSString *)url
                  into:(NSMutableAttributedString *)output
               context:(RenderContext *)context
{
  NSUInteger start = output.length;

  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  NSRange range = NSMakeRange(start, output.length - start);
  if (range.length == 0)
    return;

  RCTUIColor *linkColor = [_config linkColor];
  NSNumber *underlineStyle = @([_config linkUnderline] ? NSUnderlineStyleSingle : NSUnderlineStyleNone);
  NSString *linkFontFamily = [_config linkFontFamily];

  [output addAttribute:NSLinkAttributeName value:url range:range];

  [output enumerateAttributesInRange:range
                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                          usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange subrange, BOOL *stop) {
                            NSMutableDictionary *newAttributes = [NSMutableDictionary dictionary];

                            if (linkColor && ![attrs[NSForegroundColorAttributeName] isEqual:linkColor]) {
                              newAttributes[NSForegroundColorAttributeName] = linkColor;
                              newAttributes[NSUnderlineColorAttributeName] = linkColor;
                            }

                            if (![attrs[NSUnderlineStyleAttributeName] isEqual:underlineStyle]) {
                              newAttributes[NSUnderlineStyleAttributeName] = underlineStyle;
                            }

                            if (linkFontFamily.length > 0) {
                              UIFont *currentFont = attrs[NSFontAttributeName];
                              if (currentFont) {
                                UIFont *linkFont = [RCTFont updateFont:currentFont
                                                            withFamily:linkFontFamily
                                                                  size:nil
                                                                weight:nil
                                                                 style:nil
                                                               variant:nil
                                                       scaleMultiplier:1.0];
                                if (linkFont && ![currentFont isEqual:linkFont]) {
                                  newAttributes[NSFontAttributeName] = linkFont;
                                }
                              }
                            }

                            if (newAttributes.count > 0) {
                              [output addAttributes:newAttributes range:subrange];
                            }
                          }];

  [context registerLinkRange:range url:url];
}

#pragma mark - Mention

- (void)renderMentionNode:(MarkdownASTNode *)node
                      url:(NSString *)url
                     into:(NSMutableAttributedString *)output
                  context:(RenderContext *)context
{
  // Collapse children into a plain display string. The pill itself is rendered
  // as inline text (not an NSTextAttachment), so native copy/paste/selection
  // behave exactly like normal text — the "pill" look is painted by
  // `MentionBackground` during the layout manager's draw cycle.
  NSMutableAttributedString *childBuffer = [[NSMutableAttributedString alloc] init];
  [_rendererFactory renderChildrenOfNode:node into:childBuffer context:context];
  NSString *displayText = childBuffer.string ?: @"";
  if (displayText.length == 0)
    return;

  NSString *mentionURL = stripScheme(url, kMentionScheme);

  // Inherit surrounding paragraph attributes so the pill text participates in
  // the current line's metrics.
  NSDictionary *baseAttrs = output.length > 0 ? [output attributesAtIndex:output.length - 1 effectiveRange:NULL] : @{};
  NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:baseAttrs];

  UIFont *mentionFont = [_config mentionFont];
  if (mentionFont) {
    attrs[NSFontAttributeName] = mentionFont;
  }
  RCTUIColor *mentionColor = [_config mentionColor];
  if (mentionColor) {
    attrs[NSForegroundColorAttributeName] = mentionColor;
  }
  attrs[ENRMMentionURLAttributeName] = mentionURL;
  attrs[ENRMMentionTextAttributeName] = displayText;

  NSUInteger start = output.length;
  [output appendAttributedString:[[NSAttributedString alloc] initWithString:displayText attributes:attrs]];
  NSRange outputRange = NSMakeRange(start, output.length - start);

  // The drawn pill extends `paddingHorizontal` beyond the glyph run on each
  // side. Inline text doesn't reserve any advance for that visual padding, so
  // two adjacent mentions (separated only by a space) would have their pills
  // visually overlap. Stamping NSKern on the last glyph pushes the following
  // character away by the same amount the pill extends, matching what CSS
  // `paddingInline` does on web.
  CGFloat mentionPaddingH = [_config mentionPaddingHorizontal];
  if (mentionPaddingH > 0 && outputRange.length > 0) {
    NSRange lastCharRange = NSMakeRange(NSMaxRange(outputRange) - 1, 1);
    [output addAttribute:NSKernAttributeName value:@(mentionPaddingH * 2) range:lastCharRange];
  }

  [context registerMentionRange:outputRange url:mentionURL text:displayText];
}

#pragma mark - Citation

- (void)renderCitationNode:(MarkdownASTNode *)node
                       url:(NSString *)url
                      into:(NSMutableAttributedString *)output
                   context:(RenderContext *)context
{
  NSUInteger start = output.length;
  [_rendererFactory renderChildrenOfNode:node into:output context:context];
  NSRange range = NSMakeRange(start, output.length - start);
  if (range.length == 0)
    return;

  NSString *targetURL = stripScheme(url, kCitationScheme);
  NSString *labelText = [[output attributedSubstringFromRange:range] string] ?: @"";

  CGFloat multiplier = [_config citationFontSizeMultiplier];
  CGFloat baselineOffsetPx = [_config citationBaselineOffsetPx];
  RCTUIColor *citationColor = [_config citationColor];
  NSString *fontWeight = [_config citationFontWeight];
  BOOL underline = [_config citationUnderline];
  CGFloat paddingHorizontal = [_config citationPaddingHorizontal];

  [output enumerateAttributesInRange:range
                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                          usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange subrange, BOOL *stop) {
                            NSMutableDictionary *newAttributes = [NSMutableDictionary dictionary];

                            UIFont *currentFont = attrs[NSFontAttributeName];
                            if (currentFont && multiplier > 0) {
                              CGFloat newSize = currentFont.pointSize * multiplier;
                              UIFont *scaled = [RCTFont updateFont:currentFont
                                                        withFamily:nil
                                                              size:@(newSize)
                                                            weight:fontWeight.length > 0 ? fontWeight : nil
                                                             style:nil
                                                           variant:nil
                                                   scaleMultiplier:1.0];
                              if (scaled) {
                                newAttributes[NSFontAttributeName] = scaled;

                                CGFloat offset = baselineOffsetPx;
                                if (offset == 0) {
                                  offset = (currentFont.capHeight - scaled.capHeight) * 0.5;
                                }
                                newAttributes[NSBaselineOffsetAttributeName] = @(offset);
                              }
                            } else if (baselineOffsetPx != 0) {
                              newAttributes[NSBaselineOffsetAttributeName] = @(baselineOffsetPx);
                            }

                            if (citationColor) {
                              newAttributes[NSForegroundColorAttributeName] = citationColor;
                            }

                            if (underline) {
                              newAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                              if (citationColor) {
                                newAttributes[NSUnderlineColorAttributeName] = citationColor;
                              }
                            }

                            if (newAttributes.count > 0) {
                              [output addAttributes:newAttributes range:subrange];
                            }
                          }];

  [output addAttribute:ENRMCitationURLAttributeName value:targetURL range:range];
  [output addAttribute:ENRMCitationTextAttributeName value:labelText range:range];

  // The drawn chip background extends `paddingHorizontal` beyond the glyph run
  // on each side. Inline text doesn't reserve any advance for that visual
  // padding, so adjacent citations (and following text) would sit right up
  // against our glyphs, causing the drawn chips to overlap. Applying NSKern
  // on the last character adds the missing trailing advance so consecutive
  // chips have the same natural spacing they'd get on web via CSS padding.
  if (paddingHorizontal > 0 && range.length > 0) {
    NSRange lastCharRange = NSMakeRange(NSMaxRange(range) - 1, 1);
    [output addAttribute:NSKernAttributeName value:@(paddingHorizontal * 2) range:lastCharRange];
  }

  [context registerCitationRange:range url:targetURL text:labelText];
}

@end
