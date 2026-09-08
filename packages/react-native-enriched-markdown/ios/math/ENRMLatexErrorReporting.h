#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Reports a LaTeX expression the engine could not parse or render. The whole
/// expression is the unit of failure - the engine does not attribute a single
/// command. `displayMode` is NO for inline `$...$`, YES for block `$$...$$`.
typedef void (^ENRMLatexErrorHandler)(NSString *source, NSString *message, BOOL displayMode);

/// Adopted by the inline math attachment and the block math container so the
/// host view can inject one reporter into every math object after a render.
/// Pure Foundation so it compiles even when math is disabled.
@protocol ENRMLatexErrorReporting <NSObject>
@property (nonatomic, copy, nullable) ENRMLatexErrorHandler onLatexError;
/// Fires onLatexError for a failure that was already detected before the reporter
/// was wired. Inline math is parsed during background measurement (boxHeight),
/// which can happen before the host view attaches the reporter, so the failure is
/// recorded and drained here once onLatexError is set. No-op if nothing failed.
- (void)reportLatexErrorIfNeeded;
@end

NS_ASSUME_NONNULL_END
