package com.swmansion.enriched.markdown.utils.common

import com.swmansion.enriched.markdown.BuildConfig

object FeatureFlags {
  const val isMathEnabled: Boolean = BuildConfig.ENABLE_MATH
}
