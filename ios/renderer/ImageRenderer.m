#import "ImageRenderer.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RichTextConfig.h"
#import "RendererFactory.h"
#import "RichTextImageAttachment.h"

static const unichar kLineBreak = '\n';
static const unichar kZeroWidthSpace = 0x200B;

@implementation ImageRenderer {
    RendererFactory *_rendererFactory;
    RichTextConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory
                                 config:(id)config {
    self = [super init];
    if (self) {
        _rendererFactory = rendererFactory;
        _config = (RichTextConfig *)config;
    }
    return self;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    NSString *imageURL = node.attributes[@"url"];
    if (!imageURL.length) return;
    
    BOOL isInline = [self isInlineImageInOutput:output];
    
    RichTextImageAttachment *attachment = [[RichTextImageAttachment alloc]
        initWithImageURL:imageURL
                  config:_config
                isInline:isInline];
    
    [output appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
}

#pragma mark - Private Helpers

- (BOOL)isInlineImageInOutput:(NSMutableAttributedString *)output {
    if (output.length == 0) return NO;
    
    unichar lastChar = [output.string characterAtIndex:output.length - 1];
    return lastChar != kLineBreak && lastChar != kZeroWidthSpace;
}

@end

