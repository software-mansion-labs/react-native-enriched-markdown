#import "StyleConfig.h"
#import "FontUtils.h"
#import <React/RCTFont.h>
#import <React/RCTUtils.h>

static inline NSString *normalizedFontWeight(NSString *fontWeight)
{
  // If nil or empty string, return nil to let RCTFont use fontFamily as-is
  if (fontWeight == nil || fontWeight.length == 0) {
    return nil;
  }

  return fontWeight;
}

@implementation StyleConfig {
  BOOL _allowFontScaling;
  CGFloat _maxFontSizeMultiplier;
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
  CGFloat _paragraphMarginTop;
  CGFloat _paragraphMarginBottom;
  CGFloat _paragraphLineHeight;
  NSTextAlignment _paragraphTextAlign;
  UIFont *_paragraphFont;
  BOOL _paragraphFontNeedsRecreation;
  // H1 properties
  CGFloat _h1FontSize;
  NSString *_h1FontFamily;
  NSString *_h1FontWeight;
  UIColor *_h1Color;
  CGFloat _h1MarginTop;
  CGFloat _h1MarginBottom;
  CGFloat _h1LineHeight;
  NSTextAlignment _h1TextAlign;
  UIFont *_h1Font;
  BOOL _h1FontNeedsRecreation;
  // H2 properties
  CGFloat _h2FontSize;
  NSString *_h2FontFamily;
  NSString *_h2FontWeight;
  UIColor *_h2Color;
  CGFloat _h2MarginTop;
  CGFloat _h2MarginBottom;
  CGFloat _h2LineHeight;
  NSTextAlignment _h2TextAlign;
  UIFont *_h2Font;
  BOOL _h2FontNeedsRecreation;
  // H3 properties
  CGFloat _h3FontSize;
  NSString *_h3FontFamily;
  NSString *_h3FontWeight;
  UIColor *_h3Color;
  CGFloat _h3MarginTop;
  CGFloat _h3MarginBottom;
  CGFloat _h3LineHeight;
  NSTextAlignment _h3TextAlign;
  UIFont *_h3Font;
  BOOL _h3FontNeedsRecreation;
  // H4 properties
  CGFloat _h4FontSize;
  NSString *_h4FontFamily;
  NSString *_h4FontWeight;
  UIColor *_h4Color;
  CGFloat _h4MarginTop;
  CGFloat _h4MarginBottom;
  CGFloat _h4LineHeight;
  NSTextAlignment _h4TextAlign;
  UIFont *_h4Font;
  BOOL _h4FontNeedsRecreation;
  // H5 properties
  CGFloat _h5FontSize;
  NSString *_h5FontFamily;
  NSString *_h5FontWeight;
  UIColor *_h5Color;
  CGFloat _h5MarginTop;
  CGFloat _h5MarginBottom;
  CGFloat _h5LineHeight;
  NSTextAlignment _h5TextAlign;
  UIFont *_h5Font;
  BOOL _h5FontNeedsRecreation;
  // H6 properties
  CGFloat _h6FontSize;
  NSString *_h6FontFamily;
  NSString *_h6FontWeight;
  UIColor *_h6Color;
  CGFloat _h6MarginTop;
  CGFloat _h6MarginBottom;
  CGFloat _h6LineHeight;
  NSTextAlignment _h6TextAlign;
  UIFont *_h6Font;
  BOOL _h6FontNeedsRecreation;
  // Link properties
  UIColor *_linkColor;
  BOOL _linkUnderline;
  // Strong properties
  UIColor *_strongColor;
  // Emphasis properties
  UIColor *_emphasisColor;
  // Strikethrough properties
  UIColor *_strikethroughColor;
  // Underline properties
  UIColor *_underlineColor;
  // Code properties
  UIColor *_codeColor;
  UIColor *_codeBackgroundColor;
  UIColor *_codeBorderColor;
  // Image properties
  CGFloat _imageHeight;
  CGFloat _imageBorderRadius;
  CGFloat _imageMarginTop;
  CGFloat _imageMarginBottom;
  // Inline image properties
  CGFloat _inlineImageSize;
  // Blockquote properties
  CGFloat _blockquoteFontSize;
  NSString *_blockquoteFontFamily;
  NSString *_blockquoteFontWeight;
  UIColor *_blockquoteColor;
  CGFloat _blockquoteMarginTop;
  CGFloat _blockquoteMarginBottom;
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
  CGFloat _listStyleMarginTop;
  CGFloat _listStyleMarginBottom;
  CGFloat _listStyleLineHeight;
  UIColor *_listStyleBulletColor;
  CGFloat _listStyleBulletSize;
  UIColor *_listStyleMarkerColor;
  NSString *_listStyleMarkerFontWeight;
  CGFloat _listStyleGapWidth;
  CGFloat _listStyleMarginLeft;
  UIFont *_listMarkerFont;
  BOOL _listMarkerFontNeedsRecreation;
  UIFont *_listStyleFont;
  BOOL _listStyleFontNeedsRecreation;
  // Code block properties
  CGFloat _codeBlockFontSize;
  NSString *_codeBlockFontFamily;
  NSString *_codeBlockFontWeight;
  UIColor *_codeBlockColor;
  CGFloat _codeBlockMarginTop;
  CGFloat _codeBlockMarginBottom;
  CGFloat _codeBlockLineHeight;
  UIColor *_codeBlockBackgroundColor;
  UIColor *_codeBlockBorderColor;
  CGFloat _codeBlockBorderRadius;
  CGFloat _codeBlockBorderWidth;
  CGFloat _codeBlockPadding;
  UIFont *_codeBlockFont;
  BOOL _codeBlockFontNeedsRecreation;
  UIFont *_blockquoteFont;
  BOOL _blockquoteFontNeedsRecreation;
  // Thematic break properties
  UIColor *_thematicBreakColor;
  CGFloat _thematicBreakHeight;
  CGFloat _thematicBreakMarginTop;
  CGFloat _thematicBreakMarginBottom;
}

