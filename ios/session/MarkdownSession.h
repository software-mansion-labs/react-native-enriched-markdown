#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A thread-safe session for streaming markdown content.
 * Stores text in native memory and notifies listeners when content changes.
 */
@interface MarkdownSession : NSObject

/**
 * Current highlight position for karaoke-style highlighting.
 */
@property (nonatomic, assign) NSInteger highlightPosition;

/**
 * Appends a chunk of text to the session buffer.
 * Thread-safe operation that notifies all listeners.
 *
 * @param chunk The text chunk to append
 */
- (void)append:(NSString *)chunk;

/**
 * Clears the session buffer and resets highlight position.
 * Thread-safe operation that notifies all listeners.
 */
- (void)clear;

/**
 * Returns the complete text content of the session.
 * Thread-safe read operation.
 *
 * @return The full text content
 */
- (NSString *)getAllText;

/**
 * Adds a listener that will be called whenever the session content changes.
 * The listener is called on the main thread.
 *
 * @param listener Block to be called on updates
 * @return A token that can be used to remove the listener
 */
- (id)addListener:(void (^)(void))listener;

/**
 * Removes a listener using the token returned from addListener.
 *
 * @param listenerId The token returned from addListener
 */
- (void)removeListener:(id)listenerId;

@end

NS_ASSUME_NONNULL_END
