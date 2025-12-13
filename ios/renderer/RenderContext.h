#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BlockType) { BlockTypeNone, BlockTypeParagraph, BlockTypeHeading };

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

- (instancetype)init;
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
@end