- (instancetype)init
{
  self = [super init];
  _allowFontScaling = YES;
  _maxFontSizeMultiplier = 0;
  _primaryFontNeedsRecreation = YES;
  _paragraphFontNeedsRecreation = YES;
  _h1FontNeedsRecreation = YES;
  _h2FontNeedsRecreation = YES;
  _h3FontNeedsRecreation = YES;
  _h4FontNeedsRecreation = YES;
  _h5FontNeedsRecreation = YES;
  _h6FontNeedsRecreation = YES;
  _listMarkerFontNeedsRecreation = YES;
  _listStyleFontNeedsRecreation = YES;
  _codeBlockFontNeedsRecreation = YES;
  _blockquoteFontNeedsRecreation = YES;
  _linkUnderline = YES;
  return self;
}

- (CGFloat)fontScaleMultiplier
{
  return _allowFontScaling ? RCTFontSizeMultiplier() : 1.0;
}

- (void)setFontScaleMultiplier:(CGFloat)newValue
{
  BOOL newAllowFontScaling = (newValue != 1.0);
  if (_allowFontScaling != newAllowFontScaling) {
    _allowFontScaling = newAllowFontScaling;
    // Invalidate all cached fonts when scale changes
    _primaryFontNeedsRecreation = YES;
    _paragraphFontNeedsRecreation = YES;
    _h1FontNeedsRecreation = YES;
    _h2FontNeedsRecreation = YES;
    _h3FontNeedsRecreation = YES;
    _h4FontNeedsRecreation = YES;
    _h5FontNeedsRecreation = YES;
    _h6FontNeedsRecreation = YES;
    _listMarkerFontNeedsRecreation = YES;
    _listStyleFontNeedsRecreation = YES;
    _codeBlockFontNeedsRecreation = YES;
    _blockquoteFontNeedsRecreation = YES;
  }
}

- (CGFloat)effectiveScaleMultiplierForFontSize:(CGFloat)fontSize
{
  if (!_allowFontScaling) {
    return 1.0;
  }
  return RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
}

- (CGFloat)maxFontSizeMultiplier
{
  return _maxFontSizeMultiplier;
}

- (void)setMaxFontSizeMultiplier:(CGFloat)newValue
{
  if (_maxFontSizeMultiplier != newValue) {
    _maxFontSizeMultiplier = newValue;
    // Invalidate all cached fonts when max multiplier changes
    _primaryFontNeedsRecreation = YES;
    _paragraphFontNeedsRecreation = YES;
    _h1FontNeedsRecreation = YES;
    _h2FontNeedsRecreation = YES;
    _h3FontNeedsRecreation = YES;
    _h4FontNeedsRecreation = YES;
    _h5FontNeedsRecreation = YES;
    _h6FontNeedsRecreation = YES;
    _listMarkerFontNeedsRecreation = YES;
    _listStyleFontNeedsRecreation = YES;
    _codeBlockFontNeedsRecreation = YES;
    _blockquoteFontNeedsRecreation = YES;
  }
}

