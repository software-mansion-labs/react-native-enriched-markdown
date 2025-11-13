#import "CodeBackground.h"

NSString *const RichTextCodeAttributeName = @"RichTextCode";

static const CGFloat kCodeBackgroundCornerRadius = 2.0;
static const CGFloat kCodeBackgroundBorderWidth = 1.0;
// Through this variable we could set height for the inline code.
// Potentially this should be removed in the future - when we establish approach for the consistent height
static const CGFloat kCodeBackgroundHeightReductionFactor = 0.0;

@implementation CodeBackground {
    RichTextConfig *_config;
}

- (instancetype)initWithConfig:(RichTextConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
    }
    return self;
}

- (void)drawBackgroundsForGlyphRange:(NSRange)glyphsToShow
                        layoutManager:(NSLayoutManager *)layoutManager
                        textContainer:(NSTextContainer *)textContainer
                               atPoint:(CGPoint)origin {
    UIColor *backgroundColor = _config.codeBackgroundColor;
    if (!backgroundColor) return;
    
    NSTextStorage *textStorage = layoutManager.textStorage;
    if (!textStorage || textStorage.length == 0) return;
    
    NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphsToShow actualGlyphRange:NULL];
    if (charRange.location == NSNotFound || charRange.length == 0) return;
    
    UIColor *borderColor = _config.codeBorderColor;
    
    [textStorage enumerateAttribute:RichTextCodeAttributeName
                             inRange:NSMakeRange(0, textStorage.length)
                             options:0
                          usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value != nil && range.length > 0 && NSIntersectionRange(range, charRange).length > 0) {
            [self drawCodeBackgroundForRange:range
                                   layoutManager:layoutManager
                                   textContainer:textContainer
                                          atPoint:origin
                                 backgroundColor:backgroundColor
                                      borderColor:borderColor];
        }
    }];
}

- (void)drawCodeBackgroundForRange:(NSRange)range
                     layoutManager:(NSLayoutManager *)layoutManager
                     textContainer:(NSTextContainer *)textContainer
                            atPoint:(CGPoint)origin
                   backgroundColor:(UIColor *)backgroundColor
                        borderColor:(UIColor *)borderColor {
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
    if (glyphRange.location == NSNotFound || glyphRange.length == 0) return;
    
    NSRange lineRange, lastLineRange;
    [layoutManager lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:&lineRange];
    [layoutManager lineFragmentRectForGlyphAtIndex:NSMaxRange(glyphRange) - 1 effectiveRange:&lastLineRange];
    
    if (NSEqualRanges(lineRange, lastLineRange)) {
        [self drawSingleLineBackground:glyphRange layoutManager:layoutManager textContainer:textContainer
                                atPoint:origin backgroundColor:backgroundColor borderColor:borderColor];
    } else {
        [self drawMultiLineBackground:glyphRange layoutManager:layoutManager textContainer:textContainer
                               atPoint:origin backgroundColor:backgroundColor borderColor:borderColor];
    }
}

- (void)drawSingleLineBackground:(NSRange)glyphRange
                   layoutManager:(NSLayoutManager *)layoutManager
                   textContainer:(NSTextContainer *)textContainer
                          atPoint:(CGPoint)origin
                 backgroundColor:(UIColor *)backgroundColor
                      borderColor:(UIColor *)borderColor {
    CGRect boundingRect = [self boundingRectForGlyphRange:glyphRange layoutManager:layoutManager textContainer:textContainer];
    if (CGRectIsEmpty(boundingRect)) return;
    
    CGRect rect = [self adjustedRect:boundingRect atPoint:origin];
    if (CGRectIsEmpty(rect) || CGRectIsInfinite(rect)) return;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:kCodeBackgroundCornerRadius];
    [backgroundColor setFill];
    [path fill];
    
    if (!borderColor) return;
    
    [borderColor setStroke];
    path.lineWidth = kCodeBackgroundBorderWidth;
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    [path stroke];
}

