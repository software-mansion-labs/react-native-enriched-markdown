#import "RendererFactory.h"
#import "ParagraphRenderer.h"
#import "TextRenderer.h"
#import "LinkRenderer.h"
#import "HeadingRenderer.h"

@implementation RendererFactory

+ (instancetype)sharedFactory {
    static RendererFactory *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RendererFactory alloc] init];
    });
    return sharedInstance;
}

- (id<NodeRenderer>)rendererForNodeType:(MarkdownNodeType)type {
    switch (type) {
        case MarkdownNodeTypeParagraph: {
            ParagraphRenderer *paragraphRenderer = [[ParagraphRenderer alloc] initWithLinkRenderer:[LinkRenderer new]];
            return paragraphRenderer;
        }
        case MarkdownNodeTypeText: 
            return [TextRenderer new];
        case MarkdownNodeTypeLink: 
            return [LinkRenderer new];
        case MarkdownNodeTypeHeading: {
            HeadingRenderer *headingRenderer = [[HeadingRenderer alloc] initWithTextRenderer:[TextRenderer new]];
            return headingRenderer;
        }
        default: 
            return nil;
    }
}

@end
