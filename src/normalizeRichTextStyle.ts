import type { RichTextStyle } from './RichTextView';
import type { RichTextStyleInternal } from './RichTextViewNativeComponent';

const defaultH1Style: RichTextStyleInternal['h1'] = {
  fontSize: 36,
  fontFamily: 'Helvetica-Bold',
};

const defaultH2Style: RichTextStyleInternal['h2'] = {
  fontSize: 28,
  fontFamily: 'Helvetica-Bold',
};

const defaultH3Style: RichTextStyleInternal['h3'] = {
  fontSize: 24,
  fontFamily: 'Helvetica-Bold',
};

const defaultH4Style: RichTextStyleInternal['h4'] = {
  fontSize: 20,
  fontFamily: 'Helvetica-Bold',
};

export const normalizeRichTextStyle = (
  style: RichTextStyle
): RichTextStyleInternal => {
  return {
    h1: {
      ...defaultH1Style,
      ...style.h1,
    },
    h2: {
      ...defaultH2Style,
      ...style.h2,
    },
    h3: {
      ...defaultH3Style,
      ...style.h3,
    },
    h4: {
      ...defaultH4Style,
      ...style.h4,
    },
  };
};
