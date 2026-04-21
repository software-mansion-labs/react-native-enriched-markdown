"use strict";

/** Recursively collects plain text content from an AST node's subtree. */
export function extractNodeText(node) {
  if (node.content !== undefined) return node.content;
  return node.children?.map(extractNodeText).join('') ?? '';
}

/** Extracts the filename from a URL path, without extension. */
export function filenameFromUrl(url) {
  try {
    const pathname = new URL(url, 'https://placeholder').pathname;
    const filename = pathname.split('/').pop() ?? '';
    return filename.replace(/\.[^.]+$/, '');
  } catch {
    return '';
  }
}

/**
 * Stamps each task ListItem with a sequential `taskIndex` matching the order
 * native C++ assigns — so onTaskListItemPress.index is correct on web too.
 * Mutates the AST in-place (safe: called once on the freshly-parsed result).
 */
export function indexTaskItems(node, counter = {
  value: 0
}) {
  if (node.type === 'ListItem' && node.attributes?.isTask === 'true') {
    node.attributes.taskIndex = counter.value++;
  }
  node.children?.forEach(child => indexTaskItems(child, counter));
}

/**
 * Stamps Image nodes with `isInline` when they appear inside a paragraph
 * that also contains other content (text, links, etc.).
 * Matches native behavior: sole-child images are block-level, mixed are inline.
 * Mutates the AST in-place (safe: called once on the freshly-parsed result).
 */
export function markInlineImages(node) {
  if (node.type === 'Paragraph' && node.children) {
    const hasNonImageChild = node.children.some(child => child.type !== 'Image');
    if (hasNonImageChild) {
      for (const child of node.children) {
        if (child.type === 'Image') {
          child.attributes = {
            ...child.attributes,
            isInline: true
          };
        }
      }
    }
  }
  node.children?.forEach(markInlineImages);
}
//# sourceMappingURL=utils.js.map