- (id)copyWithZone:(NSZone *)zone
{
  StyleConfig *copy = [[[self class] allocWithZone:zone] init];
  copy->_allowFontScaling = _allowFontScaling;
  copy->_maxFontSizeMultiplier = _maxFontSizeMultiplier;
  copy->_primaryColor = [_primaryColor copy];
  copy->_primaryFontSize = [_primaryFontSize copy];
  copy->_primaryFontWeight = [_primaryFontWeight copy];
  copy->_primaryFontFamily = [_primaryFontFamily copy];
  copy->_primaryFontNeedsRecreation = YES;

  copy->_paragraphFontSize = _paragraphFontSize;
  copy->_paragraphFontFamily = [_paragraphFontFamily copy];
  copy->_paragraphFontWeight = [_paragraphFontWeight copy];
  copy->_paragraphColor = [_paragraphColor copy];
  copy->_paragraphMarginTop = _paragraphMarginTop;
  copy->_paragraphMarginBottom = _paragraphMarginBottom;
  copy->_paragraphLineHeight = _paragraphLineHeight;
  copy->_paragraphTextAlign = _paragraphTextAlign;
  copy->_paragraphFontNeedsRecreation = YES;
  copy->_h1FontSize = _h1FontSize;
  copy->_h1FontFamily = [_h1FontFamily copy];
  copy->_h1FontWeight = [_h1FontWeight copy];
  copy->_h1Color = [_h1Color copy];
  copy->_h1MarginTop = _h1MarginTop;
  copy->_h1MarginBottom = _h1MarginBottom;
  copy->_h1LineHeight = _h1LineHeight;
  copy->_h1TextAlign = _h1TextAlign;
  copy->_h1FontNeedsRecreation = YES;
  copy->_h2FontSize = _h2FontSize;
  copy->_h2FontFamily = [_h2FontFamily copy];
  copy->_h2FontWeight = [_h2FontWeight copy];
  copy->_h2Color = [_h2Color copy];
  copy->_h2MarginTop = _h2MarginTop;
  copy->_h2MarginBottom = _h2MarginBottom;
  copy->_h2LineHeight = _h2LineHeight;
  copy->_h2TextAlign = _h2TextAlign;
  copy->_h2FontNeedsRecreation = YES;
  copy->_h3FontSize = _h3FontSize;
  copy->_h3FontFamily = [_h3FontFamily copy];
  copy->_h3FontWeight = [_h3FontWeight copy];
  copy->_h3Color = [_h3Color copy];
  copy->_h3MarginTop = _h3MarginTop;
  copy->_h3MarginBottom = _h3MarginBottom;
  copy->_h3LineHeight = _h3LineHeight;
  copy->_h3TextAlign = _h3TextAlign;
  copy->_h3FontNeedsRecreation = YES;
  copy->_h4FontSize = _h4FontSize;
  copy->_h4FontFamily = [_h4FontFamily copy];
  copy->_h4FontWeight = [_h4FontWeight copy];
  copy->_h4Color = [_h4Color copy];
  copy->_h4MarginTop = _h4MarginTop;
  copy->_h4MarginBottom = _h4MarginBottom;
  copy->_h4LineHeight = _h4LineHeight;
  copy->_h4TextAlign = _h4TextAlign;
  copy->_h4FontNeedsRecreation = YES;
  copy->_h5FontSize = _h5FontSize;
  copy->_h5FontFamily = [_h5FontFamily copy];
  copy->_h5FontWeight = [_h5FontWeight copy];
  copy->_h5Color = [_h5Color copy];
  copy->_h5MarginTop = _h5MarginTop;
  copy->_h5MarginBottom = _h5MarginBottom;
  copy->_h5LineHeight = _h5LineHeight;
  copy->_h5TextAlign = _h5TextAlign;
  copy->_h5FontNeedsRecreation = YES;
  copy->_h6FontSize = _h6FontSize;
  copy->_h6FontFamily = [_h6FontFamily copy];
  copy->_h6FontWeight = [_h6FontWeight copy];
  copy->_h6Color = [_h6Color copy];
  copy->_h6MarginTop = _h6MarginTop;
  copy->_h6MarginBottom = _h6MarginBottom;
  copy->_h6LineHeight = _h6LineHeight;
  copy->_h6TextAlign = _h6TextAlign;
  copy->_h6FontNeedsRecreation = YES;
  copy->_linkColor = [_linkColor copy];
  copy->_linkUnderline = _linkUnderline;
  copy->_strongColor = [_strongColor copy];
  copy->_emphasisColor = [_emphasisColor copy];
  copy->_strikethroughColor = [_strikethroughColor copy];
  copy->_underlineColor = [_underlineColor copy];
  copy->_codeColor = [_codeColor copy];
  copy->_codeBackgroundColor = [_codeBackgroundColor copy];
  copy->_codeBorderColor = [_codeBorderColor copy];
  copy->_imageHeight = _imageHeight;
  copy->_imageBorderRadius = _imageBorderRadius;
  copy->_imageMarginTop = _imageMarginTop;
  copy->_imageMarginBottom = _imageMarginBottom;
  copy->_inlineImageSize = _inlineImageSize;
  copy->_blockquoteFontSize = _blockquoteFontSize;
  copy->_blockquoteFontFamily = [_blockquoteFontFamily copy];
  copy->_blockquoteFontWeight = [_blockquoteFontWeight copy];
  copy->_blockquoteColor = [_blockquoteColor copy];
  copy->_blockquoteMarginTop = _blockquoteMarginTop;
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
  copy->_listStyleMarginTop = _listStyleMarginTop;
  copy->_listStyleMarginBottom = _listStyleMarginBottom;
  copy->_listStyleLineHeight = _listStyleLineHeight;
  copy->_listStyleBulletColor = [_listStyleBulletColor copy];
  copy->_listStyleBulletSize = _listStyleBulletSize;
  copy->_listStyleMarkerColor = [_listStyleMarkerColor copy];
  copy->_listStyleMarkerFontWeight = [_listStyleMarkerFontWeight copy];
  copy->_listStyleGapWidth = _listStyleGapWidth;
  copy->_listStyleMarginLeft = _listStyleMarginLeft;
  copy->_listStyleFontNeedsRecreation = YES;
  copy->_codeBlockFontSize = _codeBlockFontSize;
  copy->_codeBlockFontFamily = [_codeBlockFontFamily copy];
  copy->_codeBlockFontWeight = [_codeBlockFontWeight copy];
  copy->_codeBlockColor = [_codeBlockColor copy];
  copy->_codeBlockMarginTop = _codeBlockMarginTop;
  copy->_codeBlockMarginBottom = _codeBlockMarginBottom;
  copy->_codeBlockLineHeight = _codeBlockLineHeight;
  copy->_codeBlockBackgroundColor = [_codeBlockBackgroundColor copy];
  copy->_codeBlockBorderColor = [_codeBlockBorderColor copy];
  copy->_codeBlockBorderRadius = _codeBlockBorderRadius;
  copy->_codeBlockBorderWidth = _codeBlockBorderWidth;
  copy->_codeBlockPadding = _codeBlockPadding;
  copy->_codeBlockFontNeedsRecreation = YES;
  copy->_blockquoteFontNeedsRecreation = YES;
  copy->_thematicBreakColor = [_thematicBreakColor copy];
  copy->_thematicBreakHeight = _thematicBreakHeight;
  copy->_thematicBreakMarginTop = _thematicBreakMarginTop;
  copy->_thematicBreakMarginBottom = _thematicBreakMarginBottom;

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
                                weight:normalizedFontWeight(_primaryFontWeight)
                                 style:nil
                               variant:nil
                       scaleMultiplier:[self effectiveScaleMultiplierForFontSize:[_primaryFontSize floatValue]]];
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
  _paragraphFontNeedsRecreation = YES;
}

