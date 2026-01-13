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
  CGFloat maxHeight = layoutConstraints.maximumSize.height;

  RCTInternalGenericWeakWrapper *weakWrapper =
      (RCTInternalGenericWeakWrapper *)unwrapManagedObject(getStateData().getComponentViewRef());
  EnrichedMarkdownText *view = weakWrapper ? (EnrichedMarkdownText *)weakWrapper.object : nil;

  __block CGSize size;

  // Measure on main thread (required for UIKit)
  void (^measureBlock)(void) = ^{
    if (view) {
      size = [view measureSize:maxWidth];
    } else {
      // No view yet - create mock view for accurate initial measurement
      EnrichedMarkdownText *mockView = setupMockEnrichedMarkdownText_(maxWidth);
      size = [mockView measureSize:maxWidth];
    }
  };

  if ([NSThread isMainThread]) {
    measureBlock();
  } else {
    dispatch_sync(dispatch_get_main_queue(), measureBlock);
  }

  return {size.width, MIN(size.height, maxHeight)};
}

} // namespace facebook::react
