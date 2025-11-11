#pragma once
#import <UIKit/UIKit.h>

@interface RichTextConfig: NSObject<NSCopying>
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
// H1 properties
- (CGFloat)h1FontSize;
- (void)setH1FontSize:(CGFloat)newValue;
- (NSString *)h1FontFamily;
- (void)setH1FontFamily:(NSString *)newValue;
// H2 properties
- (CGFloat)h2FontSize;
- (void)setH2FontSize:(CGFloat)newValue;
- (NSString *)h2FontFamily;
- (void)setH2FontFamily:(NSString *)newValue;
// H3 properties
- (CGFloat)h3FontSize;
- (void)setH3FontSize:(CGFloat)newValue;
- (NSString *)h3FontFamily;
- (void)setH3FontFamily:(NSString *)newValue;
// H4 properties
- (CGFloat)h4FontSize;
- (void)setH4FontSize:(CGFloat)newValue;
- (NSString *)h4FontFamily;
- (void)setH4FontFamily:(NSString *)newValue;
// H5 properties
- (CGFloat)h5FontSize;
- (void)setH5FontSize:(CGFloat)newValue;
- (NSString *)h5FontFamily;
- (void)setH5FontFamily:(NSString *)newValue;
// H6 properties
- (CGFloat)h6FontSize;
- (void)setH6FontSize:(CGFloat)newValue;
- (NSString *)h6FontFamily;
- (void)setH6FontFamily:(NSString *)newValue;
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

@end
