package com.swmansion.enriched.markdown.session

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule

class EnrichedMarkdownSessionModule(
  reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
  private val sessions = mutableMapOf<String, MarkdownSession>()
  private val sessionListeners = mutableMapOf<String, MutableMap<String, () -> Unit>>()
  private val lock = Any()

  override fun getName(): String = "EnrichedMarkdownSessionModule"

  @ReactMethod
  fun createSession(promise: Promise) {
    synchronized(lock) {
      val sessionId =
        java.util.UUID
          .randomUUID()
          .toString()
      val session = MarkdownSession()
      sessions[sessionId] = session
      sessionListeners[sessionId] = mutableMapOf()
      promise.resolve(sessionId)
    }
  }

  @ReactMethod
  fun append(
    sessionId: String,
    chunk: String,
    promise: Promise,
  ) {
    synchronized(lock) {
      val session = sessions[sessionId]
      if (session == null) {
        promise.reject("SESSION_NOT_FOUND", "Session not found")
        return
      }
      // session.append() already calls notifyListeners() internally
      session.append(chunk)
      promise.resolve(null)
    }
  }

  @ReactMethod
  fun clear(
    sessionId: String,
    promise: Promise,
  ) {
    synchronized(lock) {
      val session = sessions[sessionId]
      if (session == null) {
        promise.reject("SESSION_NOT_FOUND", "Session not found")
        return
      }
      // session.clear() already calls notifyListeners() internally
      session.clear()
      promise.resolve(null)
    }
  }

  @ReactMethod
  fun getAllText(
    sessionId: String,
    promise: Promise,
  ) {
    synchronized(lock) {
      val session = sessions[sessionId]
      if (session == null) {
        promise.reject("SESSION_NOT_FOUND", "Session not found")
        return
      }
      promise.resolve(session.getAllText())
    }
  }

  @ReactMethod
  fun getHighlightPosition(
    sessionId: String,
    promise: Promise,
  ) {
    synchronized(lock) {
      val session = sessions[sessionId]
      if (session == null) {
        promise.reject("SESSION_NOT_FOUND", "Session not found")
        return
      }
      promise.resolve(session.highlightPosition)
    }
  }

  @ReactMethod
  fun setHighlightPosition(
    sessionId: String,
    position: Double,
    promise: Promise,
  ) {
    synchronized(lock) {
      val session = sessions[sessionId]
      if (session == null) {
        promise.reject("SESSION_NOT_FOUND", "Session not found")
        return
      }
      session.highlightPosition = position
      promise.resolve(null)
    }
  }

  @ReactMethod
  fun addListener(
    sessionId: String,
    listenerId: String,
    promise: Promise,
  ) {
    synchronized(lock) {
      val session = sessions[sessionId]
      val listeners = sessionListeners[sessionId]
      if (session == null || listeners == null) {
        promise.reject("SESSION_NOT_FOUND", "Session not found")
        return
      }

      val unsubscribe =
        session.addListener {
          // sendEvent must be called on main thread
          // Always post to ensure we're on main thread (React Native bridge methods run on background thread)
          android.os.Handler(android.os.Looper.getMainLooper()).post {
            sendEvent("MarkdownSessionUpdate", sessionId, listenerId)
          }
        }

      listeners[listenerId] = unsubscribe
      promise.resolve(null)
    }
  }

  @ReactMethod
  fun removeListener(
    sessionId: String,
    listenerId: String,
    promise: Promise,
  ) {
    synchronized(lock) {
      val listeners = sessionListeners[sessionId]
      val unsubscribe = listeners?.remove(listenerId)
      if (unsubscribe != null) {
        unsubscribe()
      }
      promise.resolve(null)
    }
  }

  @ReactMethod
  fun disposeSession(
    sessionId: String,
    promise: Promise,
  ) {
    synchronized(lock) {
      sessions.remove(sessionId)
      sessionListeners.remove(sessionId)
      promise.resolve(null)
    }
  }

  private fun sendEvent(
    eventName: String,
    sessionId: String,
    listenerId: String,
  ) {
    reactApplicationContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(
        eventName,
        com.facebook.react.bridge.Arguments.createMap().apply {
          putString("sessionId", sessionId)
          putString("listenerId", listenerId)
        },
      )
  }
}
