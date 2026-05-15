package com.swmansion.enriched.markdown.utils.common

import android.content.Context
import android.os.Build
import android.view.accessibility.AccessibilityManager

/**
 * Returns true when the user has asked the system to minimise motion.
 *
 * On API 26+ this maps to [AccessibilityManager.isAnimatorEnabled], which is the
 * platform signal for "Remove animations" (Settings > Accessibility) and the
 * "Animator duration scale" developer toggle. Older API levels do not expose an
 * equivalent flag, so we fall back to allowing animations.
 */
fun isReducedMotionEnabled(context: Context): Boolean {
  if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
  val am =
    context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
      ?: return false
  return !am.isAnimatorEnabled
}
