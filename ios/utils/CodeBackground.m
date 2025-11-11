#import "CodeBackground.h"

NSString *const RichTextCodeAttributeName = @"RichTextCode";

@implementation CodeBackground {
    RichTextConfig *_config;
    CGFloat _cornerRadius;
    CGFloat _borderWidth;
    CGFloat _heightReductionFactor;
}

- (instancetype)initWithConfig:(RichTextConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        _cornerRadius = 2.0;
        _borderWidth = 1.0;
        _heightReductionFactor = 0.1;
    }
    return self;
}

- (void)drawBackgroundsForGlyphRange:(NSRange)glyphsToShow
                        layoutManager:(NSLayoutManager *)layoutManager
                        textContainer:(NSTextContainer *)textContainer
                               atPoint:(CGPoint)origin {
    UIColor *backgroundColor = _config.codeBackgroundColor;
    UIColor *borderColor = _config.codeBorderColor;
    
    if (!backgroundColor) return;
    
    NSTextStorage *textStorage = layoutManager.textStorage;
    if (!textStorage || textStorage.length == 0) return;
    
    NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphsToShow actualGlyphRange:NULL];
    if (charRange.location == NSNotFound || charRange.length == 0) return;
    
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
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:_cornerRadius];
    [backgroundColor setFill];
    [path fill];
    
    if (borderColor) {
        [borderColor setStroke];
        path.lineWidth = _borderWidth;
        path.lineCapStyle = kCGLineCapRound;
        path.lineJoinStyle = kCGLineJoinRound;
        [path stroke];
    }
}

- (void)drawMultiLineBackground:(NSRange)glyphRange
                 layoutManager:(NSLayoutManager *)layoutManager
                 textContainer:(NSTextContainer *)textContainer
                        atPoint:(CGPoint)origin
               backgroundColor:(UIColor *)backgroundColor
                    borderColor:(UIColor *)borderColor {
    NSMutableArray<NSValue *> *lineRects = [NSMutableArray array];
    NSUInteger glyphIndex = glyphRange.location;
    
    while (glyphIndex < NSMaxRange(glyphRange)) {
        NSRange lineRange;
        [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&lineRange];
        
        NSRange intersection = NSIntersectionRange(lineRange, glyphRange);
        if (intersection.length > 0) {
            CGRect boundingRect = [self boundingRectForGlyphRange:intersection layoutManager:layoutManager textContainer:textContainer];
            [lineRects addObject:[NSValue valueWithCGRect:boundingRect]];
        }
        glyphIndex = NSMaxRange(lineRange);
    }
    
    if (lineRects.count == 0) return;
    
    // Draw start line
    CGRect firstRect = [lineRects[0] CGRectValue];
    NSRange firstLineRange;
    CGRect firstFragmentRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:&firstLineRange];
    CGRect adjustedFirstRect = [self adjustedRect:firstRect atPoint:origin];
    adjustedFirstRect.size.width = CGRectGetMaxX(firstFragmentRect) + origin.x - adjustedFirstRect.origin.x;
    [self drawRoundedEdge:adjustedFirstRect backgroundColor:backgroundColor borderColor:borderColor isLeft:YES];
    
    // Draw middle lines
    for (NSUInteger i = 1; i < lineRects.count - 1; i++) {
        CGRect lineRect = [lineRects[i] CGRectValue];
        NSRange lineRange;
        CGRect fragmentRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphRange.location + i effectiveRange:&lineRange];
        
        CGRect middleRect = [self adjustedRect:lineRect atPoint:origin];
        middleRect.origin.x = fragmentRect.origin.x + origin.x;
        middleRect.size.width = fragmentRect.size.width;
        
        [backgroundColor setFill];
        UIRectFill(middleRect);
        
        if (borderColor) {
            [self drawMiddleBorders:middleRect borderColor:borderColor];
        }
    }
    
    // Draw end line
    if (lineRects.count > 1) {
        CGRect lastRect = [lineRects[lineRects.count - 1] CGRectValue];
        NSRange lastLineRange;
        CGRect lastFragmentRect = [layoutManager lineFragmentRectForGlyphAtIndex:NSMaxRange(glyphRange) - 1 effectiveRange:&lastLineRange];
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
    if (borderColor) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        [self configureBorderContext:context borderColor:borderColor];
        
        CGFloat halfStroke = _borderWidth / 2.0;
        CGFloat topY = rect.origin.y + halfStroke;
        CGFloat bottomY = CGRectGetMaxY(rect) - halfStroke;
        
        [self drawRoundedBorder:rect topY:topY bottomY:bottomY context:context isLeft:isLeft];
        
        // Draw top and bottom borders
        CGFloat startX = isLeft ? (rect.origin.x + _cornerRadius) : rect.origin.x;
        CGFloat endX = isLeft ? CGRectGetMaxX(rect) : (CGRectGetMaxX(rect) - _cornerRadius);
        CGContextMoveToPoint(context, startX, topY);
        CGContextAddLineToPoint(context, endX, topY);
        CGContextMoveToPoint(context, startX, bottomY);
        CGContextAddLineToPoint(context, endX, bottomY);
        
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
    }
}

