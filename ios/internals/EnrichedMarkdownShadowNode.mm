#import "EnrichedMarkdownShadowNode.h"
#import "EnrichedMarkdown.h"
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>

namespace facebook::react {

extern const char EnrichedMarkdownComponentName[] = "EnrichedMarkdown";

EnrichedMarkdownShadowNode::EnrichedMarkdownShadowNode(const ShadowNodeFragment &fragment,
                                                       const ShadowNodeFamily::Shared &family, ShadowNodeTraits traits)
    : ConcreteViewShadowNode(fragment, family, traits)
{
}

EnrichedMarkdownShadowNode::EnrichedMarkdownShadowNode(const ShadowNode &sourceShadowNode,
                                                       const ShadowNodeFragment &fragment)
    : ConcreteViewShadowNode(sourceShadowNode, fragment)
{
  dirtyLayoutIfNeeded();
}

void EnrichedMarkdownShadowNode::dirtyLayoutIfNeeded()
{
  const auto state = this->getStateData();
  const int receivedCounter = state.getHeightRecalculationCounter();

  if (receivedCounter > localHeightRecalculationCounter_) {
    localHeightRecalculationCounter_ = receivedCounter;
    YGNodeMarkDirty(&yogaNode_);
  }
}

/// Creates a mock view off-screen to measure content when real view isn't ready yet.
id EnrichedMarkdownShadowNode::setupMockEnrichedMarkdown_(CGFloat width) const
{
  EnrichedMarkdown *mockView = [[EnrichedMarkdown alloc] initWithFrame:CGRectMake(20000, 20000, width, 1000)];

  const auto props = this->getProps();
  [mockView updateProps:props oldProps:nullptr];

  // Render markdown synchronously for accurate measurement
  const auto &typedProps = *std::static_pointer_cast<const EnrichedMarkdownProps>(props);
  if (!typedProps.markdown.empty()) {
    NSString *markdown = [NSString stringWithUTF8String:typedProps.markdown.c_str()];
    [mockView renderMarkdownSynchronously:markdown];
  }

  return mockView;
}

Size EnrichedMarkdownShadowNode::measureContent(const LayoutContext &layoutContext,
                                                const LayoutConstraints &layoutConstraints) const
{
  CGFloat maxWidth = layoutConstraints.maximumSize.width;

  const auto &typedProps = *std::static_pointer_cast<const EnrichedMarkdownProps>(this->getProps());

  CGFloat fontScale = typedProps.allowFontScaling ? RCTFontSizeMultiplier() : 1.0;

  if (!typedProps.markdown.empty()) {
    auto cacheKey = buildMeasurementCacheKey(typedProps, maxWidth, fontScale, MarkdownFlavor::GitHub);
    CachedSize cached;
    if (MeasurementCache::shared().get(cacheKey, cached)) {
      Float cachedWidth = std::max(cached.width, layoutConstraints.minimumSize.width);
      cachedWidth = std::min(cachedWidth, layoutConstraints.maximumSize.width);
      Float cachedHeight = std::max(cached.height, layoutConstraints.minimumSize.height);
      if (std::isfinite(layoutConstraints.maximumSize.height)) {
        cachedHeight = std::min(cachedHeight, layoutConstraints.maximumSize.height);
      }
      return {cachedWidth, cachedHeight};
    }
  }

  RCTInternalGenericWeakWrapper *weakWrapper =
      (RCTInternalGenericWeakWrapper *)unwrapManagedObject(getStateData().getComponentViewRef());
  EnrichedMarkdown *view = weakWrapper ? (EnrichedMarkdown *)weakWrapper.object : nil;

  NSString *currentMarkdown = typedProps.markdown.empty() ? nil : @(typedProps.markdown.c_str());

  __block CGSize size;

  void (^measureBlock)(void) = ^{
    if (view && [view hasRenderedMarkdown:currentMarkdown]) {
      size = [view measureSize:maxWidth];
    } else {
      EnrichedMarkdown *mockView = setupMockEnrichedMarkdown_(maxWidth);
      size = [mockView measureSize:maxWidth];
    }
  };

  if ([NSThread isMainThread]) {
    measureBlock();
  } else {
    dispatch_sync(dispatch_get_main_queue(), measureBlock);
  }

  if (!typedProps.markdown.empty()) {
    auto cacheKey = buildMeasurementCacheKey(typedProps, maxWidth, fontScale, MarkdownFlavor::GitHub);
    MeasurementCache::shared().set(cacheKey, {size.width, size.height});
  }

  Float clampedWidth = size.width;
  Float clampedHeight = size.height;
  clampedWidth = std::max(clampedWidth, layoutConstraints.minimumSize.width);
  clampedWidth = std::min(clampedWidth, layoutConstraints.maximumSize.width);
  clampedHeight = std::max(clampedHeight, layoutConstraints.minimumSize.height);
  if (std::isfinite(layoutConstraints.maximumSize.height)) {
    clampedHeight = std::min(clampedHeight, layoutConstraints.maximumSize.height);
  }
  return {clampedWidth, clampedHeight};
}

} // namespace facebook::react
