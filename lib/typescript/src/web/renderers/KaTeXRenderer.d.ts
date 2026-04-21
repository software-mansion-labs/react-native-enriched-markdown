import { type CSSProperties } from 'react';
import type { KaTeXInstance } from '../katex';
interface KaTeXRendererProps {
    content: string;
    katex: KaTeXInstance | null;
    displayMode: boolean;
    style: CSSProperties;
    fallbackTag: 'code' | 'pre';
}
export declare function KaTeXRenderer({ content, katex, displayMode, style, fallbackTag: FallbackTag, }: KaTeXRendererProps): import("react/jsx-runtime").JSX.Element;
export {};
//# sourceMappingURL=KaTeXRenderer.d.ts.map