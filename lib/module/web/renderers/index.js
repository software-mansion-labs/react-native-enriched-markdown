"use strict";

import { blockRenderers } from "./BlockRenderers.js";
import { inlineRenderers } from "./InlineRenderers.js";
import { listRenderers } from "./ListRenderers.js";
import { tableRenderers } from "./TableRenderers.js";
import { jsx as _jsx } from "react/jsx-runtime";
function nodeKey(node, index) {
  if (node.type === 'ListItem' && node.attributes?.isTask === 'true') {
    const taskId = node.attributes.taskIndex ?? index;
    return `task-${taskId}-${node.attributes.taskChecked}`;
  }
  return index;
}
const RENDERERS = {
  ...blockRenderers,
  ...inlineRenderers,
  ...listRenderers,
  ...tableRenderers
};
export function RenderNode({
  node,
  style,
  styles,
  callbacks,
  capabilities,
  parentType
}) {
  const Renderer = RENDERERS[node.type];
  if (!Renderer) return null;
  const renderChildren = childNode => childNode.children?.map((child, index) => /*#__PURE__*/_jsx(RenderNode, {
    node: child,
    style: style,
    styles: styles,
    callbacks: callbacks,
    capabilities: capabilities,
    parentType: childNode.type
  }, nodeKey(child, index))) ?? null;
  return /*#__PURE__*/_jsx(Renderer, {
    node: node,
    style: style,
    styles: styles,
    parentType: parentType,
    callbacks: callbacks,
    capabilities: capabilities,
    renderChildren: renderChildren
  });
}
//# sourceMappingURL=index.js.map