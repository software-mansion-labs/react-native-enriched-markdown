#import "EnrichedMarkdownTextShadowNode.h"
#import "EnrichedMarkdownText.h"
#import "ShadowMeasurementUtils.h"
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>

namespace facebook::react {

extern const char EnrichedMarkdownTextComponentName[] = "EnrichedMarkdownText";

static bool ENRMTextPropsNeedExactStreamingMeasurement(const EnrichedMarkdownTextProps &oldProps,
                                                       const EnrichedMarkdownTextProps &newProps)
{
  // Streaming normally reuses the current native bounds to avoid re-measuring
  // every token. Layout-affecting prop changes still need one exact pass.
  return oldProps.streamingAnimation != newProps.streamingAnimation ||
         oldProps.allowFontScaling != newProps.allowFontScaling ||
         oldProps.maxFontSizeMultiplier != newProps.maxFontSizeMultiplier ||
         oldProps.allowTrailingMargin != newProps.allowTrailingMargin ||
         oldProps.md4cFlags.underline != newProps.md4cFlags.underline ||
         oldProps.md4cFlags.latexMath != newProps.md4cFlags.latexMath ||
         computeStyleFingerprint(oldProps.markdownStyle) != computeStyleFingerprint(newProps.markdownStyle);
}

EnrichedMarkdownTextShadowNode::EnrichedMarkdownTextShadowNode(const ShadowNodeFragment &fragment,
                                                               const ShadowNodeFamily::Shared &family,
                                                               ShadowNodeTraits traits)
    : ConcreteViewShadowNode(fragment, family, traits)
{
}

EnrichedMarkdownTextShadowNode::EnrichedMarkdownTextShadowNode(const ShadowNode &sourceShadowNode,
                                                               const ShadowNodeFragment &fragment)
    : ConcreteViewShadowNode(sourceShadowNode, fragment),
      localHeightRecalculationCounter_(
          static_cast<const EnrichedMarkdownTextShadowNode &>(sourceShadowNode).localHeightRecalculationCounter_),
      lastExactMeasurementCounter_(
          static_cast<const EnrichedMarkdownTextShadowNode &>(sourceShadowNode).lastExactMeasurementCounter_)
{
  const auto &oldProps = *std::static_pointer_cast<const EnrichedMarkdownTextProps>(sourceShadowNode.getProps());
  const auto &newProps = *std::static_pointer_cast<const EnrichedMarkdownTextProps>(this->getProps());

  if (newProps.streamingAnimation && ENRMTextPropsNeedExactStreamingMeasurement(oldProps, newProps)) {
    lastExactMeasurementCounter_ = -1;
  }

  dirtyLayoutIfNeeded();
}

void EnrichedMarkdownTextShadowNode::dirtyLayoutIfNeeded()
{
  const auto state = this->getStateData();
  const int receivedCounter = state.getHeightRecalculationCounter();

  if (receivedCounter > localHeightRecalculationCounter_) {
    localHeightRecalculationCounter_ = receivedCounter;
    YGNodeMarkDirty(&yogaNode_);
  }
}

/// Creates a mock view off-screen to measure content when real view isn't ready yet.
id EnrichedMarkdownTextShadowNode::setupMockEnrichedMarkdownText_(CGFloat width) const
{
  EnrichedMarkdownText *mockView = [[EnrichedMarkdownText alloc] initWithFrame:CGRectMake(20000, 20000, width, 1000)];

  const auto props = this->getProps();
  [mockView updateProps:props oldProps:nullptr];

  // Render markdown synchronously for accurate measurement
  const auto &typedProps = *std::static_pointer_cast<const EnrichedMarkdownTextProps>(props);
  if (!typedProps.markdown.empty()) {
    NSString *markdown = [NSString stringWithUTF8String:typedProps.markdown.c_str()];
    [mockView renderMarkdownSynchronously:markdown];
  }

  return mockView;
}

Size EnrichedMarkdownTextShadowNode::measureContent(const LayoutContext &layoutContext,
                                                    const LayoutConstraints &layoutConstraints) const
{
  CGFloat maxWidth = layoutConstraints.maximumSize.width;

  const auto &typedProps = *std::static_pointer_cast<const EnrichedMarkdownTextProps>(this->getProps());

  // Check measurement cache before creating mock views or dispatching to main thread.
  // This avoids the expensive mock view + synchronous md4c parse path for repeated content.
  RCTInternalGenericWeakWrapper *weakWrapper =
      (RCTInternalGenericWeakWrapper *)unwrapManagedObject(getStateData().getComponentViewRef());
  EnrichedMarkdownText *view = weakWrapper ? (EnrichedMarkdownText *)weakWrapper.object : nil;

  const int receivedCounter = getStateData().getHeightRecalculationCounter();

  if (typedProps.streamingAnimation && view && receivedCounter <= lastExactMeasurementCounter_) {
    __block CGSize currentSize = CGSizeZero;
    void (^readCurrentSize)(void) = ^{
      if (view.bounds.size.width > 0 && view.bounds.size.height > 0) {
        currentSize = view.bounds.size;
      }
    };

    if ([NSThread isMainThread]) {
      readCurrentSize();
    } else {
      dispatch_sync(dispatch_get_main_queue(), readCurrentSize);
    }

    if (currentSize.height > 0) {
      return ENRMClampMeasuredSize(currentSize, layoutConstraints);
    }
  }

  const bool shouldUseMeasurementCache = !typedProps.streamingAnimation;
  CGFloat fontScale = shouldUseMeasurementCache ? ENRMFontScaleForMeasurement(typedProps.allowFontScaling) : 1.0;

  if (shouldUseMeasurementCache && !typedProps.markdown.empty()) {
    auto cacheKey = buildMeasurementCacheKey(typedProps, maxWidth, fontScale, MarkdownFlavor::CommonMark);
    CachedSize cached;
    if (MeasurementCache::shared().get(cacheKey, cached)) {
      return ENRMClampMeasuredSize(CGSizeMake(cached.width, cached.height), layoutConstraints);
    }
  }

  __block CGSize size;
  NSString *currentMarkdown = typedProps.markdown.empty() ? nil : @(typedProps.markdown.c_str());

  void (^measureBlock)(void) = ^{
    if (view && (typedProps.streamingAnimation || [view hasRenderedMarkdown:currentMarkdown])) {
      size = [view measureSize:maxWidth];
    } else {
      EnrichedMarkdownText *mockView = setupMockEnrichedMarkdownText_(maxWidth);
      size = [mockView measureSize:maxWidth];
    }
  };

  if ([NSThread isMainThread]) {
    measureBlock();
  } else {
    dispatch_sync(dispatch_get_main_queue(), measureBlock);
  }

  if (shouldUseMeasurementCache && !typedProps.markdown.empty()) {
    auto cacheKey = buildMeasurementCacheKey(typedProps, maxWidth, fontScale, MarkdownFlavor::CommonMark);
    MeasurementCache::shared().set(cacheKey, {size.width, size.height});
  }

  if (typedProps.streamingAnimation) {
    lastExactMeasurementCounter_ = receivedCounter;
  }

  return ENRMClampMeasuredSize(size, layoutConstraints);
}

} // namespace facebook::react
