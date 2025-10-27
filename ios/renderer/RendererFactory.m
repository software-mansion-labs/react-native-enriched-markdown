#import "RendererFactory.h"
#import "ParagraphRenderer.h"
#import "TextRenderer.h"
#import "LinkRenderer.h"
#import "HeadingRenderer.h"

@implementation RendererFactory {
    TextRenderer *_sharedTextRenderer;
    LinkRenderer *_sharedLinkRenderer;
    HeadingRenderer *_sharedHeadingRenderer;
    ParagraphRenderer *_sharedParagraphRenderer;
}

+ (instancetype)sharedFactory {
    static RendererFactory *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RendererFactory alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sharedTextRenderer = [TextRenderer new];
        _sharedLinkRenderer = [[LinkRenderer alloc] initWithTextRenderer:_sharedTextRenderer];
        _sharedHeadingRenderer = [[HeadingRenderer alloc] initWithTextRenderer:_sharedTextRenderer];
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
