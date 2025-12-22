#import "BlockquoteBorder.h"
#import "RichTextConfig.h"

NSString *const RichTextBlockquoteDepthAttributeName = @"RichTextBlockquoteDepth";
NSString *const RichTextBlockquoteBackgroundColorAttributeName = @"RichTextBlockquoteBackgroundColor";

@implementation BlockquoteBorder {
  RichTextConfig *_config;
}

- (instancetype)initWithConfig:(RichTextConfig *)config
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
  if (!borderColor || borderWidth <= 0)
    return;

  CGFloat levelSpacing = borderWidth + [_config blockquoteGapWidth];
  CGFloat nestedMarginBottom = [_config blockquoteNestedMarginBottom];

  // Collect fragments and track first non-spacer character for each depth
  NSMutableArray<NSDictionary *> *fragments = [NSMutableArray array];
  NSMutableDictionary<NSNumber *, NSNumber *> *firstCharIndexForDepth = [NSMutableDictionary dictionary];

  [layoutManager
      enumerateLineFragmentsForGlyphRange:glyphsToShow
                               usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *container,
                                            NSRange glyphRange, BOOL *stop) {
                                 NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphRange
                                                                               actualGlyphRange:NULL];
                                 if (charRange.location == NSNotFound || charRange.length == 0)
                                   return;

                                 NSNumber *depth = nil;
                                 NSUInteger depthLocation = NSNotFound;
                                 [self findDepth:&depth
                                        location:&depthLocation
                                         inRange:charRange
                                     textStorage:textStorage];
                                 if (!depth)
                                   return;

                                 // Check if spacer inline to avoid method call overhead
                                 NSParagraphStyle *paraStyle = [textStorage attribute:NSParagraphStyleAttributeName
                                                                              atIndex:depthLocation
                                                                       effectiveRange:NULL];
                                 BOOL isSpacer =
                                     (paraStyle && paraStyle.headIndent == 0 && paraStyle.minimumLineHeight > 0 &&
                                      fabs(paraStyle.minimumLineHeight - paraStyle.maximumLineHeight) < 0.001);

                                 // Track first non-spacer character for each depth
                                 if (!firstCharIndexForDepth[depth] && !isSpacer) {
                                   firstCharIndexForDepth[depth] = @(depthLocation);
                                 }

                                 [fragments addObject:@{
                                   @"rect" : [NSValue valueWithCGRect:rect],
                                   @"depth" : depth,
                                   @"depthLocation" : @(depthLocation),
                                   @"isSpacer" : @(isSpacer),
                                   @"containerWidth" : @(container.size.width)
                                 }];
                               }];

  // Draw all fragments
  for (NSDictionary *fragment in fragments) {
    [self drawFragment:fragment
                   textStorage:textStorage
                        origin:origin
                  levelSpacing:levelSpacing
            nestedMarginBottom:nestedMarginBottom
        firstCharIndexForDepth:firstCharIndexForDepth
                   borderColor:borderColor
                   borderWidth:borderWidth];
  }
}

#pragma mark - Helper Methods

- (void)findDepth:(NSNumber **)depth
         location:(NSUInteger *)location
          inRange:(NSRange)range
      textStorage:(NSTextStorage *)textStorage
{
  *depth = nil;
  *location = NSNotFound;

  for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
    NSNumber *foundDepth = [textStorage attribute:RichTextBlockquoteDepthAttributeName atIndex:i effectiveRange:NULL];
    if (foundDepth) {
      *depth = foundDepth;
      *location = i;
      return;
    }
  }
}

- (void)drawFragment:(NSDictionary *)fragment
               textStorage:(NSTextStorage *)textStorage
                    origin:(CGPoint)origin
              levelSpacing:(CGFloat)levelSpacing
        nestedMarginBottom:(CGFloat)nestedMarginBottom
    firstCharIndexForDepth:(NSDictionary<NSNumber *, NSNumber *> *)firstCharIndexForDepth
               borderColor:(UIColor *)borderColor
               borderWidth:(CGFloat)borderWidth
{
  // Extract all values once
  CGRect rect = [fragment[@"rect"] CGRectValue];
  NSInteger depth = [fragment[@"depth"] integerValue];
  NSUInteger depthLocation = [fragment[@"depthLocation"] unsignedIntegerValue];
  BOOL isSpacer = [fragment[@"isSpacer"] boolValue];
  CGFloat containerWidth = [fragment[@"containerWidth"] doubleValue];
  CGFloat baseY = origin.y + rect.origin.y;

  // Draw background
  UIColor *backgroundColor = [textStorage attribute:RichTextBlockquoteBackgroundColorAttributeName
                                            atIndex:depthLocation
                                     effectiveRange:NULL]
                                 ?: [_config blockquoteBackgroundColor];
  if (backgroundColor && backgroundColor != [UIColor clearColor]) {
    CGRect bgRect = CGRectMake(origin.x, baseY, containerWidth, rect.size.height);
    [backgroundColor setFill];
    UIRectFill(bgRect);
  }

  // Draw borders for all levels
  BOOL shouldApplyNestedOffset = (nestedMarginBottom > 0 && !isSpacer);
  for (NSInteger level = 0; level <= depth; level++) {
    CGFloat borderY = baseY;
    CGFloat borderHeight = rect.size.height;

    // Apply nested margin offset for first non-spacer line at each depth
    if (level > 0 && shouldApplyNestedOffset) {
      NSNumber *levelKey = @(level);
      NSNumber *firstCharIdx = firstCharIndexForDepth[levelKey];
      if (firstCharIdx && depthLocation == [firstCharIdx unsignedIntegerValue]) {
        borderY += nestedMarginBottom;
        borderHeight = MAX(0, borderHeight - nestedMarginBottom);
      }
    }

    CGRect borderRect = CGRectMake(origin.x + (levelSpacing * level), borderY, borderWidth, borderHeight);
    [borderColor setFill];
    UIRectFill(borderRect);
  }
}

@end
