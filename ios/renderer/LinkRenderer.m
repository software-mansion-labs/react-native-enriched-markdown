#import "LinkRenderer.h"

@implementation LinkRenderer

- (instancetype)initWithTextRenderer:(id<NodeRenderer>)textRenderer {
    self = [super init];
    if (self) {
        _textRenderer = textRenderer;
    }
    return self;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    NSUInteger start = output.length;
    
    for (MarkdownASTNode *child in node.children) {
        if (child.type == MarkdownNodeTypeText && child.content) {
            [self.textRenderer renderNode:child 
                                    into:output 
                               withFont:font
                                  color:color
                                 context:context];
        }
    }
    
    NSUInteger len = output.length - start;
    if (len > 0) {
        NSRange range = NSMakeRange(start, len);
        NSString *url = node.attributes[@"url"] ?: @"";
        
        [output addAttributes:@{
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
        } range:range];
        [output addAttribute:NSLinkAttributeName 
                       value:url 
                       range:range];
        [context registerLinkRange:range url:url];
    }
}

@end
