#pragma once

// ──────────────────────────────────────────────
// Math (iosMath)
// ──────────────────────────────────────────────
// The podspec sets ENRICHED_MARKDOWN_MATH=1 when math is enabled; this header
// also enables it when iosMath headers are found, as a safety net.
#if __has_include(<IosMath/IosMath.h>)
#if !defined(ENRICHED_MARKDOWN_MATH)
#define ENRICHED_MARKDOWN_MATH 1
#endif
#endif

#if !defined(ENRICHED_MARKDOWN_MATH)
#define ENRICHED_MARKDOWN_MATH 0
#endif