- (UIBezierPath *)createRoundedFillPath:(CGRect)rect isLeft:(BOOL)isLeft {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    if (isLeft) {
        [path moveToPoint:CGPointMake(rect.origin.x + _cornerRadius, rect.origin.y)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(rect.origin.x + _cornerRadius, CGRectGetMaxY(rect))];
        [path addQuadCurveToPoint:CGPointMake(rect.origin.x, CGRectGetMaxY(rect) - _cornerRadius)
                      controlPoint:CGPointMake(rect.origin.x, CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y + _cornerRadius)];
        [path addQuadCurveToPoint:CGPointMake(rect.origin.x + _cornerRadius, rect.origin.y)
                      controlPoint:CGPointMake(rect.origin.x, rect.origin.y)];
    } else {
        [path moveToPoint:CGPointMake(rect.origin.x, rect.origin.y)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - _cornerRadius, rect.origin.y)];
        [path addQuadCurveToPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y + _cornerRadius)
                      controlPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect) - _cornerRadius)];
        [path addQuadCurveToPoint:CGPointMake(CGRectGetMaxX(rect) - _cornerRadius, CGRectGetMaxY(rect))
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
    
    CGFloat halfStroke = _borderWidth / 2.0;
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
    CGContextSetLineWidth(context, _borderWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
}

- (void)drawRoundedBorder:(CGRect)rect topY:(CGFloat)topY bottomY:(CGFloat)bottomY context:(CGContextRef)context isLeft:(BOOL)isLeft {
    CGFloat halfStroke = _borderWidth / 2.0;
    CGFloat borderX = isLeft ? (rect.origin.x + halfStroke) : (CGRectGetMaxX(rect) - halfStroke);
    CGFloat cornerX = isLeft ? (rect.origin.x + _cornerRadius) : (CGRectGetMaxX(rect) - _cornerRadius);
    CGFloat edgeX = isLeft ? rect.origin.x : CGRectGetMaxX(rect);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    if (isLeft) {
        [path moveToPoint:CGPointMake(borderX, rect.origin.y + _cornerRadius)];
        [path addQuadCurveToPoint:CGPointMake(cornerX, topY) controlPoint:CGPointMake(borderX, rect.origin.y)];
        [path moveToPoint:CGPointMake(cornerX, bottomY)];
        [path addQuadCurveToPoint:CGPointMake(borderX, CGRectGetMaxY(rect) - _cornerRadius)
                      controlPoint:CGPointMake(borderX, CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(borderX, rect.origin.y + _cornerRadius)];
    } else {
        [path moveToPoint:CGPointMake(cornerX, topY)];
        [path addQuadCurveToPoint:CGPointMake(borderX, rect.origin.y + _cornerRadius)
                      controlPoint:CGPointMake(edgeX, rect.origin.y)];
        [path moveToPoint:CGPointMake(borderX, CGRectGetMaxY(rect) - _cornerRadius)];
        [path addQuadCurveToPoint:CGPointMake(cornerX, bottomY)
                      controlPoint:CGPointMake(edgeX, CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(borderX, rect.origin.y + _cornerRadius)];
    }
    
    CGContextAddPath(context, path.CGPath);
}

- (CGRect)adjustedRect:(CGRect)rect atPoint:(CGPoint)origin {
    CGFloat reduction = rect.size.height * _heightReductionFactor;
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
