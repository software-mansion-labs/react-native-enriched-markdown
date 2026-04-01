import { useState } from 'react';
import { extractNodeText } from '../utils';
import type { RendererProps, RendererMap } from '../types';
import { listCSS, listItemCSS, taskCheckboxCSS } from '../cssMap';

function ListRenderer({
  node,
  style,
  parentType,
  renderChildren,
  tag: Tag,
}: RendererProps & { tag: 'ul' | 'ol' }) {
  const isNested = parentType === 'ListItem';
  const isTopLevelTaskList =
    !isNested && node.children?.[0]?.attributes?.isTask === 'true';
  const css = isNested
    ? { ...listCSS(style), marginBottom: 0 }
    : listCSS(style, isTopLevelTaskList);
  return <Tag style={css}>{renderChildren(node)}</Tag>;
}

function UnorderedListRenderer(props: RendererProps) {
  return <ListRenderer {...props} tag="ul" />;
}

function OrderedListRenderer(props: RendererProps) {
  return <ListRenderer {...props} tag="ol" />;
}

function ListItemRenderer({
  node,
  style,
  callbacks,
  renderChildren,
}: RendererProps) {
  const isTask = node.attributes?.isTask === 'true';
  const initialChecked = node.attributes?.taskChecked === 'true';

  const [isChecked, setIsChecked] = useState(initialChecked);

  const handleChange = () => {
    const newChecked = !isChecked;
    setIsChecked(newChecked);
    callbacks.onTaskListItemPress?.({
      index: node.attributes?.taskIndex ?? 0,
      checked: newChecked,
      text: extractNodeText(node),
    });
  };

  return (
    <li style={listItemCSS(style, isTask, isTask && isChecked)}>
      {isTask && (
        <input
          type="checkbox"
          checked={isChecked}
          onChange={handleChange}
          style={taskCheckboxCSS(style)}
        />
      )}
      {renderChildren(node)}
    </li>
  );
}

export const listRenderers: RendererMap = {
  UnorderedList: UnorderedListRenderer,
  OrderedList: OrderedListRenderer,
  ListItem: ListItemRenderer,
};
