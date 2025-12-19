#pragma once
#import <UIKit/UIKit.h>

@interface RichTextConfig : NSObject <NSCopying>
- (instancetype)init;
// Primary font properties
- (UIColor *)primaryColor;
- (void)setPrimaryColor:(UIColor *)newValue;
- (NSNumber *)primaryFontSize;
- (void)setPrimaryFontSize:(NSNumber *)newValue;
- (NSString *)primaryFontWeight;
- (void)setPrimaryFontWeight:(NSString *)newValue;
- (NSString *)primaryFontFamily;
- (void)setPrimaryFontFamily:(NSString *)newValue;
- (UIFont *)primaryFont;
// Paragraph properties
- (CGFloat)paragraphFontSize;
- (void)setParagraphFontSize:(CGFloat)newValue;
- (NSString *)paragraphFontFamily;
- (void)setParagraphFontFamily:(NSString *)newValue;
- (NSString *)paragraphFontWeight;
- (void)setParagraphFontWeight:(NSString *)newValue;
- (UIColor *)paragraphColor;
- (void)setParagraphColor:(UIColor *)newValue;
- (CGFloat)paragraphMarginBottom;
- (void)setParagraphMarginBottom:(CGFloat)newValue;
// H1 properties
- (CGFloat)h1FontSize;
- (void)setH1FontSize:(CGFloat)newValue;
- (NSString *)h1FontFamily;
- (void)setH1FontFamily:(NSString *)newValue;
- (NSString *)h1FontWeight;
- (void)setH1FontWeight:(NSString *)newValue;
- (UIColor *)h1Color;
- (void)setH1Color:(UIColor *)newValue;
- (CGFloat)h1MarginBottom;
- (void)setH1MarginBottom:(CGFloat)newValue;
// H2 properties
- (CGFloat)h2FontSize;
- (void)setH2FontSize:(CGFloat)newValue;
- (NSString *)h2FontFamily;
- (void)setH2FontFamily:(NSString *)newValue;
- (NSString *)h2FontWeight;
- (void)setH2FontWeight:(NSString *)newValue;
- (UIColor *)h2Color;
- (void)setH2Color:(UIColor *)newValue;
- (CGFloat)h2MarginBottom;
- (void)setH2MarginBottom:(CGFloat)newValue;
// H3 properties
- (CGFloat)h3FontSize;
- (void)setH3FontSize:(CGFloat)newValue;
- (NSString *)h3FontFamily;
- (void)setH3FontFamily:(NSString *)newValue;
- (NSString *)h3FontWeight;
- (void)setH3FontWeight:(NSString *)newValue;
- (UIColor *)h3Color;
- (void)setH3Color:(UIColor *)newValue;
- (CGFloat)h3MarginBottom;
- (void)setH3MarginBottom:(CGFloat)newValue;
// H4 properties
- (CGFloat)h4FontSize;
- (void)setH4FontSize:(CGFloat)newValue;
- (NSString *)h4FontFamily;
- (void)setH4FontFamily:(NSString *)newValue;
- (NSString *)h4FontWeight;
- (void)setH4FontWeight:(NSString *)newValue;
- (UIColor *)h4Color;
- (void)setH4Color:(UIColor *)newValue;
- (CGFloat)h4MarginBottom;
- (void)setH4MarginBottom:(CGFloat)newValue;
// H5 properties
- (CGFloat)h5FontSize;
- (void)setH5FontSize:(CGFloat)newValue;
- (NSString *)h5FontFamily;
- (void)setH5FontFamily:(NSString *)newValue;
- (NSString *)h5FontWeight;
- (void)setH5FontWeight:(NSString *)newValue;
- (UIColor *)h5Color;
- (void)setH5Color:(UIColor *)newValue;
- (CGFloat)h5MarginBottom;
- (void)setH5MarginBottom:(CGFloat)newValue;
// H6 properties
- (CGFloat)h6FontSize;
- (void)setH6FontSize:(CGFloat)newValue;
- (NSString *)h6FontFamily;
- (void)setH6FontFamily:(NSString *)newValue;
- (NSString *)h6FontWeight;
- (void)setH6FontWeight:(NSString *)newValue;
- (UIColor *)h6Color;
- (void)setH6Color:(UIColor *)newValue;
- (CGFloat)h6MarginBottom;
- (void)setH6MarginBottom:(CGFloat)newValue;
// Link properties
- (UIColor *)linkColor;
- (void)setLinkColor:(UIColor *)newValue;
- (BOOL)linkUnderline;
- (void)setLinkUnderline:(BOOL)newValue;
// Strong properties
- (UIColor *)strongColor;
- (void)setStrongColor:(UIColor *)newValue;
// Emphasis properties
- (UIColor *)emphasisColor;
- (void)setEmphasisColor:(UIColor *)newValue;
// Code properties
- (UIColor *)codeColor;
- (void)setCodeColor:(UIColor *)newValue;
- (UIColor *)codeBackgroundColor;
- (void)setCodeBackgroundColor:(UIColor *)newValue;
- (UIColor *)codeBorderColor;
- (void)setCodeBorderColor:(UIColor *)newValue;
// Image properties
- (CGFloat)imageHeight;
- (void)setImageHeight:(CGFloat)newValue;
- (CGFloat)imageBorderRadius;
- (void)setImageBorderRadius:(CGFloat)newValue;
- (CGFloat)imageMarginBottom;
- (void)setImageMarginBottom:(CGFloat)newValue;
// Inline image properties
- (CGFloat)inlineImageSize;
- (void)setInlineImageSize:(CGFloat)newValue;

@end
