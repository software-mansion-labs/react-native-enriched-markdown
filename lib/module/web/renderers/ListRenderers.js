"use strict";

import { useState, useEffect } from 'react';
import { extractNodeText } from "../utils.js";
import { listItemStyle, checkedTaskTextStyle } from "../styles.js";
import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
const NESTED_LIST_TYPES = new Set(['UnorderedList', 'OrderedList']);
function ListRenderer({
  node,
  styles,
  parentType,
  renderChildren,
  listTag: ListTag
}) {
  const isNested = parentType === 'ListItem';
  const hasTaskChild = !isNested && node.children?.some(child => child.attributes?.isTask === 'true');
  const resolvedStyle = isNested ? styles.listNested : hasTaskChild ? styles.listTask : styles.list;
  return /*#__PURE__*/_jsx(ListTag, {
    style: resolvedStyle,
    children: renderChildren(node)
  });
}
function UnorderedListRenderer(props) {
  return /*#__PURE__*/_jsx(ListRenderer, {
    ...props,
    listTag: "ul"
  });
}
function OrderedListRenderer(props) {
  return /*#__PURE__*/_jsx(ListRenderer, {
    ...props,
    listTag: "ol"
  });
}
function isNestedList(child) {
  return NESTED_LIST_TYPES.has(child.type);
}
function ListItemRenderer({
  node,
  style,
  styles,
  callbacks,
  renderChildren
}) {
  const isTask = node.attributes?.isTask === 'true';
  const initialChecked = node.attributes?.taskChecked === 'true';
  const taskText = isTask ? extractNodeText(node) : '';
  const [isChecked, setIsChecked] = useState(initialChecked);
  useEffect(() => {
    setIsChecked(initialChecked);
  }, [initialChecked]);
  const handleChange = () => {
    const taskIndex = node.attributes?.taskIndex;
    if (taskIndex === undefined) return;
    const newChecked = !isChecked;
    setIsChecked(newChecked);
    callbacks.onTaskListItemPress?.({
      index: taskIndex,
      checked: newChecked,
      text: taskText
    });
  };
  const hasNestedList = node.children?.some(isNestedList);
  const checkedStyle = isTask && isChecked ? checkedTaskTextStyle(style) : undefined;
  const inlineNode = hasNestedList ? {
    ...node,
    children: node.children?.filter(child => !isNestedList(child))
  } : node;
  const nestedNode = hasNestedList ? {
    ...node,
    children: node.children?.filter(isNestedList)
  } : null;
  return /*#__PURE__*/_jsxs("li", {
    style: listItemStyle(isTask),
    children: [/*#__PURE__*/_jsxs("span", {
      style: checkedStyle,
      children: [isTask && /*#__PURE__*/_jsx("input", {
        type: "checkbox",
        checked: isChecked,
        onChange: handleChange,
        style: styles.taskCheckbox,
        "aria-label": `Task: ${taskText}`
      }), renderChildren(inlineNode)]
    }), nestedNode && renderChildren(nestedNode)]
  });
}
export const listRenderers = {
  UnorderedList: UnorderedListRenderer,
  OrderedList: OrderedListRenderer,
  ListItem: ListItemRenderer
};
//# sourceMappingURL=ListRenderers.js.map