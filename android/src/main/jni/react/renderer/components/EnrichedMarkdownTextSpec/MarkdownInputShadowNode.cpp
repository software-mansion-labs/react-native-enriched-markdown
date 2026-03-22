#include "MarkdownInputShadowNode.h"

#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {

extern const char MarkdownInputComponentName[] = "EnrichedMarkdownInput";

void MarkdownInputShadowNode::setMeasurementsManager(
    const std::shared_ptr<MarkdownInputMeasurementManager> &measurementsManager) {
  ensureUnsealed();
  measurementsManager_ = measurementsManager;
}

void MarkdownInputShadowNode::dirtyLayoutIfNeeded() {
  const auto state = this->getStateData();
  const auto counter = state.getForceHeightRecalculationCounter();

  if (forceHeightRecalculationCounter_ != counter) {
    forceHeightRecalculationCounter_ = counter;
    dirtyLayout();
  }
}

Size MarkdownInputShadowNode::measureContent(const LayoutContext &layoutContext,
                                             const LayoutConstraints &layoutConstraints) const {
  return measurementsManager_->measure(getSurfaceId(), getTag(), getConcreteProps(), layoutConstraints);
}

} // namespace facebook::react