- (NSString *)paragraphFontFamily
{
  return _paragraphFontFamily;
}

- (void)setParagraphFontFamily:(NSString *)newValue
{
  _paragraphFontFamily = newValue;
  _paragraphFontNeedsRecreation = YES;
}

- (NSString *)paragraphFontWeight
{
  return _paragraphFontWeight;
}

- (void)setParagraphFontWeight:(NSString *)newValue
{
  _paragraphFontWeight = newValue;
  _paragraphFontNeedsRecreation = YES;
}

- (UIColor *)paragraphColor
{
  return _paragraphColor;
}

- (void)setParagraphColor:(UIColor *)newValue
{
  _paragraphColor = newValue;
}

- (CGFloat)paragraphMarginTop
{
  return _paragraphMarginTop;
}

- (void)setParagraphMarginTop:(CGFloat)newValue
{
  _paragraphMarginTop = newValue;
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
  if (_allowFontScaling && _paragraphLineHeight > 0) {
    return _paragraphLineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _paragraphLineHeight;
}

- (void)setParagraphLineHeight:(CGFloat)newValue
{
  _paragraphLineHeight = newValue;
}

- (NSTextAlignment)paragraphTextAlign
{
  return _paragraphTextAlign;
}

- (void)setParagraphTextAlign:(NSTextAlignment)newValue
{
  _paragraphTextAlign = newValue;
}

- (UIFont *)paragraphFont
{
  if (_paragraphFontNeedsRecreation || !_paragraphFont) {
    _paragraphFont = [RCTFont updateFont:nil
                              withFamily:_paragraphFontFamily
                                    size:@(_paragraphFontSize)
                                  weight:normalizedFontWeight(_paragraphFontWeight)
                                   style:nil
                                 variant:nil
                         scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_paragraphFontSize]];
    _paragraphFontNeedsRecreation = NO;
  }
  return _paragraphFont;
}

- (CGFloat)h1FontSize
{
  return _h1FontSize;
}

- (void)setH1FontSize:(CGFloat)newValue
{
  _h1FontSize = newValue;
  _h1FontNeedsRecreation = YES;
}

- (NSString *)h1FontFamily
{
  return _h1FontFamily;
}

- (void)setH1FontFamily:(NSString *)newValue
{
  _h1FontFamily = newValue;
  _h1FontNeedsRecreation = YES;
}

- (NSString *)h1FontWeight
{
  return _h1FontWeight;
}

- (void)setH1FontWeight:(NSString *)newValue
{
  _h1FontWeight = newValue;
  _h1FontNeedsRecreation = YES;
}

- (UIColor *)h1Color
{
  return _h1Color;
}

- (void)setH1Color:(UIColor *)newValue
{
  _h1Color = newValue;
}

- (CGFloat)h1MarginTop
{
  return _h1MarginTop;
}

- (void)setH1MarginTop:(CGFloat)newValue
{
  _h1MarginTop = newValue;
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
  if (_allowFontScaling && _h1LineHeight > 0) {
    return _h1LineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _h1LineHeight;
}

- (void)setH1LineHeight:(CGFloat)newValue
{
  _h1LineHeight = newValue;
}

- (NSTextAlignment)h1TextAlign
{
  return _h1TextAlign;
}

- (void)setH1TextAlign:(NSTextAlignment)newValue
{
  _h1TextAlign = newValue;
}

- (UIFont *)h1Font
{
  if (_h1FontNeedsRecreation || !_h1Font) {
    _h1Font = [RCTFont updateFont:nil
                       withFamily:_h1FontFamily
                             size:@(_h1FontSize)
                           weight:normalizedFontWeight(_h1FontWeight)
                            style:nil
                          variant:nil
                  scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_h1FontSize]];
    _h1FontNeedsRecreation = NO;
  }
  return _h1Font;
}

