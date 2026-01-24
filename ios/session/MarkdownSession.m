#import "MarkdownSession.h"

@interface MarkdownSession ()
@property (nonatomic, strong) NSMutableString *buffer;
@property (nonatomic, strong) NSMutableDictionary<NSString *, void (^)(void)> *listeners;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, assign) NSInteger version;
@end

@implementation MarkdownSession

- (instancetype)init
{
  if (self = [super init]) {
    _buffer = [NSMutableString string];
    _listeners = [NSMutableDictionary dictionary];
    _lock = [[NSLock alloc] init];
    _version = 0;
    _highlightPosition = 0;
  }
  return self;
}

- (void)append:(NSString *)chunk
{
  if (!chunk || chunk.length == 0) {
    return;
  }

  [_lock lock];
  [_buffer appendString:chunk];
  _version++;
  [_lock unlock];

  [self notifyListeners];
}

- (void)clear
{
  [_lock lock];
  [_buffer setString:@""];
  _highlightPosition = 0;
  _version++;
  [_lock unlock];

  [self notifyListeners];
}

- (NSString *)getAllText
{
  [_lock lock];
  NSString *text = [_buffer copy];
  [_lock unlock];
  return text;
}

- (id)addListener:(void (^)(void))listener
{
  if (!listener) {
    return nil;
  }

  NSString *listenerId = [[NSUUID UUID] UUIDString];
  listener = [listener copy];

  [_lock lock];
  _listeners[listenerId] = listener;
  [_lock unlock];

  // Return a block that removes the listener
  // Copy listenerId to ensure it's retained in the block
  NSString *capturedListenerId = [listenerId copy];
  __weak typeof(self) weakSelf = self;
  void (^unsubscribeBlock)(void) = [^{
    typeof(self) strongSelf = weakSelf;
    if (strongSelf && strongSelf.listeners) {
      [strongSelf.lock lock];
      [strongSelf.listeners removeObjectForKey:capturedListenerId];
      [strongSelf.lock unlock];
    }
  } copy];

  return unsubscribeBlock;
}

- (void)removeListener:(id)listenerId
{
  if (!listenerId) {
    return;
  }

  // listenerId is a block returned from addListener:
  // Execute on main queue to ensure thread safety
  if ([NSThread isMainThread]) {
    void (^unsubscribe)(void) = (void (^)(void))listenerId;
    if (unsubscribe) {
      unsubscribe();
    }
  } else {
    void (^unsubscribe)(void) = (void (^)(void))listenerId;
    if (unsubscribe) {
      dispatch_async(dispatch_get_main_queue(), ^{ unsubscribe(); });
    }
  }
}

- (void)notifyListeners
{
  // Copy listeners array while holding lock (like nitro-markdown does)
  NSArray<void (^)(void)> *currentListeners;
  [_lock lock];
  currentListeners = [_listeners.allValues copy];
  [_lock unlock];

  // Call listeners synchronously (like nitro-markdown - no async dispatch)
  // The listener blocks themselves can handle thread safety if needed
  for (void (^listener)(void) in currentListeners) {
    if (listener) {
      @try {
        listener();
      } @catch (NSException *exception) {
        // Silently fail if listener execution fails
      }
    }
  }
}

@end
