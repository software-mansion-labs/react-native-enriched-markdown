import type { ReactNode } from 'react';
import type {
  ASTNode,
  NodeType,
  RendererCallbacks,
  RendererMap,
} from '../types';
import type { MarkdownStyleInternal } from '../../types/MarkdownStyleInternal';
import { blockRenderers } from './BlockRenderers';
import { inlineRenderers } from './InlineRenderers';
import { listRenderers } from './ListRenderers';
import { tableRenderers } from './TableRenderers';

const RENDERERS: RendererMap = {
  ...blockRenderers,
  ...inlineRenderers,
  ...listRenderers,
  ...tableRenderers,
};

export function renderNode(
  node: ASTNode,
  style: MarkdownStyleInternal,
  callbacks: RendererCallbacks,
  key: number = 0,
  parentType?: NodeType
): ReactNode {
  const Renderer = RENDERERS[node.type];
  if (!Renderer) return null;

  const renderChildren = (childNode: ASTNode): ReactNode =>
    childNode.children?.map((child, index) =>
      renderNode(child, style, callbacks, index, childNode.type)
    );

  return (
    <Renderer
      key={key}
      node={node}
      style={style}
      parentType={parentType}
      callbacks={callbacks}
      renderChildren={renderChildren}
    />
  );
}
