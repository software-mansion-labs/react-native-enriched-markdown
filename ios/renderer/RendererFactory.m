#import "RendererFactory.h"
#import "ParagraphRenderer.h"
#import "TextRenderer.h"
#import "LinkRenderer.h"
#import "HeadingRenderer.h"
#import "BoldRenderer.h"
#import "RenderContext.h"

@implementation RendererFactory {
    id _config;
    TextRenderer *_sharedTextRenderer;
    LinkRenderer *_sharedLinkRenderer;
    HeadingRenderer *_sharedHeadingRenderer;
    BoldRenderer *_sharedBoldRenderer;
    ParagraphRenderer *_sharedParagraphRenderer;
}

- (instancetype)initWithConfig:(id)config {
    self = [super init];
    if (self) {
        _config = config;
        _sharedTextRenderer = [TextRenderer new];
        _sharedBoldRenderer = [[BoldRenderer alloc] initWithRendererFactory:self
                                                                     config:config];
        _sharedLinkRenderer = [[LinkRenderer alloc] initWithRendererFactory:self config:config];
        _sharedHeadingRenderer = [[HeadingRenderer alloc] initWithRendererFactory:self
                                                                         config:config];
        _sharedParagraphRenderer = [[ParagraphRenderer alloc] initWithRendererFactory:self];
    }
    return self;
}

- (id<NodeRenderer>)rendererForNodeType:(MarkdownNodeType)type {
    switch (type) {
        case MarkdownNodeTypeParagraph:
            return _sharedParagraphRenderer;
        case MarkdownNodeTypeText: 
            return _sharedTextRenderer;
        case MarkdownNodeTypeLink:
            return _sharedLinkRenderer;
        case MarkdownNodeTypeHeading:
            return _sharedHeadingRenderer;
        case MarkdownNodeTypeStrong:
            return _sharedBoldRenderer;
        default: 
            return nil;
    }
}

- (void)renderChildrenOfNode:(MarkdownASTNode *)node
                        into:(NSMutableAttributedString *)output
                    withFont:(UIFont *)font
                       color:(UIColor *)color
                      context:(RenderContext *)context {
    for (MarkdownASTNode *child in node.children) {
        id<NodeRenderer> renderer = [self rendererForNodeType:child.type];
        if (renderer) {
            [renderer renderNode:child 
                          into:output 
                     withFont:font
                        color:color
                       context:context];
        }
    }
}

@end
