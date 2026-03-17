#import "ENRMContextMenuTextView+macOS.h"
#include <TargetConditionals.h>

#if TARGET_OS_OSX

@implementation ENRMContextMenuTextView

- (NSMenu *)menuForEvent:(NSEvent *)event
{
  NSMenu *baseMenu = [super menuForEvent:event];
  if (!self.contextMenuProvider || self.selectedRange.length == 0) {
    return baseMenu;
  }
  return self.contextMenuProvider(baseMenu, self);
}

@end

#endif // TARGET_OS_OSX