- (void)drawMultiLineBackground:(NSRange)glyphRange
                 layoutManager:(NSLayoutManager *)layoutManager
                 textContainer:(NSTextContainer *)textContainer
                        atPoint:(CGPoint)origin
               backgroundColor:(UIColor *)backgroundColor
                    borderColor:(UIColor *)borderColor {
    NSMutableArray<NSValue *> *lineRects = [NSMutableArray array];
    NSMutableArray<NSValue *> *fragmentRects = [NSMutableArray array];
    
    [layoutManager enumerateLineFragmentsForGlyphRange:glyphRange usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *container, NSRange lineGlyphRange, BOOL *stop) {
        NSRange intersection = NSIntersectionRange(lineGlyphRange, glyphRange);
        if (intersection.length > 0) {
            CGRect boundingRect = [self boundingRectForGlyphRange:intersection layoutManager:layoutManager textContainer:textContainer];
            [lineRects addObject:[NSValue valueWithCGRect:boundingRect]];
            [fragmentRects addObject:[NSValue valueWithCGRect:rect]];
        }
    }];
    
    if (lineRects.count == 0) return;
    
    // Draw start line (rounded left, no right border)
    CGRect firstRect = [lineRects[0] CGRectValue];
    CGRect firstFragmentRect = [fragmentRects[0] CGRectValue];
    CGRect adjustedFirstRect = [self adjustedRect:firstRect atPoint:origin];
    adjustedFirstRect.size.width = CGRectGetMaxX(firstFragmentRect) + origin.x - adjustedFirstRect.origin.x;
    [self drawRoundedEdge:adjustedFirstRect backgroundColor:backgroundColor borderColor:borderColor isLeft:YES];
    
    // Draw middle lines (no left border, no rounded corners)
    for (NSUInteger i = 1; i < lineRects.count - 1; i++) {
        CGRect fragmentRect = [fragmentRects[i] CGRectValue];
        CGRect middleRect = [self adjustedRect:fragmentRect atPoint:origin];
        middleRect.origin.x = fragmentRect.origin.x + origin.x;
        middleRect.size.width = fragmentRect.size.width;
        
        [backgroundColor setFill];
        UIRectFill(middleRect);
        
        if (borderColor) {
            [self drawMiddleBorders:middleRect borderColor:borderColor];
        }
    }
    
    // Draw end line (rounded right, no left border)
    if (lineRects.count > 1) {
        CGRect lastRect = [lineRects[lineRects.count - 1] CGRectValue];
        CGRect lastFragmentRect = [fragmentRects[fragmentRects.count - 1] CGRectValue];
        CGRect adjustedLastRect = [self adjustedRect:lastRect atPoint:origin];
        adjustedLastRect.origin.x = lastFragmentRect.origin.x + origin.x;
        adjustedLastRect.size.width = CGRectGetMaxX(lastRect) + origin.x - adjustedLastRect.origin.x;
        [self drawRoundedEdge:adjustedLastRect backgroundColor:backgroundColor borderColor:borderColor isLeft:NO];
    }
}

- (void)drawRoundedEdge:(CGRect)rect
        backgroundColor:(UIColor *)backgroundColor
            borderColor:(UIColor *)borderColor
                isLeft:(BOOL)isLeft {
    // Fill background
    UIBezierPath *fillPath = [self createRoundedFillPath:rect isLeft:isLeft];
    [backgroundColor setFill];
    [fillPath fill];
    
    // Draw borders
    if (!borderColor) return;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    [self configureBorderContext:context borderColor:borderColor];
    
    CGFloat halfStroke = kCodeBackgroundBorderWidth / 2.0;
    CGFloat topY = rect.origin.y + halfStroke;
    CGFloat bottomY = CGRectGetMaxY(rect) - halfStroke;
    
    [self drawRoundedBorder:rect topY:topY bottomY:bottomY context:context isLeft:isLeft];
    
    // Draw top and bottom borders
    CGFloat startX = isLeft ? (rect.origin.x + kCodeBackgroundCornerRadius) : rect.origin.x;
    CGFloat endX = isLeft ? CGRectGetMaxX(rect) : (CGRectGetMaxX(rect) - kCodeBackgroundCornerRadius);
    CGContextMoveToPoint(context, startX, topY);
    CGContextAddLineToPoint(context, endX, topY);
    CGContextMoveToPoint(context, startX, bottomY);
    CGContextAddLineToPoint(context, endX, bottomY);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

- (UIBezierPath *)createRoundedFillPath:(CGRect)rect isLeft:(BOOL)isLeft {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    if (isLeft) {
        [path moveToPoint:CGPointMake(rect.origin.x + kCodeBackgroundCornerRadius, rect.origin.y)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(rect.origin.x + kCodeBackgroundCornerRadius, CGRectGetMaxY(rect))];
        [path addQuadCurveToPoint:CGPointMake(rect.origin.x, CGRectGetMaxY(rect) - kCodeBackgroundCornerRadius)
                      controlPoint:CGPointMake(rect.origin.x, CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y + kCodeBackgroundCornerRadius)];
        [path addQuadCurveToPoint:CGPointMake(rect.origin.x + kCodeBackgroundCornerRadius, rect.origin.y)
                      controlPoint:CGPointMake(rect.origin.x, rect.origin.y)];
    } else {
        [path moveToPoint:CGPointMake(rect.origin.x, rect.origin.y)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - kCodeBackgroundCornerRadius, rect.origin.y)];
        [path addQuadCurveToPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y + kCodeBackgroundCornerRadius)
                      controlPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect) - kCodeBackgroundCornerRadius)];
        [path addQuadCurveToPoint:CGPointMake(CGRectGetMaxX(rect) - kCodeBackgroundCornerRadius, CGRectGetMaxY(rect))
                      controlPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(rect.origin.x, CGRectGetMaxY(rect))];
        [path closePath];
    }
    
    return path;
}

