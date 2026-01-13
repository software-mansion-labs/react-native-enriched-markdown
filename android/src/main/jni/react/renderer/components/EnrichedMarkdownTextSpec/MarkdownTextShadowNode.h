#pragma once

#include "MarkdownTextMeasurementManager.h"
#include "MarkdownTextState.h"

#include <react/renderer/components/EnrichedMarkdownTextSpec/EventEmitters.h>
#include <react/renderer/components/EnrichedMarkdownTextSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

namespace facebook::react {

JSI_EXPORT extern const char MarkdownTextComponentName[];

/*
 * `ShadowNode` for <EnrichedMarkdownText> component.
 */
class MarkdownTextShadowNode final
    : public ConcreteViewShadowNode<MarkdownTextComponentName, EnrichedMarkdownTextProps,
                                    EnrichedMarkdownTextEventEmitter, MarkdownTextState> {
public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  // This constructor is called when we "update" shadow node, e.g. after
  // updating shadow node's state
  MarkdownTextShadowNode(ShadowNode const &sourceShadowNode, ShadowNodeFragment const &fragment)
      : ConcreteViewShadowNode(sourceShadowNode, fragment) {
    dirtyLayoutIfNeeded();
  }

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

  // Associates a shared `MarkdownTextMeasurementManager` with the node.
  void setMeasurementsManager(const std::shared_ptr<MarkdownTextMeasurementManager> &measurementsManager);

  void dirtyLayoutIfNeeded();

  Size measureContent(const LayoutContext &layoutContext, const LayoutConstraints &layoutConstraints) const override;

private:
  int forceHeightRecalculationCounter_;
  std::shared_ptr<MarkdownTextMeasurementManager> measurementsManager_;
};

} // namespace facebook::react
