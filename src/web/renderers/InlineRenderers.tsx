import type { MouseEvent } from 'react';
import type { RendererProps, RendererMap } from '../types';
import { extractNodeText } from '../utils';
import { KaTeXRenderer } from './KaTeXRenderer';

const MENTION_SCHEME = 'mention://';
const CITATION_SCHEME = 'citation://';
const MENTION_CLASS = 'enriched-mention';

// The `:active` rule honors the consumer-configured `pressedOpacity` via a CSS
// variable the mention span sets inline. Rendered as a `<style>` element so we
// don't need DOM globals at type-check time.
const MENTION_PRESSED_STYLE_RULE = `.${MENTION_CLASS}:active { opacity: var(--enriched-mention-pressed-opacity, 0.6); }`;

function TextRenderer({ node }: RendererProps) {
  return <>{node.content ?? ''}</>;
}

function LineBreakRenderer(_props: RendererProps) {
  return <br />;
}

function StrongRenderer({ node, styles, renderChildren }: RendererProps) {
  return <strong style={styles.strong}>{renderChildren(node)}</strong>;
}

function EmphasisRenderer({ node, styles, renderChildren }: RendererProps) {
  return <em style={styles.emphasis}>{renderChildren(node)}</em>;
}

function StrikethroughRenderer({
  node,
  styles,
  renderChildren,
}: RendererProps) {
  return <s style={styles.strikethrough}>{renderChildren(node)}</s>;
}

function UnderlineRenderer({ node, styles, renderChildren }: RendererProps) {
  return <u style={styles.underline}>{renderChildren(node)}</u>;
}

function CodeRenderer({ node, styles, renderChildren }: RendererProps) {
  return (
    <code style={styles.code}>{node.content ?? renderChildren(node)}</code>
  );
}

function LinkRenderer(props: RendererProps) {
  const url = props.node.attributes?.url;

  if (!url) return <>{props.renderChildren(props.node)}</>;

  if (url.startsWith(MENTION_SCHEME)) {
    return <MentionRenderer {...props} url={url} />;
  }

  if (url.startsWith(CITATION_SCHEME)) {
    return <CitationRenderer {...props} url={url} />;
  }

  return <StandardLinkRenderer {...props} url={url} />;
}

interface SchemeRendererProps extends RendererProps {
  url: string;
}

function StandardLinkRenderer({
  url,
  styles,
  callbacks,
  node,
  renderChildren,
}: SchemeRendererProps) {
  const handleClick = (event: MouseEvent) => {
    if (callbacks.onLinkPress) {
      event.preventDefault();
      callbacks.onLinkPress({ url });
    }
  };

  const handleContextMenu = (event: MouseEvent) => {
    if (callbacks.onLinkLongPress) {
      event.preventDefault();
      callbacks.onLinkLongPress({ url });
    }
  };

  return (
    <a
      href={url}
      style={styles.link}
      target="_blank"
      rel="noopener noreferrer"
      onClick={handleClick}
      onContextMenu={handleContextMenu}
    >
      {renderChildren(node)}
    </a>
  );
}

function MentionRenderer({
  url,
  styles,
  callbacks,
  node,
}: SchemeRendererProps) {
  const userId = url.slice(MENTION_SCHEME.length);
  const displayText = extractNodeText(node);

  const handleClick = (event: MouseEvent) => {
    event.preventDefault();
    callbacks.onMentionPress?.({ userId, text: displayText });
  };

  const style = {
    ...styles.mention,
    ['--enriched-mention-pressed-opacity' as never]:
      styles.mentionPressedOpacity,
  };

  return (
    <>
      <style>{MENTION_PRESSED_STYLE_RULE}</style>
      <span
        className={MENTION_CLASS}
        role="button"
        tabIndex={0}
        aria-label={`Mention: ${displayText}`}
        data-user-id={userId}
        onClick={handleClick}
        style={style}
      >
        {displayText}
      </span>
    </>
  );
}

function CitationRenderer({
  url,
  styles,
  callbacks,
  node,
  renderChildren,
}: SchemeRendererProps) {
  const targetUrl = url.slice(CITATION_SCHEME.length);
  const displayText = extractNodeText(node);

  const handleClick = (event: MouseEvent) => {
    event.preventDefault();
    callbacks.onCitationPress?.({ url: targetUrl, text: displayText });
  };

  return (
    <sup
      style={styles.citation}
      aria-label={`Citation: ${displayText}`}
      data-citation-url={targetUrl}
      onClick={handleClick}
    >
      {renderChildren(node)}
    </sup>
  );
}

function LatexMathInlineRenderer({
  node,
  styles,
  capabilities,
}: RendererProps) {
  const content = extractNodeText(node);

  return (
    <KaTeXRenderer
      content={content}
      katex={capabilities.katex}
      displayMode={false}
      style={styles.mathInline}
      fallbackTag="code"
    />
  );
}

export const inlineRenderers: RendererMap = {
  Text: TextRenderer,
  LineBreak: LineBreakRenderer,
  Strong: StrongRenderer,
  Emphasis: EmphasisRenderer,
  Strikethrough: StrikethroughRenderer,
  Underline: UnderlineRenderer,
  Code: CodeRenderer,
  Link: LinkRenderer,
  LatexMathInline: LatexMathInlineRenderer,
};
