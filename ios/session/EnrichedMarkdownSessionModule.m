#import "EnrichedMarkdownSessionModule.h"
#import "MarkdownSession.h"
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>

// Global session storage
static NSMutableDictionary<NSString *, MarkdownSession *> *sessions = nil;
static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *sessionListeners = nil;
static NSLock *sessionsLock = nil;

static void initializeStorage(void)
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sessions = [NSMutableDictionary dictionary];
    sessionListeners = [NSMutableDictionary dictionary];
    sessionsLock = [[NSLock alloc] init];
  });
}

@implementation EnrichedMarkdownSessionModule

RCT_EXPORT_MODULE(EnrichedMarkdownSessionModule);

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

RCT_EXPORT_METHOD(createSession : (RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  initializeStorage();

  MarkdownSession *session = [[MarkdownSession alloc] init];
  NSString *sessionId = [[NSUUID UUID] UUIDString];

  [sessionsLock lock];
  sessions[sessionId] = session;
  sessionListeners[sessionId] = [NSMutableDictionary dictionary];
  [sessionsLock unlock];

  resolve(sessionId);
}

RCT_EXPORT_METHOD(append
                  : (NSString *)sessionId chunk
                  : (NSString *)chunk resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  if (!sessionId || !chunk) {
    if (reject) {
      reject(@"INVALID_ARGUMENT", @"sessionId and chunk are required", nil);
    }
    return;
  }

  initializeStorage();

  MarkdownSession *session = nil;
  [sessionsLock lock];
  session = sessions[sessionId];
  [sessionsLock unlock];

  if (!session) {
    if (reject) {
      reject(@"SESSION_NOT_FOUND", @"Session not found", nil);
    }
    return;
  }

  // Use the session - ARC will retain it for the duration of this method
  @try {
    [session append:chunk];
    if (resolve) {
      resolve(nil);
    }
  } @catch (NSException *exception) {
    if (reject) {
      reject(@"APPEND_ERROR", [exception reason] ?: @"Unknown error", nil);
    }
  }
}

RCT_EXPORT_METHOD(clear
                  : (NSString *)sessionId resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  if (!sessionId) {
    if (reject) {
      reject(@"INVALID_ARGUMENT", @"sessionId is required", nil);
    }
    return;
  }

  initializeStorage();

  [sessionsLock lock];
  MarkdownSession *session = sessions[sessionId];
  [sessionsLock unlock];

  if (!session) {
    if (reject) {
      reject(@"SESSION_NOT_FOUND", @"Session not found", nil);
    }
    return;
  }

  @try {
    [session clear];
    if (resolve) {
      resolve(nil);
    }
  } @catch (NSException *exception) {
    if (reject) {
      reject(@"CLEAR_ERROR", [exception reason] ?: @"Unknown error", nil);
    }
  }
}

RCT_EXPORT_METHOD(getAllText
                  : (NSString *)sessionId resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  if (!sessionId) {
    if (reject) {
      reject(@"INVALID_ARGUMENT", @"sessionId is required", nil);
    }
    return;
  }

  initializeStorage();

  [sessionsLock lock];
  MarkdownSession *session = sessions[sessionId];
  [sessionsLock unlock];

  if (!session) {
    if (reject) {
      reject(@"SESSION_NOT_FOUND", @"Session not found", nil);
    }
    return;
  }

  @try {
    NSString *text = [session getAllText];
    if (resolve) {
      resolve(text ?: @"");
    }
  } @catch (NSException *exception) {
    if (reject) {
      reject(@"GET_TEXT_ERROR", [exception reason] ?: @"Unknown error", nil);
    }
  }
}

RCT_EXPORT_METHOD(getHighlightPosition
                  : (NSString *)sessionId resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  if (!sessionId) {
    if (reject) {
      reject(@"INVALID_ARGUMENT", @"sessionId is required", nil);
    }
    return;
  }

  initializeStorage();

  [sessionsLock lock];
  MarkdownSession *session = sessions[sessionId];
  [sessionsLock unlock];

  if (!session) {
    if (reject) {
      reject(@"SESSION_NOT_FOUND", @"Session not found", nil);
    }
    return;
  }

  @try {
    if (resolve) {
      resolve(@(session.highlightPosition));
    }
  } @catch (NSException *exception) {
    if (reject) {
      reject(@"GET_HIGHLIGHT_ERROR", [exception reason] ?: @"Unknown error", nil);
    }
  }
}

RCT_EXPORT_METHOD(setHighlightPosition
                  : (NSString *)sessionId position
                  : (NSNumber *)position resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  if (!sessionId || !position) {
    if (reject) {
      reject(@"INVALID_ARGUMENT", @"sessionId and position are required", nil);
    }
    return;
  }

  initializeStorage();

  [sessionsLock lock];
  MarkdownSession *session = sessions[sessionId];
  [sessionsLock unlock];

  if (!session) {
    if (reject) {
      reject(@"SESSION_NOT_FOUND", @"Session not found", nil);
    }
    return;
  }

  @try {
    session.highlightPosition = [position integerValue];
    if (resolve) {
      resolve(nil);
    }
  } @catch (NSException *exception) {
    if (reject) {
      reject(@"SET_HIGHLIGHT_ERROR", [exception reason] ?: @"Unknown error", nil);
    }
  }
}

RCT_EXPORT_METHOD(addListener
                  : (NSString *)sessionId listenerId
                  : (NSString *)listenerId resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  if (!sessionId || !listenerId) {
    if (reject) {
      reject(@"INVALID_ARGUMENT", @"sessionId and listenerId are required", nil);
    }
    return;
  }

  initializeStorage();

  [sessionsLock lock];
  MarkdownSession *session = sessions[sessionId];
  NSMutableDictionary *listeners = sessionListeners[sessionId];
  [sessionsLock unlock];

  if (!session || !listeners) {
    if (reject) {
      reject(@"SESSION_NOT_FOUND", @"Session not found", nil);
    }
    return;
  }

  // Copy strings to ensure they're retained in the block
  NSString *copiedSessionId = [sessionId copy];
  NSString *copiedListenerId = [listenerId copy];

  __weak typeof(self) weakSelf = self;
  void (^listenerBlock)(void) = [^{
    typeof(self) strongSelf = weakSelf;
    // Check bridge and that we can send events
    // Dispatch to main queue here since sendEventWithName must be called on main thread
    if (strongSelf) {
      RCTBridge *bridge = strongSelf.bridge;
      if (bridge && [bridge isValid]) {
        // sendEventWithName must be called on main thread
        if ([NSThread isMainThread]) {
          @try {
            [strongSelf sendEventWithName:@"MarkdownSessionUpdate"
                                     body:@{@"sessionId" : copiedSessionId, @"listenerId" : copiedListenerId}];
          } @catch (NSException *exception) {
            // Silently fail if event sending fails (e.g., bridge is invalidating)
          }
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            if (strongSelf && strongSelf.bridge && [strongSelf.bridge isValid]) {
              @try {
                [strongSelf sendEventWithName:@"MarkdownSessionUpdate"
                                         body:@{@"sessionId" : copiedSessionId, @"listenerId" : copiedListenerId}];
              } @catch (NSException *exception) {
                // Silently fail if event sending fails
              }
            }
          });
        }
      }
    }
  } copy];

  id unsubscribe = [session addListener:listenerBlock];

  @try {
    [sessionsLock lock];
    if (unsubscribe) {
      listeners[copiedListenerId] = unsubscribe;
    }
    [sessionsLock unlock];

    if (resolve) {
      resolve(nil);
    }
  } @catch (NSException *exception) {
    [sessionsLock unlock];
    if (reject) {
      reject(@"ADD_LISTENER_ERROR", [exception reason] ?: @"Unknown error", nil);
    }
  }
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[ @"MarkdownSessionUpdate" ];
}

- (void)startObserving
{
  // Required by RCTEventEmitter
}

- (void)stopObserving
{
  // Required by RCTEventEmitter
}

RCT_EXPORT_METHOD(removeListener
                  : (NSString *)sessionId listenerId
                  : (NSString *)listenerId resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  initializeStorage();

  [sessionsLock lock];
  NSMutableDictionary *listeners = sessionListeners[sessionId];
  id unsubscribe = listeners ? listeners[listenerId] : nil;
  if (unsubscribe) {
    [listeners removeObjectForKey:listenerId];
  }
  MarkdownSession *session = sessions[sessionId];
  [sessionsLock unlock];

  if (unsubscribe && session) {
    [session removeListener:unsubscribe];
  }

  resolve(nil);
}

RCT_EXPORT_METHOD(disposeSession
                  : (NSString *)sessionId resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  initializeStorage();

  [sessionsLock lock];
  [sessions removeObjectForKey:sessionId];
  [sessionListeners removeObjectForKey:sessionId];
  [sessionsLock unlock];

  resolve(nil);
}

@end
