#pragma once
#include <TargetConditionals.h>

#if TARGET_OS_OSX
#import "ENRMUIKit.h"

typedef NSMenu *_Nullable (^ENRMContextMenuProvider)(NSMenu *baseMenu, NSTextView *textView);

/// macOS-only ENRMPlatformTextView subclass that intercepts menuForEvent: via a block.
/// Follows the same object_setClass pattern used by TextViewLayoutManager.
@interface ENRMContextMenuTextView : ENRMPlatformTextView

@property (nonatomic, copy, nullable) ENRMContextMenuProvider contextMenuProvider;

@end

#endif // TARGET_OS_OSX
