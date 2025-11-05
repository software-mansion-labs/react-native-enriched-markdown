#import "ParagraphRenderer.h"
#import "SpacingUtils.h"
#import "RendererFactory.h"

@implementation ParagraphRenderer {
    RendererFactory *_rendererFactory;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory {
    self = [super init];
    if (self) {
        _rendererFactory = rendererFactory;
    }
    return self;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    
    [_rendererFactory renderChildrenOfNode:node
                                      into:output
                                  withFont:font
                                     color:color
                                    context:context];
}

@end