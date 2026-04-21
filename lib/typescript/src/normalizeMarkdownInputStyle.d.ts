import { type ColorValue } from 'react-native';
import type { MarkdownInputStyle } from './EnrichedMarkdownInput';
interface MarkdownInputStyleInternal {
    strong: {
        color?: ColorValue;
    };
    em: {
        color?: ColorValue;
    };
    link: {
        color: ColorValue;
        underline: boolean;
    };
    spoiler: {
        color: ColorValue;
        backgroundColor: ColorValue;
    };
}
export declare const normalizeMarkdownInputStyle: (style?: MarkdownInputStyle) => MarkdownInputStyleInternal;
export {};
//# sourceMappingURL=normalizeMarkdownInputStyle.d.ts.map