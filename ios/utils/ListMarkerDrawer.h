#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StyleConfig;

@interface ListMarkerDrawer : NSObject

- (instancetype)initWithConfig:(StyleConfig *)config;

- (void)drawMarkersForGlyphRange:(NSRange)glyphsToShow
                   layoutManager:(NSLayoutManager *)layoutManager
                   textContainer:(NSTextContainer *)textContainer
                         atPoint:(CGPoint)origin;

@end
