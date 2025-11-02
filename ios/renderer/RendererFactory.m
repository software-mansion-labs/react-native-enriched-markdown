#import "RendererFactory.h"
#import "ParagraphRenderer.h"
#import "TextRenderer.h"
#import "LinkRenderer.h"
#import "HeadingRenderer.h"

@implementation RendererFactory {
    id _config;
    TextRenderer *_sharedTextRenderer;
    LinkRenderer *_sharedLinkRenderer;
    HeadingRenderer *_sharedHeadingRenderer;
    ParagraphRenderer *_sharedParagraphRenderer;
}

- (instancetype)initWithConfig:(id)config {
    self = [super init];
    if (self) {
        _config = config;
        _sharedTextRenderer = [TextRenderer new];
        _sharedLinkRenderer = [[LinkRenderer alloc] initWithTextRenderer:_sharedTextRenderer config:config];
        _sharedHeadingRenderer = [[HeadingRenderer alloc] initWithTextRenderer:_sharedTextRenderer config:config];
        _sharedParagraphRenderer = [[ParagraphRenderer alloc] initWithLinkRenderer:_sharedLinkRenderer
                                                                      textRenderer:_sharedTextRenderer];
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
        default: 
            return nil;
    }
}

@end
