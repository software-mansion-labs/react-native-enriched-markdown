#pragma once
#import "ENRMFeatureFlags.h"
#import "ENRMMathInlineAttachment.h"

#if ENRICHED_MARKDOWN_MATH
#import <IosMath/IosMath.h>

@interface ENRMMathInlineAttachment () {
  CGSize _cachedSize;
  CGFloat _mathAscent;
  CGFloat _mathDescent;
  MTMathListDisplay *_displayList;
}
@end

#endif
