#pragma once

#import "ENRMUIKit.h"

@class ENRMRenderedSegment;

NS_ASSUME_NONNULL_BEGIN

@interface ENRMSegmentReconciliationResult : NSObject
@property (nonatomic, strong) NSMutableArray<RCTUIView *> *views;
@property (nonatomic, strong) NSMutableArray<NSString *> *signatures;
@end

@interface ENRMSegmentReconciler : NSObject
// Reuses views by index when the segment kind still matches. Matching
// signatures skip updates; changed signatures update the existing view.
+ (ENRMSegmentReconciliationResult *)
    reconcileCurrentViews:(NSArray<RCTUIView *> *)currentViews
        currentSignatures:(NSArray<NSString *> *)currentSignatures
         renderedSegments:(NSArray<ENRMRenderedSegment *> *)renderedSegments
                    reset:(BOOL)reset
               createView:(RCTUIView * (^)(ENRMRenderedSegment *segment))createView
               updateView:(void (^)(RCTUIView *view, ENRMRenderedSegment *segment))updateView
               attachView:(void (^)(RCTUIView *view))attachView
               removeView:(void (^)(RCTUIView *view))removeView
              matchesKind:(BOOL (^)(RCTUIView *view, ENRMRenderedSegment *segment))matchesKind;
@end

NS_ASSUME_NONNULL_END
