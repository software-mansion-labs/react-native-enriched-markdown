#include "MarkdownTextShadowNode.h"

#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {

extern const char MarkdownTextComponentName[] = "EnrichedMarkdownText";

void MarkdownTextShadowNode::setMeasurementsManager(
    const std::shared_ptr<MarkdownTextMeasurementManager> &measurementsManager) {
  ensureUnsealed();
  measurementsManager_ = measurementsManager;
}

// Mark layout as dirty after state has been updated.
// Once layout is marked as dirty, `measureContent` will be called in order to
// recalculate layout.
void MarkdownTextShadowNode::dirtyLayoutIfNeeded() {
  const auto state = this->getStateData();
  const auto counter = state.getForceHeightRecalculationCounter();

  if (forceHeightRecalculationCounter_ != counter) {
    forceHeightRecalculationCounter_ = counter;
    dirtyLayout();
  }
}

Size MarkdownTextShadowNode::measureContent(const LayoutContext &layoutContext,
                                            const LayoutConstraints &layoutConstraints) const {
  return measurementsManager_->measure(getSurfaceId(), getTag(), getConcreteProps(), layoutConstraints);
}

} // namespace facebook::react
