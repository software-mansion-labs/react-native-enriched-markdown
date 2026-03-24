#pragma once

#include "MarkdownContainerMeasurementManager.h"
#include "MarkdownContainerShadowNode.h"
#include "MarkdownInputMeasurementManager.h"
#include "MarkdownInputShadowNode.h"
#include "MarkdownTextMeasurementManager.h"
#include "MarkdownTextShadowNode.h"

#include <react/renderer/componentregistry/ComponentDescriptorProviderRegistry.h>
#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

class EnrichedMarkdownComponentDescriptor final : public ConcreteComponentDescriptor<MarkdownContainerShadowNode> {
public:
  EnrichedMarkdownComponentDescriptor(const ComponentDescriptorParameters &parameters)
      : ConcreteComponentDescriptor(parameters),
        measurementsManager_(std::make_shared<MarkdownContainerMeasurementManager>(contextContainer_)) {}

  void adopt(ShadowNode &shadowNode) const override {
    ConcreteComponentDescriptor::adopt(shadowNode);
    auto &containerShadowNode = static_cast<MarkdownContainerShadowNode &>(shadowNode);
    containerShadowNode.setMeasurementsManager(measurementsManager_);
  }

private:
  const std::shared_ptr<MarkdownContainerMeasurementManager> measurementsManager_;
};

class EnrichedMarkdownTextComponentDescriptor final : public ConcreteComponentDescriptor<MarkdownTextShadowNode> {
public:
  EnrichedMarkdownTextComponentDescriptor(const ComponentDescriptorParameters &parameters)
      : ConcreteComponentDescriptor(parameters),
        measurementsManager_(std::make_shared<MarkdownTextMeasurementManager>(contextContainer_)) {}

  void adopt(ShadowNode &shadowNode) const override {
    ConcreteComponentDescriptor::adopt(shadowNode);
    auto &markdownTextShadowNode = static_cast<MarkdownTextShadowNode &>(shadowNode);
    markdownTextShadowNode.setMeasurementsManager(measurementsManager_);
  }

private:
  const std::shared_ptr<MarkdownTextMeasurementManager> measurementsManager_;
};

class EnrichedMarkdownInputComponentDescriptor final : public ConcreteComponentDescriptor<MarkdownInputShadowNode> {
public:
  EnrichedMarkdownInputComponentDescriptor(const ComponentDescriptorParameters &parameters)
      : ConcreteComponentDescriptor(parameters),
        measurementsManager_(std::make_shared<MarkdownInputMeasurementManager>(contextContainer_)) {}

  void adopt(ShadowNode &shadowNode) const override {
    ConcreteComponentDescriptor::adopt(shadowNode);
    auto &inputShadowNode = static_cast<MarkdownInputShadowNode &>(shadowNode);
    inputShadowNode.setMeasurementsManager(measurementsManager_);
  }

private:
  const std::shared_ptr<MarkdownInputMeasurementManager> measurementsManager_;
};

void EnrichedMarkdownTextSpec_registerComponentDescriptorsFromCodegen(
    std::shared_ptr<const ComponentDescriptorProviderRegistry> registry);

} // namespace facebook::react
