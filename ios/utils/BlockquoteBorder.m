#import "BlockquoteBorder.h"
#import "StyleConfig.h"

NSString *const RichTextBlockquoteDepthAttributeName = @"RichTextBlockquoteDepth";
NSString *const RichTextBlockquoteBackgroundColorAttributeName = @"RichTextBlockquoteBackgroundColor";

static NSString *const kFragmentRectKey = @"rect";
static NSString *const kFragmentDepthKey = @"depth";
static NSString *const kFragmentDepthLocationKey = @"depthLocation";
static NSString *const kFragmentIsSpacerKey = @"isSpacer";

@implementation BlockquoteBorder {
  StyleConfig *_config;
}

- (instancetype)initWithConfig:(StyleConfig *)config
{
  if (self = [super init]) {
    _config = config;
  }
  return self;
}

- (void)drawBordersForGlyphRange:(NSRange)glyphsToShow
                   layoutManager:(NSLayoutManager *)layoutManager
                   textContainer:(NSTextContainer *)textContainer
                         atPoint:(CGPoint)origin
{
  NSTextStorage *textStorage = layoutManager.textStorage;
  if (!textStorage || textStorage.length == 0)
    return;

  UIColor *borderColor = [_config blockquoteBorderColor];
  CGFloat borderWidth = [_config blockquoteBorderWidth];
  CGFloat levelSpacing = borderWidth + [_config blockquoteGapWidth];
  CGFloat nestedMarginBottom = [_config blockquoteNestedMarginBottom];
  CGFloat containerWidth = textContainer.size.width;

  NSMutableArray<NSDictionary *> *fragments = [NSMutableArray array];
  NSMutableDictionary<NSNumber *, NSNumber *> *firstCharIndexForDepth = [NSMutableDictionary dictionary];

  [layoutManager
      enumerateLineFragmentsForGlyphRange:glyphsToShow
                               usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *container,
                                            NSRange glyphRange, BOOL *stop) {
                                 NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphRange
                                                                               actualGlyphRange:NULL];
                                 if (charRange.location == NSNotFound || charRange.length == 0) {
                                   return;
                                 }

                                 NSNumber *depth = [textStorage attribute:RichTextBlockquoteDepthAttributeName
                                                                  atIndex:charRange.location
                                                           effectiveRange:NULL];
                                 if (!depth) {
                                   return;
                                 }

                                 NSUInteger charLocation = charRange.location;
                                 BOOL isSpacer = nestedMarginBottom > 0
                                                     ? [self isSpacerAtLocation:charLocation textStorage:textStorage]
                                                     : NO;

                                 if (nestedMarginBottom > 0 && !firstCharIndexForDepth[depth] && !isSpacer) {
                                   firstCharIndexForDepth[depth] = @(charLocation);
                                 }

                                 [fragments addObject:@{
                                   kFragmentRectKey : [NSValue valueWithCGRect:rect],
                                   @"usedRect" : [NSValue valueWithCGRect:usedRect],
                                   kFragmentDepthKey : depth,
                                   kFragmentDepthLocationKey : @(charLocation),
                                   kFragmentIsSpacerKey : @(isSpacer)
                                 }];
                               }];

  for (NSDictionary *fragment in fragments) {
    [self drawFragment:fragment
                   textStorage:textStorage
                        origin:origin
                  levelSpacing:levelSpacing
            nestedMarginBottom:nestedMarginBottom
        firstCharIndexForDepth:firstCharIndexForDepth
                   borderColor:borderColor
                   borderWidth:borderWidth
                containerWidth:containerWidth];
  }
}

#pragma mark - Helper Methods

- (BOOL)isSpacerAtLocation:(NSUInteger)location textStorage:(NSTextStorage *)textStorage
{
  NSParagraphStyle *paraStyle = [textStorage attribute:NSParagraphStyleAttributeName
                                               atIndex:location
                                        effectiveRange:NULL];
  if (!paraStyle) {
    return NO;
  }
  return (paraStyle.headIndent == 0 && paraStyle.minimumLineHeight > 0 &&
          fabs(paraStyle.minimumLineHeight - paraStyle.maximumLineHeight) < 0.001);
}

- (void)drawFragment:(NSDictionary *)fragment
               textStorage:(NSTextStorage *)textStorage
                    origin:(CGPoint)origin
              levelSpacing:(CGFloat)levelSpacing
        nestedMarginBottom:(CGFloat)nestedMarginBottom
    firstCharIndexForDepth:(NSDictionary<NSNumber *, NSNumber *> *)firstCharIndexForDepth
               borderColor:(UIColor *)borderColor
               borderWidth:(CGFloat)borderWidth
            containerWidth:(CGFloat)containerWidth
{
  CGRect rect = [fragment[kFragmentRectKey] CGRectValue];
  NSInteger depth = [fragment[kFragmentDepthKey] integerValue];
  NSUInteger charLocation = [fragment[kFragmentDepthLocationKey] unsignedIntegerValue];
  BOOL isSpacer = [fragment[kFragmentIsSpacerKey] boolValue];
  CGFloat baseY = origin.y + rect.origin.y;

  UIColor *backgroundColor = [textStorage attribute:RichTextBlockquoteBackgroundColorAttributeName
                                            atIndex:charLocation
                                     effectiveRange:NULL]
                                 ?: [_config blockquoteBackgroundColor];
  if (backgroundColor && backgroundColor != [UIColor clearColor]) {
    CGRect bgRect = CGRectMake(origin.x, baseY, containerWidth, rect.size.height);
    [backgroundColor setFill];
    UIRectFill(bgRect);
  }

  // Border aligns with text content naturally since paragraphSpacing adds space after paragraphs
  for (NSInteger level = 0; level <= depth; level++) {
    CGFloat borderY = baseY;
    CGFloat borderHeight = rect.size.height;
    CGRect borderRect = CGRectMake(origin.x + (levelSpacing * level), borderY, borderWidth, borderHeight);
    [borderColor setFill];
    UIRectFill(borderRect);
  }
}

@end
