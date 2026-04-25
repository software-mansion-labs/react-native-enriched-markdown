#import "SegmentReconciler.h"
#import "RenderedMarkdownSegment.h"

@implementation ENRMSegmentReconciliationResult
@end

@implementation ENRMSegmentReconciler
+ (ENRMSegmentReconciliationResult *)
    reconcileCurrentViews:(NSArray<RCTUIView *> *)currentViews
        currentSignatures:(NSArray<NSNumber *> *)currentSignatures
         renderedSegments:(NSArray<ENRMRenderedSegment *> *)renderedSegments
                    reset:(BOOL)reset
               createView:(RCTUIView * (^)(ENRMRenderedSegment *segment))createView
               updateView:(void (^)(RCTUIView *view, ENRMRenderedSegment *segment))updateView
               attachView:(void (^)(RCTUIView *view))attachView
               removeView:(void (^)(RCTUIView *view))removeView
              matchesKind:(BOOL (^)(RCTUIView *view, ENRMRenderedSegment *segment))matchesKind
{
  NSArray<RCTUIView *> *sourceViews = currentViews;
  NSArray<NSNumber *> *sourceSignatures = currentSignatures;

  if (reset) {
    [currentViews enumerateObjectsUsingBlock:^(RCTUIView *view, NSUInteger index, BOOL *stop) { removeView(view); }];
    sourceViews = @[];
    sourceSignatures = @[];
  }

  NSMutableArray<RCTUIView *> *nextViews = [NSMutableArray arrayWithCapacity:renderedSegments.count];
  NSMutableArray<NSNumber *> *nextSignatures = [NSMutableArray arrayWithCapacity:renderedSegments.count];
  NSMutableSet<RCTUIView *> *reusedViews = [NSMutableSet setWithCapacity:sourceViews.count];

  [renderedSegments enumerateObjectsUsingBlock:^(ENRMRenderedSegment *segment, NSUInteger index, BOOL *stop) {
    RCTUIView *existingView = index < sourceViews.count ? sourceViews[index] : nil;
    NSNumber *existingSignature = index < sourceSignatures.count ? sourceSignatures[index] : nil;
    RCTUIView *view = nil;
    NSNumber *nextSignature = @(segment.signature);

    if (existingView && matchesKind(existingView, segment)) {
      if (![existingSignature isEqual:nextSignature]) {
        updateView(existingView, segment);
      }
      view = existingView;
    } else {
      view = createView(segment);
      attachView(view);
    }

    [nextViews addObject:view];
    [nextSignatures addObject:nextSignature];
    [reusedViews addObject:view];
  }];

  [sourceViews enumerateObjectsUsingBlock:^(RCTUIView *view, NSUInteger index, BOOL *stop) {
    if (![reusedViews containsObject:view]) {
      removeView(view);
    }
  }];

  ENRMSegmentReconciliationResult *result = [[ENRMSegmentReconciliationResult alloc] init];
  result.views = nextViews;
  result.signatures = nextSignatures;
  return result;
}
@end
