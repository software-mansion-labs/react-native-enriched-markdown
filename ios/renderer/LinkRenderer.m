#import "LinkRenderer.h"
#import "ENRMCitationAttachment.h"
#import "ENRMMentionAttachment.h"
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
  // Extract the child text to use as the pill label; the child nodes may be
  // formatted text (e.g. **bold**), so we collapse to a plain string.
  NSMutableAttributedString *childBuffer = [[NSMutableAttributedString alloc] init];
  [_rendererFactory renderChildrenOfNode:node into:childBuffer context:context];
  NSString *displayText = childBuffer.string ?: @"";
  NSString *mentionURL = stripScheme(url, kMentionScheme);

  // Inherit the current text attributes (font, color) so the pill sits in the
  // same line metrics as the surrounding paragraph if the pill label has no
  // explicit style override.
  NSDictionary *baseAttrs = output.length > 0 ? [output attributesAtIndex:output.length - 1 effectiveRange:NULL] : @{};

  ENRMMentionAttachment *attachment = [ENRMMentionAttachment attachmentWithDisplayText:displayText
                                                                                   url:mentionURL
                                                                                config:_config];

  NSMutableAttributedString *attachmentString =
      [[NSMutableAttributedString attributedStringWithAttachment:attachment] mutableCopy];
  NSRange attachmentRange = NSMakeRange(0, attachmentString.length);
  if (baseAttrs.count > 0) {
    [attachmentString addAttributes:baseAttrs range:attachmentRange];
  }
  [attachmentString addAttribute:ENRMMentionURLAttributeName value:mentionURL range:attachmentRange];
  [attachmentString addAttribute:ENRMMentionTextAttributeName value:displayText range:attachmentRange];

  NSUInteger start = output.length;
  [output appendAttributedString:attachmentString];
  NSRange outputRange = NSMakeRange(start, output.length - start);

  [context registerMentionRange:outputRange url:mentionURL text:displayText];
}

#pragma mark - Citation

- (void)renderCitationNode:(MarkdownASTNode *)node
                       url:(NSString *)url
                      into:(NSMutableAttributedString *)output
                   context:(RenderContext *)context
{
  // Render children into a throwaway buffer so we can collect the label text
  // and inherit the surrounding font (used to scale the citation glyph).
  NSMutableAttributedString *childBuffer = [[NSMutableAttributedString alloc] init];
  [_rendererFactory renderChildrenOfNode:node into:childBuffer context:context];
  NSString *displayText = childBuffer.string ?: @"";
  NSString *targetURL = stripScheme(url, kCitationScheme);

  NSDictionary *baseAttrs = output.length > 0 ? [output attributesAtIndex:output.length - 1 effectiveRange:NULL] : @{};
  UIFont *baseFont = baseAttrs[NSFontAttributeName];

  ENRMCitationAttachment *attachment = [ENRMCitationAttachment attachmentWithDisplayText:displayText
                                                                                     url:targetURL
                                                                                baseFont:baseFont
                                                                                  config:_config];

  NSMutableAttributedString *attachmentString =
      [[NSMutableAttributedString attributedStringWithAttachment:attachment] mutableCopy];
  NSRange attachmentRange = NSMakeRange(0, attachmentString.length);
  if (baseAttrs.count > 0) {
    [attachmentString addAttributes:baseAttrs range:attachmentRange];
  }
  [attachmentString addAttribute:ENRMCitationURLAttributeName value:targetURL range:attachmentRange];
  [attachmentString addAttribute:ENRMCitationTextAttributeName value:displayText range:attachmentRange];

  NSUInteger start = output.length;
  [output appendAttributedString:attachmentString];
  NSRange outputRange = NSMakeRange(start, output.length - start);

  [context registerCitationRange:outputRange url:targetURL text:displayText];
}

@end