- (CGFloat)h2FontSize
{
  return _h2FontSize;
}

- (void)setH2FontSize:(CGFloat)newValue
{
  _h2FontSize = newValue;
  _h2FontNeedsRecreation = YES;
}

- (NSString *)h2FontFamily
{
  return _h2FontFamily;
}

- (void)setH2FontFamily:(NSString *)newValue
{
  _h2FontFamily = newValue;
  _h2FontNeedsRecreation = YES;
}

- (NSString *)h2FontWeight
{
  return _h2FontWeight;
}

- (void)setH2FontWeight:(NSString *)newValue
{
  _h2FontWeight = newValue;
  _h2FontNeedsRecreation = YES;
}

- (UIColor *)h2Color
{
  return _h2Color;
}

- (void)setH2Color:(UIColor *)newValue
{
  _h2Color = newValue;
}

- (CGFloat)h2MarginTop
{
  return _h2MarginTop;
}

- (void)setH2MarginTop:(CGFloat)newValue
{
  _h2MarginTop = newValue;
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
  if (_allowFontScaling && _h2LineHeight > 0) {
    return _h2LineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _h2LineHeight;
}

- (void)setH2LineHeight:(CGFloat)newValue
{
  _h2LineHeight = newValue;
}

- (NSTextAlignment)h2TextAlign
{
  return _h2TextAlign;
}

- (void)setH2TextAlign:(NSTextAlignment)newValue
{
  _h2TextAlign = newValue;
}

- (UIFont *)h2Font
{
  if (_h2FontNeedsRecreation || !_h2Font) {
    _h2Font = [RCTFont updateFont:nil
                       withFamily:_h2FontFamily
                             size:@(_h2FontSize)
                           weight:normalizedFontWeight(_h2FontWeight)
                            style:nil
                          variant:nil
                  scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_h2FontSize]];
    _h2FontNeedsRecreation = NO;
  }
  return _h2Font;
}

- (CGFloat)h3FontSize
{
  return _h3FontSize;
}

- (void)setH3FontSize:(CGFloat)newValue
{
  _h3FontSize = newValue;
  _h3FontNeedsRecreation = YES;
}

- (NSString *)h3FontFamily
{
  return _h3FontFamily;
}

- (void)setH3FontFamily:(NSString *)newValue
{
  _h3FontFamily = newValue;
  _h3FontNeedsRecreation = YES;
}

- (NSString *)h3FontWeight
{
  return _h3FontWeight;
}

- (void)setH3FontWeight:(NSString *)newValue
{
  _h3FontWeight = newValue;
  _h3FontNeedsRecreation = YES;
}

- (UIColor *)h3Color
{
  return _h3Color;
}

- (void)setH3Color:(UIColor *)newValue
{
  _h3Color = newValue;
}

- (CGFloat)h3MarginTop
{
  return _h3MarginTop;
}

- (void)setH3MarginTop:(CGFloat)newValue
{
  _h3MarginTop = newValue;
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
  if (_allowFontScaling && _h3LineHeight > 0) {
    return _h3LineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _h3LineHeight;
}

- (void)setH3LineHeight:(CGFloat)newValue
{
  _h3LineHeight = newValue;
}

- (NSTextAlignment)h3TextAlign
{
  return _h3TextAlign;
}

- (void)setH3TextAlign:(NSTextAlignment)newValue
{
  _h3TextAlign = newValue;
}

- (UIFont *)h3Font
{
  if (_h3FontNeedsRecreation || !_h3Font) {
    _h3Font = [RCTFont updateFont:nil
                       withFamily:_h3FontFamily
                             size:@(_h3FontSize)
                           weight:normalizedFontWeight(_h3FontWeight)
                            style:nil
                          variant:nil
                  scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_h3FontSize]];
    _h3FontNeedsRecreation = NO;
  }
  return _h3Font;
}

- (CGFloat)h4FontSize
{
  return _h4FontSize;
}

- (void)setH4FontSize:(CGFloat)newValue
{
  _h4FontSize = newValue;
  _h4FontNeedsRecreation = YES;
}

- (NSString *)h4FontFamily
{
  return _h4FontFamily;
}

- (void)setH4FontFamily:(NSString *)newValue
{
  _h4FontFamily = newValue;
  _h4FontNeedsRecreation = YES;
}

- (NSString *)h4FontWeight
{
  return _h4FontWeight;
}

- (void)setH4FontWeight:(NSString *)newValue
{
  _h4FontWeight = newValue;
  _h4FontNeedsRecreation = YES;
}

- (UIColor *)h4Color
{
  return _h4Color;
}

