#import "EnrichedMarkdownInputShadowNode.h"
#import "EnrichedMarkdownInput.h"
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>

namespace facebook::react {

extern const char EnrichedMarkdownInputComponentName[] = "EnrichedMarkdownInput";

EnrichedMarkdownInputShadowNode::EnrichedMarkdownInputShadowNode(const ShadowNodeFragment &fragment,
                                                                 const ShadowNodeFamily::Shared &family,
                                                                 ShadowNodeTraits traits)
    : ConcreteViewShadowNode(fragment, family, traits)
{
}

EnrichedMarkdownInputShadowNode::EnrichedMarkdownInputShadowNode(const ShadowNode &sourceShadowNode,
                                                                 const ShadowNodeFragment &fragment)
    : ConcreteViewShadowNode(sourceShadowNode, fragment)
{
  dirtyLayoutIfNeeded();
}

void EnrichedMarkdownInputShadowNode::dirtyLayoutIfNeeded()
{
  const auto state = this->getStateData();
  const int receivedCounter = state.getHeightRecalculationCounter();

  if (receivedCounter > localHeightRecalculationCounter_) {
    localHeightRecalculationCounter_ = receivedCounter;
    YGNodeMarkDirty(&yogaNode_);
  }
}

id EnrichedMarkdownInputShadowNode::setupMockInputView_(CGFloat width) const
{
  EnrichedMarkdownInput *mockView = [[EnrichedMarkdownInput alloc] initWithFrame:CGRectMake(20000, 20000, width, 1000)];

  mockView.blockEmitting = YES;

  const auto props = this->getProps();
  [mockView updateProps:props oldProps:nullptr];

  return mockView;
}

Size EnrichedMarkdownInputShadowNode::measureContent(const LayoutContext &layoutContext,
                                                     const LayoutConstraints &layoutConstraints) const
{
  CGFloat maxWidth = layoutConstraints.maximumSize.width;

  RCTInternalGenericWeakWrapper *weakWrapper =
      (RCTInternalGenericWeakWrapper *)unwrapManagedObject(getStateData().getComponentViewRef());
  EnrichedMarkdownInput *view = weakWrapper ? (EnrichedMarkdownInput *)weakWrapper.object : nil;

  __block CGSize size;

  void (^measureBlock)(void) = ^{
    if (view) {
      size = [view measureSize:maxWidth];
    } else {
      EnrichedMarkdownInput *mockView = setupMockInputView_(maxWidth);
      size = [mockView measureSize:maxWidth];
    }
  };

  if ([NSThread isMainThread]) {
    measureBlock();
  } else {
    dispatch_sync(dispatch_get_main_queue(), measureBlock);
  }

  Float clampedWidth = std::max((Float)size.width, layoutConstraints.minimumSize.width);
  clampedWidth = std::min(clampedWidth, layoutConstraints.maximumSize.width);
  Float clampedHeight = std::max((Float)size.height, layoutConstraints.minimumSize.height);
  if (std::isfinite(layoutConstraints.maximumSize.height)) {
    clampedHeight = std::min(clampedHeight, layoutConstraints.maximumSize.height);
  }
  return {clampedWidth, clampedHeight};
}

} // namespace facebook::react
