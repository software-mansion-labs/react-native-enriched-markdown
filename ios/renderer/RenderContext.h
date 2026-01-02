#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BlockType) {
  BlockTypeNone,
  BlockTypeParagraph,
  BlockTypeHeading,
  BlockTypeBlockquote,
  BlockTypeUnorderedList,
  BlockTypeOrderedList
};

typedef NS_ENUM(NSInteger, ListType) { ListTypeUnordered, ListTypeOrdered };

@interface BlockStyle : NSObject
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, strong) NSString *fontFamily;
@property (nonatomic, strong) NSString *fontWeight;
@property (nonatomic, strong) UIColor *color;
@end

@interface RenderContext : NSObject
@property (nonatomic, strong) NSMutableArray<NSValue *> *linkRanges;
@property (nonatomic, strong) NSMutableArray<NSString *> *linkURLs;
@property (nonatomic, assign) BlockType currentBlockType;
@property (nonatomic, strong) BlockStyle *currentBlockStyle;
@property (nonatomic, assign) NSInteger currentHeadingLevel;
@property (nonatomic, assign) NSInteger blockquoteDepth;
@property (nonatomic, assign) NSInteger listDepth;
@property (nonatomic, assign) ListType listType;
@property (nonatomic, assign) NSInteger listItemNumber;

- (instancetype)init;
- (void)reset;
- (void)registerLinkRange:(NSRange)range url:(NSString *)url;
- (void)setBlockStyle:(BlockType)type
             fontSize:(CGFloat)fontSize
           fontFamily:(NSString *)fontFamily
           fontWeight:(NSString *)fontWeight
                color:(UIColor *)color;
- (void)setBlockStyle:(BlockType)type
             fontSize:(CGFloat)fontSize
           fontFamily:(NSString *)fontFamily
           fontWeight:(NSString *)fontWeight
                color:(UIColor *)color
         headingLevel:(NSInteger)headingLevel;
- (BlockStyle *)getBlockStyle;
- (void)clearBlockStyle;

/**
 * Checks if colors should be preserved based on existing attributes.
 * Returns YES if the text is inside a link or inline code, which means
 * we should preserve their colors instead of applying new colors.
 */
+ (BOOL)shouldPreserveColors:(NSDictionary *)existingAttributes;

/**
 * Calculates the color that strong would use based on the configured strong color and block style.
 * Uses strongColor if explicitly set (different from block color), otherwise uses block color.
 */
+ (UIColor *)calculateStrongColor:(UIColor *)configStrongColor blockColor:(UIColor *)blockColor;

/**
 * Calculates the range for content rendered between start and current output length.
 * Returns a range with length 0 if no content was rendered.
 */
+ (NSRange)rangeForRenderedContent:(NSMutableAttributedString *)output start:(NSUInteger)start;

/**
 * Applies font and color attributes conditionally, only updating if they've changed.
 * Returns YES if any attributes were updated, NO otherwise.
 */
+ (BOOL)applyFontAndColorAttributes:(NSMutableAttributedString *)output
                              range:(NSRange)range
                               font:(UIFont *)font
                              color:(UIColor *)color
                 existingAttributes:(NSDictionary *)existingAttributes
               shouldPreserveColors:(BOOL)shouldPreserveColors;
@end
