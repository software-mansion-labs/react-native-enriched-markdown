import type { MarkdownStyle, Md4cFlags } from '../types/MarkdownStyle';
import type { EnrichedMarkdownTextProps, ContextMenuItem } from '../types/MarkdownTextProps';
import type { LinkPressEvent, LinkLongPressEvent, TaskListItemPressEvent, MentionPressEvent, CitationPressEvent } from '../types/events';
export type { MarkdownStyle, Md4cFlags };
export type { EnrichedMarkdownTextProps, ContextMenuItem };
export type { LinkPressEvent, LinkLongPressEvent, TaskListItemPressEvent, MentionPressEvent, CitationPressEvent, };
export declare const EnrichedMarkdownText: ({ markdown, markdownStyle, containerStyle, onLinkPress, onLinkLongPress, onTaskListItemPress, onMentionPress, onCitationPress, enableLinkPreview, selectable, md4cFlags, allowFontScaling, maxFontSizeMultiplier, allowTrailingMargin, flavor, streamingAnimation, spoilerOverlay, contextMenuItems, selectionColor, selectionHandleColor, ...rest }: EnrichedMarkdownTextProps) => import("react/jsx-runtime").JSX.Element;
export default EnrichedMarkdownText;
//# sourceMappingURL=EnrichedMarkdownText.d.ts.map