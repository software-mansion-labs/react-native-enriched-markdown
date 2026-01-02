#import "StyleConfig.h"
#import <React/RCTFont.h>

@implementation StyleConfig {
  // Primary font properties
  UIColor *_primaryColor;
  NSNumber *_primaryFontSize;
  NSString *_primaryFontWeight;
  NSString *_primaryFontFamily;
  UIFont *_primaryFont;
  BOOL _primaryFontNeedsRecreation;
  // Paragraph properties
  CGFloat _paragraphFontSize;
  NSString *_paragraphFontFamily;
  NSString *_paragraphFontWeight;
  UIColor *_paragraphColor;
  CGFloat _paragraphMarginBottom;
  CGFloat _paragraphLineHeight;
  // H1 properties
  CGFloat _h1FontSize;
  NSString *_h1FontFamily;
  NSString *_h1FontWeight;
  UIColor *_h1Color;
  CGFloat _h1MarginBottom;
  CGFloat _h1LineHeight;
  // H2 properties
  CGFloat _h2FontSize;
  NSString *_h2FontFamily;
  NSString *_h2FontWeight;
  UIColor *_h2Color;
  CGFloat _h2MarginBottom;
  CGFloat _h2LineHeight;
  // H3 properties
  CGFloat _h3FontSize;
  NSString *_h3FontFamily;
  NSString *_h3FontWeight;
  UIColor *_h3Color;
  CGFloat _h3MarginBottom;
  CGFloat _h3LineHeight;
  // H4 properties
  CGFloat _h4FontSize;
  NSString *_h4FontFamily;
  NSString *_h4FontWeight;
  UIColor *_h4Color;
  CGFloat _h4MarginBottom;
  CGFloat _h4LineHeight;
  // H5 properties
  CGFloat _h5FontSize;
  NSString *_h5FontFamily;
  NSString *_h5FontWeight;
  UIColor *_h5Color;
  CGFloat _h5MarginBottom;
  CGFloat _h5LineHeight;
  // H6 properties
  CGFloat _h6FontSize;
  NSString *_h6FontFamily;
  NSString *_h6FontWeight;
  UIColor *_h6Color;
  CGFloat _h6MarginBottom;
  CGFloat _h6LineHeight;
  // Link properties
  UIColor *_linkColor;
  BOOL _linkUnderline;
  // Strong properties
  UIColor *_strongColor;
  // Emphasis properties
  UIColor *_emphasisColor;
  // Code properties
  UIColor *_codeColor;
  UIColor *_codeBackgroundColor;
  UIColor *_codeBorderColor;
  // Image properties
  CGFloat _imageHeight;
  CGFloat _imageBorderRadius;
  CGFloat _imageMarginBottom;
  // Inline image properties
  CGFloat _inlineImageSize;
  // Blockquote properties
  CGFloat _blockquoteFontSize;
  NSString *_blockquoteFontFamily;
  NSString *_blockquoteFontWeight;
  UIColor *_blockquoteColor;
  CGFloat _blockquoteMarginBottom;
  CGFloat _blockquoteNestedMarginBottom;
  CGFloat _blockquoteLineHeight;
  UIColor *_blockquoteBorderColor;
  CGFloat _blockquoteBorderWidth;
  CGFloat _blockquoteGapWidth;
  UIColor *_blockquoteBackgroundColor;
  // List style properties (combined for both ordered and unordered lists)
  CGFloat _listStyleFontSize;
  NSString *_listStyleFontFamily;
  NSString *_listStyleFontWeight;
  UIColor *_listStyleColor;
  CGFloat _listStyleMarginBottom;
  CGFloat _listStyleLineHeight;
  UIColor *_listStyleBulletColor;
  CGFloat _listStyleBulletSize;
  UIColor *_listStyleMarkerColor;
  NSString *_listStyleMarkerFontWeight;
  CGFloat _listStyleGapWidth;
  CGFloat _listStyleMarginLeft;
}