- (void)drawMiddleBorders:(CGRect)rect borderColor:(UIColor *)borderColor {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    [self configureBorderContext:context borderColor:borderColor];
    
    CGFloat halfStroke = kCodeBackgroundBorderWidth / 2.0;
    CGFloat topY = rect.origin.y + halfStroke;
    CGFloat bottomY = CGRectGetMaxY(rect) - halfStroke;
    CGFloat rightX = CGRectGetMaxX(rect) - halfStroke;
    
    CGContextMoveToPoint(context, rect.origin.x, topY);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), topY);
    CGContextMoveToPoint(context, rightX, rect.origin.y);
    CGContextAddLineToPoint(context, rightX, CGRectGetMaxY(rect));
    CGContextMoveToPoint(context, rect.origin.x, bottomY);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), bottomY);
    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)configureBorderContext:(CGContextRef)context borderColor:(UIColor *)borderColor {
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, kCodeBackgroundBorderWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
}

- (void)drawRoundedBorder:(CGRect)rect topY:(CGFloat)topY bottomY:(CGFloat)bottomY context:(CGContextRef)context isLeft:(BOOL)isLeft {
    CGFloat halfStroke = kCodeBackgroundBorderWidth / 2.0;
    CGFloat borderX = isLeft ? (rect.origin.x + halfStroke) : (CGRectGetMaxX(rect) - halfStroke);
    CGFloat cornerX = isLeft ? (rect.origin.x + kCodeBackgroundCornerRadius) : (CGRectGetMaxX(rect) - kCodeBackgroundCornerRadius);
    CGFloat edgeX = isLeft ? rect.origin.x : CGRectGetMaxX(rect);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    if (isLeft) {
        [path moveToPoint:CGPointMake(borderX, rect.origin.y + kCodeBackgroundCornerRadius)];
        [path addQuadCurveToPoint:CGPointMake(cornerX, topY) controlPoint:CGPointMake(borderX, rect.origin.y)];
        [path moveToPoint:CGPointMake(cornerX, bottomY)];
        [path addQuadCurveToPoint:CGPointMake(borderX, CGRectGetMaxY(rect) - kCodeBackgroundCornerRadius)
                      controlPoint:CGPointMake(borderX, CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(borderX, rect.origin.y + kCodeBackgroundCornerRadius)];
    } else {
        [path moveToPoint:CGPointMake(cornerX, topY)];
        [path addQuadCurveToPoint:CGPointMake(borderX, rect.origin.y + kCodeBackgroundCornerRadius)
                      controlPoint:CGPointMake(edgeX, rect.origin.y)];
        [path moveToPoint:CGPointMake(borderX, CGRectGetMaxY(rect) - kCodeBackgroundCornerRadius)];
        [path addQuadCurveToPoint:CGPointMake(cornerX, bottomY)
                      controlPoint:CGPointMake(edgeX, CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(borderX, rect.origin.y + kCodeBackgroundCornerRadius)];
    }
    
    CGContextAddPath(context, path.CGPath);
}

- (CGRect)adjustedRect:(CGRect)rect atPoint:(CGPoint)origin {
    CGFloat reduction = rect.size.height * kCodeBackgroundHeightReductionFactor;
    CGFloat top = rect.origin.y + reduction + origin.y;
    CGFloat bottom = CGRectGetMaxY(rect) - reduction + origin.y;
    return CGRectMake(rect.origin.x + origin.x, top, rect.size.width, bottom - top);
}

- (CGRect)boundingRectForGlyphRange:(NSRange)glyphRange
                      layoutManager:(NSLayoutManager *)layoutManager
                      textContainer:(NSTextContainer *)textContainer {
    if (glyphRange.location == NSNotFound || glyphRange.length == 0) return CGRectZero;
    return [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
}

@end
