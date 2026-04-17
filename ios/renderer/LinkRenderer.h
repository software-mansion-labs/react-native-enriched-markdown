#import "MarkdownASTNode.h"
#import "NodeRenderer.h"
#import "RenderContext.h"

/**
 * Attribute names used by the link/mention/citation renderer to tag ranges of
 * the rendered NSAttributedString. Tap dispatching reads these to decide which
 * JS event to fire for a given character.
 */
FOUNDATION_EXPORT NSString *const ENRMMentionURLAttributeName;
FOUNDATION_EXPORT NSString *const ENRMMentionTextAttributeName;
FOUNDATION_EXPORT NSString *const ENRMCitationURLAttributeName;
FOUNDATION_EXPORT NSString *const ENRMCitationTextAttributeName;

@interface LinkRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