- (void)setH4Color:(UIColor *)newValue
{
  _h4Color = newValue;
}

- (CGFloat)h4MarginTop
{
  return _h4MarginTop;
}

- (void)setH4MarginTop:(CGFloat)newValue
{
  _h4MarginTop = newValue;
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
  if (_allowFontScaling && _h4LineHeight > 0) {
    return _h4LineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _h4LineHeight;
}

- (void)setH4LineHeight:(CGFloat)newValue
{
  _h4LineHeight = newValue;
}

- (NSTextAlignment)h4TextAlign
{
  return _h4TextAlign;
}

- (void)setH4TextAlign:(NSTextAlignment)newValue
{
  _h4TextAlign = newValue;
}

- (UIFont *)h4Font
{
  if (_h4FontNeedsRecreation || !_h4Font) {
    _h4Font = [RCTFont updateFont:nil
                       withFamily:_h4FontFamily
                             size:@(_h4FontSize)
                           weight:normalizedFontWeight(_h4FontWeight)
                            style:nil
                          variant:nil
                  scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_h4FontSize]];
    _h4FontNeedsRecreation = NO;
  }
  return _h4Font;
}

- (CGFloat)h5FontSize
{
  return _h5FontSize;
}

- (void)setH5FontSize:(CGFloat)newValue
{
  _h5FontSize = newValue;
  _h5FontNeedsRecreation = YES;
}

- (NSString *)h5FontFamily
{
  return _h5FontFamily;
}

- (void)setH5FontFamily:(NSString *)newValue
{
  _h5FontFamily = newValue;
  _h5FontNeedsRecreation = YES;
}

- (NSString *)h5FontWeight
{
  return _h5FontWeight;
}

- (void)setH5FontWeight:(NSString *)newValue
{
  _h5FontWeight = newValue;
  _h5FontNeedsRecreation = YES;
}

- (UIColor *)h5Color
{
  return _h5Color;
}

- (void)setH5Color:(UIColor *)newValue
{
  _h5Color = newValue;
}

- (CGFloat)h5MarginTop
{
  return _h5MarginTop;
}

- (void)setH5MarginTop:(CGFloat)newValue
{
  _h5MarginTop = newValue;
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
  if (_allowFontScaling && _h5LineHeight > 0) {
    return _h5LineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _h5LineHeight;
}

- (void)setH5LineHeight:(CGFloat)newValue
{
  _h5LineHeight = newValue;
}

- (NSTextAlignment)h5TextAlign
{
  return _h5TextAlign;
}

- (void)setH5TextAlign:(NSTextAlignment)newValue
{
  _h5TextAlign = newValue;
}

- (UIFont *)h5Font
{
  if (_h5FontNeedsRecreation || !_h5Font) {
    _h5Font = [RCTFont updateFont:nil
                       withFamily:_h5FontFamily
                             size:@(_h5FontSize)
                           weight:normalizedFontWeight(_h5FontWeight)
                            style:nil
                          variant:nil
                  scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_h5FontSize]];
    _h5FontNeedsRecreation = NO;
  }
  return _h5Font;
}

- (CGFloat)h6FontSize
{
  return _h6FontSize;
}

- (void)setH6FontSize:(CGFloat)newValue
{
  _h6FontSize = newValue;
  _h6FontNeedsRecreation = YES;
}

- (NSString *)h6FontFamily
{
  return _h6FontFamily;
}

- (void)setH6FontFamily:(NSString *)newValue
{
  _h6FontFamily = newValue;
  _h6FontNeedsRecreation = YES;
}

- (NSString *)h6FontWeight
{
  return _h6FontWeight;
}

- (void)setH6FontWeight:(NSString *)newValue
{
  _h6FontWeight = newValue;
  _h6FontNeedsRecreation = YES;
}

- (UIColor *)h6Color
{
  return _h6Color;
}

- (void)setH6Color:(UIColor *)newValue
{
  _h6Color = newValue;
}

- (CGFloat)h6MarginTop
{
  return _h6MarginTop;
}

