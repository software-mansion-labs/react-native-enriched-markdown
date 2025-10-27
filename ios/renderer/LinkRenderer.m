#import "LinkRenderer.h"

@implementation LinkRenderer

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    NSUInteger start = output.length;
    
    for (MarkdownASTNode *child in node.children) {
        if (child.type == MarkdownNodeTypeText && child.content) {
            NSAttributedString *text = [[NSAttributedString alloc] 
                initWithString:child.content 
                attributes:@{
                    NSFontAttributeName: font
                }];
            [output appendAttributedString:text];
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
