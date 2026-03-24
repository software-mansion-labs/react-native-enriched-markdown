#pragma once

#include "MarkdownInputMeasurementManager.h"
#include "MarkdownInputState.h"

#include <react/renderer/components/EnrichedMarkdownTextSpec/EventEmitters.h>
#include <react/renderer/components/EnrichedMarkdownTextSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

namespace facebook::react {

JSI_EXPORT extern const char MarkdownInputComponentName[];

class MarkdownInputShadowNode final
    : public ConcreteViewShadowNode<MarkdownInputComponentName, EnrichedMarkdownInputProps,
                                    EnrichedMarkdownInputEventEmitter, MarkdownInputState> {
public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  MarkdownInputShadowNode(ShadowNode const &sourceShadowNode, ShadowNodeFragment const &fragment)
      : ConcreteViewShadowNode(sourceShadowNode, fragment) {
    dirtyLayoutIfNeeded();
  }

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

  void setMeasurementsManager(const std::shared_ptr<MarkdownInputMeasurementManager> &measurementsManager);

  void dirtyLayoutIfNeeded();

  Size measureContent(const LayoutContext &layoutContext, const LayoutConstraints &layoutConstraints) const override;

private:
  int forceHeightRecalculationCounter_{0};
  std::shared_ptr<MarkdownInputMeasurementManager> measurementsManager_;
};

} // namespace facebook::react
