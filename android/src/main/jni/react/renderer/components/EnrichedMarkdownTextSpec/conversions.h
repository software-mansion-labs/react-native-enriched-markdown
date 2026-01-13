#pragma once

#include <folly/dynamic.h>
#include <react/renderer/components/EnrichedMarkdownTextSpec/Props.h>
#include <react/renderer/core/propsConversions.h>

namespace facebook::react {

#ifdef RN_SERIALIZABLE_STATE
inline folly::dynamic toDynamic(const EnrichedMarkdownTextProps &props) {
  // Serialize measurement-affecting props
  folly::dynamic serializedProps = folly::dynamic::object();
  serializedProps["markdown"] = props.markdown;
  serializedProps["markdownStyle"] = toDynamic(props.markdownStyle);
  return serializedProps;
}
#endif

} // namespace facebook::react