- (instancetype)init
{
  self = [super init];
  _primaryFontNeedsRecreation = YES;
  _linkUnderline = YES;
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  StyleConfig *copy = [[[self class] allocWithZone:zone] init];
  copy->_primaryColor = [_primaryColor copy];
  copy->_primaryFontSize = [_primaryFontSize copy];
  copy->_primaryFontWeight = [_primaryFontWeight copy];
  copy->_primaryFontFamily = [_primaryFontFamily copy];
  copy->_primaryFontNeedsRecreation = YES;

  copy->_paragraphFontSize = _paragraphFontSize;
  copy->_paragraphFontFamily = [_paragraphFontFamily copy];
  copy->_paragraphFontWeight = [_paragraphFontWeight copy];
  copy->_paragraphColor = [_paragraphColor copy];
  copy->_paragraphMarginBottom = _paragraphMarginBottom;
  copy->_paragraphLineHeight = _paragraphLineHeight;
  copy->_h1FontSize = _h1FontSize;
  copy->_h1FontFamily = [_h1FontFamily copy];
  copy->_h1FontWeight = [_h1FontWeight copy];
  copy->_h1Color = [_h1Color copy];
  copy->_h1MarginBottom = _h1MarginBottom;
  copy->_h1LineHeight = _h1LineHeight;
  copy->_h2FontSize = _h2FontSize;
  copy->_h2FontFamily = [_h2FontFamily copy];
  copy->_h2FontWeight = [_h2FontWeight copy];
  copy->_h2Color = [_h2Color copy];
  copy->_h2MarginBottom = _h2MarginBottom;
  copy->_h2LineHeight = _h2LineHeight;
  copy->_h3FontSize = _h3FontSize;
  copy->_h3FontFamily = [_h3FontFamily copy];
  copy->_h3FontWeight = [_h3FontWeight copy];
  copy->_h3Color = [_h3Color copy];
  copy->_h3MarginBottom = _h3MarginBottom;
  copy->_h3LineHeight = _h3LineHeight;
  copy->_h4FontSize = _h4FontSize;
  copy->_h4FontFamily = [_h4FontFamily copy];
  copy->_h4FontWeight = [_h4FontWeight copy];
  copy->_h4Color = [_h4Color copy];
  copy->_h4MarginBottom = _h4MarginBottom;
  copy->_h4LineHeight = _h4LineHeight;
  copy->_h5FontSize = _h5FontSize;
  copy->_h5FontFamily = [_h5FontFamily copy];
  copy->_h5FontWeight = [_h5FontWeight copy];
  copy->_h5Color = [_h5Color copy];
  copy->_h5MarginBottom = _h5MarginBottom;
  copy->_h5LineHeight = _h5LineHeight;
  copy->_h6FontSize = _h6FontSize;
  copy->_h6FontFamily = [_h6FontFamily copy];
  copy->_h6FontWeight = [_h6FontWeight copy];
  copy->_h6Color = [_h6Color copy];
  copy->_h6MarginBottom = _h6MarginBottom;
  copy->_h6LineHeight = _h6LineHeight;
  copy->_linkColor = [_linkColor copy];
  copy->_linkUnderline = _linkUnderline;
  copy->_strongColor = [_strongColor copy];
  copy->_emphasisColor = [_emphasisColor copy];
  copy->_codeColor = [_codeColor copy];
  copy->_codeBackgroundColor = [_codeBackgroundColor copy];
  copy->_codeBorderColor = [_codeBorderColor copy];
  copy->_imageHeight = _imageHeight;
  copy->_imageBorderRadius = _imageBorderRadius;
  copy->_imageMarginBottom = _imageMarginBottom;
  copy->_inlineImageSize = _inlineImageSize;
  copy->_blockquoteFontSize = _blockquoteFontSize;
  copy->_blockquoteFontFamily = [_blockquoteFontFamily copy];
  copy->_blockquoteFontWeight = [_blockquoteFontWeight copy];
  copy->_blockquoteColor = [_blockquoteColor copy];
  copy->_blockquoteMarginBottom = _blockquoteMarginBottom;
  copy->_blockquoteLineHeight = _blockquoteLineHeight;
  copy->_blockquoteBorderColor = [_blockquoteBorderColor copy];
  copy->_blockquoteBorderWidth = _blockquoteBorderWidth;
  copy->_blockquoteGapWidth = _blockquoteGapWidth;
  copy->_blockquoteBackgroundColor = [_blockquoteBackgroundColor copy];
  copy->_listStyleFontSize = _listStyleFontSize;
  copy->_listStyleFontFamily = [_listStyleFontFamily copy];
  copy->_listStyleFontWeight = [_listStyleFontWeight copy];
  copy->_listStyleColor = [_listStyleColor copy];
  copy->_listStyleMarginBottom = _listStyleMarginBottom;
  copy->_listStyleLineHeight = _listStyleLineHeight;
  copy->_listStyleBulletColor = [_listStyleBulletColor copy];
  copy->_listStyleBulletSize = _listStyleBulletSize;
  copy->_listStyleMarkerColor = [_listStyleMarkerColor copy];
  copy->_listStyleMarkerFontWeight = [_listStyleMarkerFontWeight copy];
  copy->_listStyleGapWidth = _listStyleGapWidth;
  copy->_listStyleMarginLeft = _listStyleMarginLeft;

  return copy;
}

