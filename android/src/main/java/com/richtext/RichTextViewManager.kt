package com.richtext

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.RichTextViewManagerInterface
import com.facebook.react.viewmanagers.RichTextViewManagerDelegate

@ReactModule(name = RichTextViewManager.NAME)
class RichTextViewManager : SimpleViewManager<RichTextView>(),
  RichTextViewManagerInterface<RichTextView> {
  private val mDelegate: ViewManagerDelegate<RichTextView>

  init {
    mDelegate = RichTextViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<RichTextView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): RichTextView {
    return RichTextView(context)
  }

  @ReactProp(name = "color")
  override fun setColor(view: RichTextView?, color: String?) {
    view?.setBackgroundColor(Color.parseColor(color))
  }

  companion object {
    const val NAME = "RichTextView"
  }
}
