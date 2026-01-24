import { useState, useEffect, useMemo, useCallback } from 'react';
import EnrichedMarkdownTextNativeComponent, {
  type NativeProps,
  type LinkPressEvent,
} from './EnrichedMarkdownTextNativeComponent';
import { normalizeMarkdownStyle } from './normalizeMarkdownStyle';
import type { ViewStyle, TextStyle, NativeSyntheticEvent } from 'react-native';
import type { MarkdownSession } from './MarkdownSession';
import type { MarkdownStyle } from './EnrichedMarkdownText';

export interface EnrichedMarkdownTextStreamProps
  extends Omit<
    NativeProps,
    'markdown' | 'markdownStyle' | 'style' | 'onLinkPress'
  > {
  /**
   * The active MarkdownSession to stream content from.
   */
  session: MarkdownSession;
  /**
   * Style configuration for markdown elements
   */
  markdownStyle?: MarkdownStyle;
  /**
   * Style for the container view.
   */
  containerStyle?: ViewStyle | TextStyle;
  /**
   * Callback fired when a link is pressed.
   * Receives the link URL directly.
   */
  onLinkPress?: (event: LinkPressEvent) => void;
}

/**
 * A component that renders streaming Markdown from a MarkdownSession.
 * It efficiently subscribes to session updates to minimize parent re-renders.
 *
 * @example
 * ```tsx
 * const { session } = useMarkdownSession();
 *
 * useEffect(() => {
 *   session.append("Hello ");
 *   session.append("**world**");
 * }, []);
 *
 * return <EnrichedMarkdownTextStream session={session} />;
 * ```
 */
export const EnrichedMarkdownTextStream = ({
  session,
  markdownStyle = {},
  containerStyle,
  onLinkPress,
  isSelectable = true,
  ...rest
}: EnrichedMarkdownTextStreamProps) => {
  const [text, setText] = useState(() => session.getAllText());

  useEffect(() => {
    // Ensure initial state is synced
    const initialText = session.getAllText();
    setText(initialText);

    const unsubscribe = session.addListener(() => {
      // Get fresh text from session on each update
      const currentText = session.getAllText();
      setText(currentText);
    });

    return unsubscribe;
  }, [session]);

  const normalizedStyle = useMemo(
    () => normalizeMarkdownStyle(markdownStyle),
    [markdownStyle]
  );

  const handleLinkPress = useCallback(
    (e: NativeSyntheticEvent<LinkPressEvent>) => {
      const { url } = e.nativeEvent;
      onLinkPress?.({ url });
    },
    [onLinkPress]
  );

  return (
    <EnrichedMarkdownTextNativeComponent
      markdown={text}
      markdownStyle={normalizedStyle}
      onLinkPress={handleLinkPress}
      isSelectable={isSelectable}
      style={containerStyle}
      {...rest}
    />
  );
};
