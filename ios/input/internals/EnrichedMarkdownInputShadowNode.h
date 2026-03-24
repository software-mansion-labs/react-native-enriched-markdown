#pragma once
#include "EnrichedMarkdownInputState.h"
#include <ReactNativeEnrichedMarkdown/EventEmitters.h>
#include <ReactNativeEnrichedMarkdown/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/core/LayoutConstraints.h>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedMarkdownInputComponentName[];

class EnrichedMarkdownInputShadowNode
    : public ConcreteViewShadowNode<EnrichedMarkdownInputComponentName, EnrichedMarkdownInputProps,
                                    EnrichedMarkdownInputEventEmitter, EnrichedMarkdownInputState> {
public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  EnrichedMarkdownInputShadowNode(const ShadowNodeFragment &fragment, const ShadowNodeFamily::Shared &family,
                                  ShadowNodeTraits traits);

  EnrichedMarkdownInputShadowNode(const ShadowNode &sourceShadowNode, const ShadowNodeFragment &fragment);

  void dirtyLayoutIfNeeded();

  Size measureContent(const LayoutContext &layoutContext, const LayoutConstraints &layoutConstraints) const override;

  static ShadowNodeTraits BaseTraits()
  {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

private:
  int localHeightRecalculationCounter_{0};
  id setupMockInputView_(CGFloat width) const;
};

} // namespace facebook::react
