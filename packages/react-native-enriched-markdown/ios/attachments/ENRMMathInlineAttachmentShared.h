#pragma once
#import "ENRMFeatureFlags.h"
#import "ENRMMathInlineAttachment.h"

#if ENRICHED_MARKDOWN_MATH

@class ENRMRaTeXRenderResult;

@interface ENRMMathInlineAttachment () {
  CGSize _cachedSize;
  CGFloat _mathAscent;
  CGFloat _mathDescent;
  ENRMRaTeXRenderResult *_renderResult;
  // Visible-source fallback when RaTeX cannot parse the span; see ENRMMathFallback.h.
  NSAttributedString *_fallbackSource;
  // Guards onLatexError so a failing span reports once, not on every redraw.
  BOOL _didReportError;
  // Set when RaTeX rejects this span. Recorded independently of onLatexError
  // because prepareIfNeeded can run (during measurement) before the reporter is
  // wired; the host view drains it via reportLatexErrorIfNeeded.
  BOOL _parseFailed;
  NSString *_parseMessage;
}
@end

#endif
