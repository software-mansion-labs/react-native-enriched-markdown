#import "RichTextConfig.h"
#import <React/RCTFont.h>

@implementation RichTextConfig {
    // Primary font properties
    UIColor *_primaryColor;
    NSNumber *_primaryFontSize;
    NSString *_primaryFontWeight;
    NSString *_primaryFontFamily;
    UIFont *_primaryFont;
    BOOL _primaryFontNeedsRecreation;
    // H1 properties
    CGFloat _h1FontSize;
    NSString *_h1FontFamily;
    // H2 properties
    CGFloat _h2FontSize;
    NSString *_h2FontFamily;
    // H3 properties
    CGFloat _h3FontSize;
    NSString *_h3FontFamily;
    // H4 properties
    CGFloat _h4FontSize;
    NSString *_h4FontFamily;
    // H5 properties
    CGFloat _h5FontSize;
    NSString *_h5FontFamily;
    // H6 properties
    CGFloat _h6FontSize;
    NSString *_h6FontFamily;
    // Link properties
    UIColor *_linkColor;
    BOOL _linkUnderline;
}

- (instancetype)init {
    self = [super init];
    _primaryFontNeedsRecreation = YES;
    _linkUnderline = YES;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    RichTextConfig *copy = [[[self class] allocWithZone:zone] init];
    copy->_primaryColor = [_primaryColor copy];
    copy->_primaryFontSize = [_primaryFontSize copy];
    copy->_primaryFontWeight = [_primaryFontWeight copy];
    copy->_primaryFontFamily = [_primaryFontFamily copy];
    copy->_primaryFontNeedsRecreation = YES;
    
    copy->_h1FontSize = _h1FontSize;
    copy->_h1FontFamily = [_h1FontFamily copy];
    copy->_h2FontSize = _h2FontSize;
    copy->_h2FontFamily = [_h2FontFamily copy];
    copy->_h3FontSize = _h3FontSize;
    copy->_h3FontFamily = [_h3FontFamily copy];
    copy->_h4FontSize = _h4FontSize;
    copy->_h4FontFamily = [_h4FontFamily copy];
    copy->_h5FontSize = _h5FontSize;
    copy->_h5FontFamily = [_h5FontFamily copy];
    copy->_h6FontSize = _h6FontSize;
    copy->_h6FontFamily = [_h6FontFamily copy];
    copy->_linkColor = [_linkColor copy];
    copy->_linkUnderline = _linkUnderline;
    
    return copy;
}

- (UIColor *)primaryColor {
    return _primaryColor != nullptr ? _primaryColor : [UIColor blackColor];
}

- (void)setPrimaryColor:(UIColor *)newValue {
    _primaryColor = newValue;
}

- (NSNumber *)primaryFontSize {
    return _primaryFontSize != nullptr ? _primaryFontSize : @16;
}

- (void)setPrimaryFontSize:(NSNumber *)newValue {
    _primaryFontSize = newValue;
    _primaryFontNeedsRecreation = YES;
}

- (NSString *)primaryFontWeight {
    return _primaryFontWeight != nullptr ? _primaryFontWeight : @"normal";
}

- (void)setPrimaryFontWeight:(NSString *)newValue {
    _primaryFontWeight = newValue;
    _primaryFontNeedsRecreation = YES;
}

- (NSString *)primaryFontFamily {
    return _primaryFontFamily;
}

- (void)setPrimaryFontFamily:(NSString *)newValue {
    _primaryFontFamily = newValue;
    _primaryFontNeedsRecreation = YES;
}

- (UIFont *)primaryFont {
    if (_primaryFontNeedsRecreation || !_primaryFont) {
        _primaryFont = [RCTFont updateFont:nil
                                withFamily:_primaryFontFamily
                                       size:_primaryFontSize
                                     weight:_primaryFontWeight
                                      style:nil
                                   variant:nil
                             scaleMultiplier:1];
        _primaryFontNeedsRecreation = NO;
    }
    return _primaryFont;
}

- (CGFloat)h1FontSize {
    return _h1FontSize;
}

- (void)setH1FontSize:(CGFloat)newValue {
    _h1FontSize = newValue;
}

- (NSString *)h1FontFamily {
    return _h1FontFamily;
}

- (void)setH1FontFamily:(NSString *)newValue {
    _h1FontFamily = newValue;
}

- (CGFloat)h2FontSize {
    return _h2FontSize;
}

- (void)setH2FontSize:(CGFloat)newValue {
    _h2FontSize = newValue;
}

- (NSString *)h2FontFamily {
    return _h2FontFamily;
}

- (void)setH2FontFamily:(NSString *)newValue {
    _h2FontFamily = newValue;
}

- (CGFloat)h3FontSize {
    return _h3FontSize;
}

- (void)setH3FontSize:(CGFloat)newValue {
    _h3FontSize = newValue;
}

- (NSString *)h3FontFamily {
    return _h3FontFamily;
}

- (void)setH3FontFamily:(NSString *)newValue {
    _h3FontFamily = newValue;
}

- (CGFloat)h4FontSize {
    return _h4FontSize;
}

- (void)setH4FontSize:(CGFloat)newValue {
    _h4FontSize = newValue;
}

- (NSString *)h4FontFamily {
    return _h4FontFamily;
}

- (void)setH4FontFamily:(NSString *)newValue {
    _h4FontFamily = newValue;
}

- (CGFloat)h5FontSize {
    return _h5FontSize;
}

- (void)setH5FontSize:(CGFloat)newValue {
    _h5FontSize = newValue;
}

- (NSString *)h5FontFamily {
    return _h5FontFamily;
}

- (void)setH5FontFamily:(NSString *)newValue {
    _h5FontFamily = newValue;
}

- (CGFloat)h6FontSize {
    return _h6FontSize;
}

- (void)setH6FontSize:(CGFloat)newValue {
    _h6FontSize = newValue;
}

- (NSString *)h6FontFamily {
    return _h6FontFamily;
}

- (void)setH6FontFamily:(NSString *)newValue {
    _h6FontFamily = newValue;
}

- (UIColor *)linkColor {
    return _linkColor;
}

- (void)setLinkColor:(UIColor *)newValue {
    _linkColor = newValue;
}

- (BOOL)linkUnderline {
    return _linkUnderline;
}

- (void)setLinkUnderline:(BOOL)newValue {
    _linkUnderline = newValue;
}

@end
