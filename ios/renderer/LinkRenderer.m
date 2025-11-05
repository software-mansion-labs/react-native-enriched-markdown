#import "LinkRenderer.h"
#import "RichTextConfig.h"
#import "RendererFactory.h"

@implementation LinkRenderer {
    RendererFactory *_rendererFactory;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config {
    self = [super init];
    if (self) {
        _rendererFactory = rendererFactory;
        self.config = config;
    }
    return self;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    NSUInteger start = output.length;
    
    [_rendererFactory renderChildrenOfNode:node
                                      into:output
                                  withFont:font
                                     color:color
                                    context:context];
    
    NSUInteger len = output.length - start;
    if (len > 0) {
        NSRange range = NSMakeRange(start, len);
        NSString *url = node.attributes[@"url"] ?: @"";
        
        NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];
        RichTextConfig *config = (RichTextConfig *)self.config;
        
        NSMutableDictionary *linkAttributes = [existingAttributes mutableCopy];
        linkAttributes[NSLinkAttributeName] = url;
        
        UIColor *linkColor = [config linkColor];
        linkAttributes[NSForegroundColorAttributeName] = linkColor;
        linkAttributes[NSUnderlineColorAttributeName] = linkColor;
        
        BOOL shouldUnderline = [config linkUnderline];
        linkAttributes[NSUnderlineStyleAttributeName] = shouldUnderline ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
        
        [output setAttributes:linkAttributes range:range];
        [context registerLinkRange:range url:url];
    }
}

@end
