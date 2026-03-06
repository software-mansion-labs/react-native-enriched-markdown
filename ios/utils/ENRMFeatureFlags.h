#pragma once

// Auto-detect iosMath availability as a fallback for the podspec flag.
#if __has_include(<IosMath/IosMath.h>)
#if !defined(ENRICHED_MARKDOWN_MATH)
#define ENRICHED_MARKDOWN_MATH 1
#endif
#endif

#if !defined(ENRICHED_MARKDOWN_MATH)
#define ENRICHED_MARKDOWN_MATH 0
#endif
