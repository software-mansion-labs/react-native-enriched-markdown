package com.swmansion.enriched.markdown

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager
import com.swmansion.enriched.markdown.session.EnrichedMarkdownSessionModule
import java.util.ArrayList

class EnrichedMarkdownTextPackage : ReactPackage {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    val viewManagers: MutableList<ViewManager<*, *>> = ArrayList()
    viewManagers.add(EnrichedMarkdownTextManager())
    return viewManagers
  }

  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> =
    listOf(EnrichedMarkdownSessionModule(reactContext))
}
