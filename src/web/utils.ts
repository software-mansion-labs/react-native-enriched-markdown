import type { ASTNode } from './types';

/** Recursively collects plain text content from an AST node's subtree. */
export function extractNodeText(node: ASTNode): string {
  if (node.content !== undefined) return node.content;
  return node.children?.map(extractNodeText).join('') ?? '';
}

/**
 * Stamps each task ListItem with a sequential `taskIndex` matching the order
 * native C++ assigns — so onTaskListItemPress.index is correct on web too.
 * Mutates the AST in-place (safe: called once on the freshly-parsed result).
 */
export function indexTaskItems(node: ASTNode, counter = { value: 0 }): void {
  if (node.type === 'ListItem' && node.attributes?.isTask === 'true') {
    node.attributes.taskIndex = counter.value++;
  }
  node.children?.forEach((child) => indexTaskItems(child, counter));
}
