#import "EnrichedMarkdownTextShadowNode.h"
#import "EnrichedMarkdownText.h"
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>

namespace facebook::react {

extern const char EnrichedMarkdownTextComponentName[] = "EnrichedMarkdownText";

EnrichedMarkdownTextShadowNode::EnrichedMarkdownTextShadowNode(const ShadowNodeFragment &fragment,
                                                               const ShadowNodeFamily::Shared &family,
                                                               ShadowNodeTraits traits)
    : ConcreteViewShadowNode(fragment, family, traits)
{
}

EnrichedMarkdownTextShadowNode::EnrichedMarkdownTextShadowNode(const ShadowNode &sourceShadowNode,
                                                               const ShadowNodeFragment &fragment)
    : ConcreteViewShadowNode(sourceShadowNode, fragment)
{
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
  CGFloat fontScale = typedProps.allowFontScaling ? RCTFontSizeMultiplier() : 1.0;

  if (!typedProps.markdown.empty()) {
    auto cacheKey = buildMeasurementCacheKey(typedProps, maxWidth, fontScale, MarkdownFlavor::CommonMark);
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
  EnrichedMarkdownText *view = weakWrapper ? (EnrichedMarkdownText *)weakWrapper.object : nil;

  NSString *currentMarkdown = typedProps.markdown.empty() ? nil : @(typedProps.markdown.c_str());

  __block CGSize size;

  void (^measureBlock)(void) = ^{
    if (view && [view hasRenderedMarkdown:currentMarkdown]) {
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

  if (!typedProps.markdown.empty()) {
    auto cacheKey = buildMeasurementCacheKey(typedProps, maxWidth, fontScale, MarkdownFlavor::CommonMark);
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