- (void)setH6MarginTop:(CGFloat)newValue
{
  _h6MarginTop = newValue;
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
  if (_allowFontScaling && _h6LineHeight > 0) {
    return _h6LineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _h6LineHeight;
}

- (void)setH6LineHeight:(CGFloat)newValue
{
  _h6LineHeight = newValue;
}

- (NSTextAlignment)h6TextAlign
{
  return _h6TextAlign;
}

- (void)setH6TextAlign:(NSTextAlignment)newValue
{
  _h6TextAlign = newValue;
}

- (UIFont *)h6Font
{
  if (_h6FontNeedsRecreation || !_h6Font) {
    _h6Font = [RCTFont updateFont:nil
                       withFamily:_h6FontFamily
                             size:@(_h6FontSize)
                           weight:normalizedFontWeight(_h6FontWeight)
                            style:nil
                          variant:nil
                  scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_h6FontSize]];
    _h6FontNeedsRecreation = NO;
  }
  return _h6Font;
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

- (UIColor *)strikethroughColor
{
  return _strikethroughColor;
}

- (void)setStrikethroughColor:(UIColor *)newValue
{
  _strikethroughColor = newValue;
}

- (UIColor *)underlineColor
{
  return _underlineColor;
}

- (void)setUnderlineColor:(UIColor *)newValue
{
  _underlineColor = newValue;
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

- (CGFloat)imageMarginTop
{
  return _imageMarginTop;
}

- (void)setImageMarginTop:(CGFloat)newValue
{
  _imageMarginTop = newValue;
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
  _blockquoteFontNeedsRecreation = YES;
}

- (NSString *)blockquoteFontFamily
{
  return _blockquoteFontFamily;
}

- (void)setBlockquoteFontFamily:(NSString *)newValue
{
  _blockquoteFontFamily = newValue;
  _blockquoteFontNeedsRecreation = YES;
}

- (NSString *)blockquoteFontWeight
{
  return _blockquoteFontWeight;
}

- (void)setBlockquoteFontWeight:(NSString *)newValue
{
  _blockquoteFontWeight = newValue;
  _blockquoteFontNeedsRecreation = YES;
}

- (UIColor *)blockquoteColor
{
  return _blockquoteColor;
}

- (void)setBlockquoteColor:(UIColor *)newValue
{
  _blockquoteColor = newValue;
}

- (CGFloat)blockquoteMarginTop
{
  return _blockquoteMarginTop;
}

- (void)setBlockquoteMarginTop:(CGFloat)newValue
{
  _blockquoteMarginTop = newValue;
}

- (CGFloat)blockquoteMarginBottom
{
  return _blockquoteMarginBottom;
}

- (void)setBlockquoteMarginBottom:(CGFloat)newValue
{
  _blockquoteMarginBottom = newValue;
}

- (CGFloat)blockquoteLineHeight
{
  if (_allowFontScaling && _blockquoteLineHeight > 0) {
    return _blockquoteLineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _blockquoteLineHeight;
}

- (void)setBlockquoteLineHeight:(CGFloat)newValue
{
  _blockquoteLineHeight = newValue;
}

- (UIFont *)blockquoteFont
{
  if (_blockquoteFontNeedsRecreation || !_blockquoteFont) {
    _blockquoteFont = [RCTFont updateFont:nil
                               withFamily:_blockquoteFontFamily
                                     size:@(_blockquoteFontSize)
                                   weight:normalizedFontWeight(_blockquoteFontWeight)
                                    style:nil
                                  variant:nil
                          scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_blockquoteFontSize]];
    _blockquoteFontNeedsRecreation = NO;
  }
  return _blockquoteFont;
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
  _listMarkerFontNeedsRecreation = YES;
  _listStyleFontNeedsRecreation = YES;
}

- (NSString *)listStyleFontFamily
{
  return _listStyleFontFamily;
}

- (void)setListStyleFontFamily:(NSString *)newValue
{
  _listStyleFontFamily = newValue;
  _listMarkerFontNeedsRecreation = YES;
  _listStyleFontNeedsRecreation = YES;
}

- (NSString *)listStyleFontWeight
{
  return _listStyleFontWeight;
}

- (void)setListStyleFontWeight:(NSString *)newValue
{
  _listStyleFontWeight = newValue;
  _listStyleFontNeedsRecreation = YES;
}

- (UIColor *)listStyleColor
{
  return _listStyleColor;
}

- (void)setListStyleColor:(UIColor *)newValue
{
  _listStyleColor = newValue;
}

- (CGFloat)listStyleMarginTop
{
  return _listStyleMarginTop;
}

- (void)setListStyleMarginTop:(CGFloat)newValue
{
  _listStyleMarginTop = newValue;
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
  if (_allowFontScaling && _listStyleLineHeight > 0) {
    return _listStyleLineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
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
  _listMarkerFontNeedsRecreation = YES;
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

- (UIFont *)listMarkerFont
{
  if (_listMarkerFontNeedsRecreation || !_listMarkerFont) {
    _listMarkerFont = [RCTFont updateFont:nil
                               withFamily:_listStyleFontFamily
                                     size:@(_listStyleFontSize)
                                   weight:normalizedFontWeight(_listStyleMarkerFontWeight)
                                    style:nil
                                  variant:nil
                          scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_listStyleFontSize]];
    _listMarkerFontNeedsRecreation = NO;
  }
  return _listMarkerFont;
}

- (UIFont *)listStyleFont
{
  if (_listStyleFontNeedsRecreation || !_listStyleFont) {
    _listStyleFont = [RCTFont updateFont:nil
                              withFamily:_listStyleFontFamily
                                    size:@(_listStyleFontSize)
                                  weight:normalizedFontWeight(_listStyleFontWeight)
                                   style:nil
                                 variant:nil
                         scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_listStyleFontSize]];
    _listStyleFontNeedsRecreation = NO;
  }
  return _listStyleFont;
}

static const CGFloat kDefaultMinGap = 4.0;

- (CGFloat)effectiveListGapWidth
{
  return MAX(_listStyleGapWidth, kDefaultMinGap);
}

- (CGFloat)effectiveListMarginLeftForBullet
{
  // Just the minimum width needed for bullet (radius)
  return _listStyleBulletSize / 2.0;
}

- (CGFloat)effectiveListMarginLeftForNumber
{
  // Reserve width for numbers up to 99 (matching Android)
  UIFont *font = [self listMarkerFont];
  return
      [@"99." sizeWithAttributes:@{NSFontAttributeName : font ?: [UIFont systemFontOfSize:_listStyleFontSize]}].width;
}

// Code block properties
- (CGFloat)codeBlockFontSize
{
  return _codeBlockFontSize;
}

- (void)setCodeBlockFontSize:(CGFloat)newValue
{
  _codeBlockFontSize = newValue;
  _codeBlockFontNeedsRecreation = YES;
}

- (NSString *)codeBlockFontFamily
{
  return _codeBlockFontFamily;
}

- (void)setCodeBlockFontFamily:(NSString *)newValue
{
  _codeBlockFontFamily = newValue;
  _codeBlockFontNeedsRecreation = YES;
}

- (NSString *)codeBlockFontWeight
{
  return _codeBlockFontWeight;
}

- (void)setCodeBlockFontWeight:(NSString *)newValue
{
  _codeBlockFontWeight = newValue;
  _codeBlockFontNeedsRecreation = YES;
}

- (UIColor *)codeBlockColor
{
  return _codeBlockColor;
}

- (void)setCodeBlockColor:(UIColor *)newValue
{
  _codeBlockColor = newValue;
}

- (CGFloat)codeBlockMarginTop
{
  return _codeBlockMarginTop;
}

- (void)setCodeBlockMarginTop:(CGFloat)newValue
{
  _codeBlockMarginTop = newValue;
}

- (CGFloat)codeBlockMarginBottom
{
  return _codeBlockMarginBottom;
}

- (void)setCodeBlockMarginBottom:(CGFloat)newValue
{
  _codeBlockMarginBottom = newValue;
}

- (CGFloat)codeBlockLineHeight
{
  if (_allowFontScaling && _codeBlockLineHeight > 0) {
    return _codeBlockLineHeight * RCTFontSizeMultiplierWithMax(_maxFontSizeMultiplier);
  }
  return _codeBlockLineHeight;
}

- (void)setCodeBlockLineHeight:(CGFloat)newValue
{
  _codeBlockLineHeight = newValue;
}

- (UIColor *)codeBlockBackgroundColor
{
  return _codeBlockBackgroundColor;
}

- (void)setCodeBlockBackgroundColor:(UIColor *)newValue
{
  _codeBlockBackgroundColor = newValue;
}

- (UIColor *)codeBlockBorderColor
{
  return _codeBlockBorderColor;
}

- (void)setCodeBlockBorderColor:(UIColor *)newValue
{
  _codeBlockBorderColor = newValue;
}

- (CGFloat)codeBlockBorderRadius
{
  return _codeBlockBorderRadius;
}

- (void)setCodeBlockBorderRadius:(CGFloat)newValue
{
  _codeBlockBorderRadius = newValue;
}

- (CGFloat)codeBlockBorderWidth
{
  return _codeBlockBorderWidth;
}

- (void)setCodeBlockBorderWidth:(CGFloat)newValue
{
  _codeBlockBorderWidth = newValue;
}

- (CGFloat)codeBlockPadding
{
  return _codeBlockPadding;
}

- (void)setCodeBlockPadding:(CGFloat)newValue
{
  _codeBlockPadding = newValue;
}

- (UIFont *)codeBlockFont
{
  if (_codeBlockFontNeedsRecreation || !_codeBlockFont) {
    _codeBlockFont = [RCTFont updateFont:nil
                              withFamily:_codeBlockFontFamily
                                    size:@(_codeBlockFontSize)
                                  weight:normalizedFontWeight(_codeBlockFontWeight)
                                   style:nil
                                 variant:nil
                         scaleMultiplier:[self effectiveScaleMultiplierForFontSize:_codeBlockFontSize]];
    _codeBlockFontNeedsRecreation = NO;
  }
  return _codeBlockFont;
}

// Thematic break properties
- (UIColor *)thematicBreakColor
{
  return _thematicBreakColor;
}

- (void)setThematicBreakColor:(UIColor *)newValue
{
  _thematicBreakColor = newValue;
}

- (CGFloat)thematicBreakHeight
{
  return _thematicBreakHeight;
}

- (void)setThematicBreakHeight:(CGFloat)newValue
{
  _thematicBreakHeight = newValue;
}

- (CGFloat)thematicBreakMarginTop
{
  return _thematicBreakMarginTop;
}

- (void)setThematicBreakMarginTop:(CGFloat)newValue
{
  _thematicBreakMarginTop = newValue;
}

- (CGFloat)thematicBreakMarginBottom
{
  return _thematicBreakMarginBottom;
}

- (void)setThematicBreakMarginBottom:(CGFloat)newValue
{
  _thematicBreakMarginBottom = newValue;
}

@end