- (UIColor *)primaryColor
{
  return _primaryColor != nullptr ? _primaryColor : [UIColor blackColor];
}

- (void)setPrimaryColor:(UIColor *)newValue
{
  _primaryColor = newValue;
}

- (NSNumber *)primaryFontSize
{
  return _primaryFontSize != nullptr ? _primaryFontSize : @16;
}

- (void)setPrimaryFontSize:(NSNumber *)newValue
{
  _primaryFontSize = newValue;
  _primaryFontNeedsRecreation = YES;
}

- (NSString *)primaryFontWeight
{
  return _primaryFontWeight != nullptr ? _primaryFontWeight : @"normal";
}

- (void)setPrimaryFontWeight:(NSString *)newValue
{
  _primaryFontWeight = newValue;
  _primaryFontNeedsRecreation = YES;
}

- (NSString *)primaryFontFamily
{
  return _primaryFontFamily;
}

- (void)setPrimaryFontFamily:(NSString *)newValue
{
  _primaryFontFamily = newValue;
  _primaryFontNeedsRecreation = YES;
}

- (UIFont *)primaryFont
{
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

// Paragraph properties
- (CGFloat)paragraphFontSize
{
  return _paragraphFontSize;
}

- (void)setParagraphFontSize:(CGFloat)newValue
{
  _paragraphFontSize = newValue;
}

- (NSString *)paragraphFontFamily
{
  return _paragraphFontFamily;
}

- (void)setParagraphFontFamily:(NSString *)newValue
{
  _paragraphFontFamily = newValue;
}

- (NSString *)paragraphFontWeight
{
  return _paragraphFontWeight;
}

- (void)setParagraphFontWeight:(NSString *)newValue
{
  _paragraphFontWeight = newValue;
}

- (UIColor *)paragraphColor
{
  return _paragraphColor;
}

- (void)setParagraphColor:(UIColor *)newValue
{
  _paragraphColor = newValue;
}

- (CGFloat)paragraphMarginBottom
{
  return _paragraphMarginBottom;
}

- (void)setParagraphMarginBottom:(CGFloat)newValue
{
  _paragraphMarginBottom = newValue;
}

- (CGFloat)paragraphLineHeight
{
  return _paragraphLineHeight;
}

- (void)setParagraphLineHeight:(CGFloat)newValue
{
  _paragraphLineHeight = newValue;
}

- (CGFloat)h1FontSize
{
  return _h1FontSize;
}

- (void)setH1FontSize:(CGFloat)newValue
{
  _h1FontSize = newValue;
}

- (NSString *)h1FontFamily
{
  return _h1FontFamily;
}

- (void)setH1FontFamily:(NSString *)newValue
{
  _h1FontFamily = newValue;
}

- (NSString *)h1FontWeight
{
  return _h1FontWeight;
}

- (void)setH1FontWeight:(NSString *)newValue
{
  _h1FontWeight = newValue;
}

- (UIColor *)h1Color
{
  return _h1Color;
}

- (void)setH1Color:(UIColor *)newValue
{
  _h1Color = newValue;
}

- (CGFloat)h1MarginBottom
{
  return _h1MarginBottom;
}

- (void)setH1MarginBottom:(CGFloat)newValue
{
  _h1MarginBottom = newValue;
}

- (CGFloat)h1LineHeight
{
  return _h1LineHeight;
}

- (void)setH1LineHeight:(CGFloat)newValue
{
  _h1LineHeight = newValue;
}

- (CGFloat)h2FontSize
{
  return _h2FontSize;
}

- (void)setH2FontSize:(CGFloat)newValue
{
  _h2FontSize = newValue;
}

- (NSString *)h2FontFamily
{
  return _h2FontFamily;
}

- (void)setH2FontFamily:(NSString *)newValue
{
  _h2FontFamily = newValue;
}

- (NSString *)h2FontWeight
{
  return _h2FontWeight;
}

- (void)setH2FontWeight:(NSString *)newValue
{
  _h2FontWeight = newValue;
}

- (UIColor *)h2Color
{
  return _h2Color;
}

- (void)setH2Color:(UIColor *)newValue
{
  _h2Color = newValue;
}

- (CGFloat)h2MarginBottom
{
  return _h2MarginBottom;
}

- (void)setH2MarginBottom:(CGFloat)newValue
{
  _h2MarginBottom = newValue;
}

- (CGFloat)h2LineHeight
{
  return _h2LineHeight;
}

- (void)setH2LineHeight:(CGFloat)newValue
{
  _h2LineHeight = newValue;
}

- (CGFloat)h3FontSize
{
  return _h3FontSize;
}

- (void)setH3FontSize:(CGFloat)newValue
{
  _h3FontSize = newValue;
}

- (NSString *)h3FontFamily
{
  return _h3FontFamily;
}

- (void)setH3FontFamily:(NSString *)newValue
{
  _h3FontFamily = newValue;
}

- (NSString *)h3FontWeight
{
  return _h3FontWeight;
}

- (void)setH3FontWeight:(NSString *)newValue
{
  _h3FontWeight = newValue;
}

- (UIColor *)h3Color
{
  return _h3Color;
}

- (void)setH3Color:(UIColor *)newValue
{
  _h3Color = newValue;
}

- (CGFloat)h3MarginBottom
{
  return _h3MarginBottom;
}

- (void)setH3MarginBottom:(CGFloat)newValue
{
  _h3MarginBottom = newValue;
}

- (CGFloat)h3LineHeight
{
  return _h3LineHeight;
}

- (void)setH3LineHeight:(CGFloat)newValue
{
  _h3LineHeight = newValue;
}

- (CGFloat)h4FontSize
{
  return _h4FontSize;
}

- (void)setH4FontSize:(CGFloat)newValue
{
  _h4FontSize = newValue;
}

- (NSString *)h4FontFamily
{
  return _h4FontFamily;
}

- (void)setH4FontFamily:(NSString *)newValue
{
  _h4FontFamily = newValue;
}

- (NSString *)h4FontWeight
{
  return _h4FontWeight;
}

- (void)setH4FontWeight:(NSString *)newValue
{
  _h4FontWeight = newValue;
}

- (UIColor *)h4Color
{
  return _h4Color;
}

- (void)setH4Color:(UIColor *)newValue
{
  _h4Color = newValue;
}

- (CGFloat)h4MarginBottom
{
  return _h4MarginBottom;
}

- (void)setH4MarginBottom:(CGFloat)newValue
{
  _h4MarginBottom = newValue;
}

- (CGFloat)h4LineHeight
{
  return _h4LineHeight;
}

- (void)setH4LineHeight:(CGFloat)newValue
{
  _h4LineHeight = newValue;
}

- (CGFloat)h5FontSize
{
  return _h5FontSize;
}

- (void)setH5FontSize:(CGFloat)newValue
{
  _h5FontSize = newValue;
}

- (NSString *)h5FontFamily
{
  return _h5FontFamily;
}

- (void)setH5FontFamily:(NSString *)newValue
{
  _h5FontFamily = newValue;
}

- (NSString *)h5FontWeight
{
  return _h5FontWeight;
}

- (void)setH5FontWeight:(NSString *)newValue
{
  _h5FontWeight = newValue;
}

- (UIColor *)h5Color
{
  return _h5Color;
}

- (void)setH5Color:(UIColor *)newValue
{
  _h5Color = newValue;
}

- (CGFloat)h5MarginBottom
{
  return _h5MarginBottom;
}

- (void)setH5MarginBottom:(CGFloat)newValue
{
  _h5MarginBottom = newValue;
}

- (CGFloat)h5LineHeight
{
  return _h5LineHeight;
}

- (void)setH5LineHeight:(CGFloat)newValue
{
  _h5LineHeight = newValue;
}

- (CGFloat)h6FontSize
{
  return _h6FontSize;
}

- (void)setH6FontSize:(CGFloat)newValue
{
  _h6FontSize = newValue;
}

- (NSString *)h6FontFamily
{
  return _h6FontFamily;
}

- (void)setH6FontFamily:(NSString *)newValue
{
  _h6FontFamily = newValue;
}

- (NSString *)h6FontWeight
{
  return _h6FontWeight;
}

- (void)setH6FontWeight:(NSString *)newValue
{
  _h6FontWeight = newValue;
}

- (UIColor *)h6Color
{
  return _h6Color;
}

- (void)setH6Color:(UIColor *)newValue
{
  _h6Color = newValue;
}

- (CGFloat)h6MarginBottom
{
  return _h6MarginBottom;
}

- (void)setH6MarginBottom:(CGFloat)newValue
{
  _h6MarginBottom = newValue;
}

- (CGFloat)h6LineHeight
{
  return _h6LineHeight;
}

- (void)setH6LineHeight:(CGFloat)newValue
{
  _h6LineHeight = newValue;
}

- (UIColor *)linkColor
{
  return _linkColor;
}

- (void)setLinkColor:(UIColor *)newValue
{
  _linkColor = newValue;
}

- (BOOL)linkUnderline
{
  return _linkUnderline;
}

- (void)setLinkUnderline:(BOOL)newValue
{
  _linkUnderline = newValue;
}

- (UIColor *)strongColor
{
  return _strongColor;
}

- (void)setStrongColor:(UIColor *)newValue
{
  _strongColor = newValue;
}

- (UIColor *)emphasisColor
{
  return _emphasisColor;
}

- (void)setEmphasisColor:(UIColor *)newValue
{
  _emphasisColor = newValue;
}

- (UIColor *)codeColor
{
  return _codeColor;
}

- (void)setCodeColor:(UIColor *)newValue
{
  _codeColor = newValue;
}

- (UIColor *)codeBackgroundColor
{
  return _codeBackgroundColor;
}

- (void)setCodeBackgroundColor:(UIColor *)newValue
{
  _codeBackgroundColor = newValue;
}

- (UIColor *)codeBorderColor
{
  return _codeBorderColor;
}

- (void)setCodeBorderColor:(UIColor *)newValue
{
  _codeBorderColor = newValue;
}

- (CGFloat)imageHeight
{
  return _imageHeight;
}

- (void)setImageHeight:(CGFloat)newValue
{
  _imageHeight = newValue;
}

- (CGFloat)imageBorderRadius
{
  return _imageBorderRadius;
}

- (void)setImageBorderRadius:(CGFloat)newValue
{
  _imageBorderRadius = newValue;
}

- (CGFloat)imageMarginBottom
{
  return _imageMarginBottom;
}

- (void)setImageMarginBottom:(CGFloat)newValue
{
  _imageMarginBottom = newValue;
}

- (CGFloat)inlineImageSize
{
  return _inlineImageSize;
}

- (void)setInlineImageSize:(CGFloat)newValue
{
  _inlineImageSize = newValue;
}

// Blockquote properties
- (CGFloat)blockquoteFontSize
{
  return _blockquoteFontSize;
}

- (void)setBlockquoteFontSize:(CGFloat)newValue
{
  _blockquoteFontSize = newValue;
}

- (NSString *)blockquoteFontFamily
{
  return _blockquoteFontFamily;
}

- (void)setBlockquoteFontFamily:(NSString *)newValue
{
  _blockquoteFontFamily = newValue;
}

- (NSString *)blockquoteFontWeight
{
  return _blockquoteFontWeight;
}

- (void)setBlockquoteFontWeight:(NSString *)newValue
{
  _blockquoteFontWeight = newValue;
}

- (UIColor *)blockquoteColor
{
  return _blockquoteColor;
}

- (void)setBlockquoteColor:(UIColor *)newValue
{
  _blockquoteColor = newValue;
}

- (CGFloat)blockquoteMarginBottom
{
  return _blockquoteMarginBottom;
}

- (void)setBlockquoteMarginBottom:(CGFloat)newValue
{
  _blockquoteMarginBottom = newValue;
}

- (CGFloat)blockquoteNestedMarginBottom
{
  return _blockquoteNestedMarginBottom;
}

- (void)setBlockquoteNestedMarginBottom:(CGFloat)newValue
{
  _blockquoteNestedMarginBottom = newValue;
}

- (CGFloat)blockquoteLineHeight
{
  return _blockquoteLineHeight;
}

- (void)setBlockquoteLineHeight:(CGFloat)newValue
{
  _blockquoteLineHeight = newValue;
}

- (UIColor *)blockquoteBorderColor
{
  return _blockquoteBorderColor;
}

- (void)setBlockquoteBorderColor:(UIColor *)newValue
{
  _blockquoteBorderColor = newValue;
}

- (CGFloat)blockquoteBorderWidth
{
  return _blockquoteBorderWidth;
}

- (void)setBlockquoteBorderWidth:(CGFloat)newValue
{
  _blockquoteBorderWidth = newValue;
}

- (CGFloat)blockquoteGapWidth
{
  return _blockquoteGapWidth;
}

- (void)setBlockquoteGapWidth:(CGFloat)newValue
{
  _blockquoteGapWidth = newValue;
}

- (UIColor *)blockquoteBackgroundColor
{
  return _blockquoteBackgroundColor;
}

- (void)setBlockquoteBackgroundColor:(UIColor *)newValue
{
  _blockquoteBackgroundColor = newValue;
}

// List style properties (combined for both ordered and unordered lists)
- (CGFloat)listStyleFontSize
{
  return _listStyleFontSize;
}

- (void)setListStyleFontSize:(CGFloat)newValue
{
  _listStyleFontSize = newValue;
}

- (NSString *)listStyleFontFamily
{
  return _listStyleFontFamily;
}

- (void)setListStyleFontFamily:(NSString *)newValue
{
  _listStyleFontFamily = newValue;
}

- (NSString *)listStyleFontWeight
{
  return _listStyleFontWeight;
}

- (void)setListStyleFontWeight:(NSString *)newValue
{
  _listStyleFontWeight = newValue;
}

- (UIColor *)listStyleColor
{
  return _listStyleColor;
}

- (void)setListStyleColor:(UIColor *)newValue
{
  _listStyleColor = newValue;
}

- (CGFloat)listStyleMarginBottom
{
  return _listStyleMarginBottom;
}

- (void)setListStyleMarginBottom:(CGFloat)newValue
{
  _listStyleMarginBottom = newValue;
}

- (CGFloat)listStyleLineHeight
{
  return _listStyleLineHeight;
}

- (void)setListStyleLineHeight:(CGFloat)newValue
{
  _listStyleLineHeight = newValue;
}

- (UIColor *)listStyleBulletColor
{
  return _listStyleBulletColor;
}

- (void)setListStyleBulletColor:(UIColor *)newValue
{
  _listStyleBulletColor = newValue;
}

- (CGFloat)listStyleBulletSize
{
  return _listStyleBulletSize;
}

- (void)setListStyleBulletSize:(CGFloat)newValue
{
  _listStyleBulletSize = newValue;
}

- (UIColor *)listStyleMarkerColor
{
  return _listStyleMarkerColor;
}

- (void)setListStyleMarkerColor:(UIColor *)newValue
{
  _listStyleMarkerColor = newValue;
}

- (NSString *)listStyleMarkerFontWeight
{
  return _listStyleMarkerFontWeight;
}

- (void)setListStyleMarkerFontWeight:(NSString *)newValue
{
  _listStyleMarkerFontWeight = newValue;
}

- (CGFloat)listStyleGapWidth
{
  return _listStyleGapWidth;
}

- (void)setListStyleGapWidth:(CGFloat)newValue
{
  _listStyleGapWidth = newValue;
}

- (CGFloat)listStyleMarginLeft
{
  return _listStyleMarginLeft;
}

- (void)setListStyleMarginLeft:(CGFloat)newValue
{
  _listStyleMarginLeft = newValue;
}

@end
