#import "MarkdownParser.h"
#import "MarkdownASTNode.h"
#import "md4c.h"

// Context for MD4C callbacks
typedef struct {
    MarkdownASTNode *root;
    NSMutableArray<MarkdownASTNode *> *nodeStack;
} MD4CContext;

static void addNodeToContext(MarkdownASTNode *node, MD4CContext *context) {
    if (!node) return;
    
    if (context->root == nil) {
        context->root = node;
    } else {
        MarkdownASTNode *parent = [context->nodeStack lastObject];
        [parent addChild:node];
    }
    [context->nodeStack addObject:node];
}

static void addInlineNodeToContext(MarkdownASTNode *node, MD4CContext *context) {
    if (!node) return;
    
    MarkdownASTNode *parent = [context->nodeStack lastObject];
    [parent addChild:node];
}

// MD4C callback functions
// Note: All callbacks return 0 for success (continue parsing) or non-zero for error (stop parsing)
static int md4c_enter_block_callback(MD_BLOCKTYPE type, void *detail, void *userdata) {
    MD4CContext *context = (MD4CContext *)userdata;
    MarkdownASTNode *node = nil;
    
    switch (type) {
        case MD_BLOCK_DOC:
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
            break;
        case MD_BLOCK_P:
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeParagraph];
            break;
        case MD_BLOCK_H: {
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeHeading];
            if (detail) {
                MD_BLOCK_H_DETAIL *h = (MD_BLOCK_H_DETAIL *)detail;
                NSInteger level = (NSInteger)h->level;
                [node setAttribute:@"level" value:@(level).stringValue];
            }
            break;
        }
        default:
            return 0;
    }
    
    addNodeToContext(node, context);
    return 0;
}

static int md4c_leave_block_callback(MD_BLOCKTYPE type, void *detail, void *userdata) {
    MD4CContext *context = (MD4CContext *)userdata;
    
    if ([context->nodeStack count] > 0) {
        [context->nodeStack removeLastObject];
    }
    
    return 0;
}

static int md4c_enter_span_callback(MD_SPANTYPE type, void *detail, void *userdata) {
    MD4CContext *context = (MD4CContext *)userdata;
    MarkdownASTNode *node = nil;
    
    switch (type) {
        case MD_SPAN_A: {
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeLink];
            if (detail) {
                MD_SPAN_A_DETAIL *linkDetail = (MD_SPAN_A_DETAIL *)detail;
                if (linkDetail->href.size > 0) {
                    NSString *url = [[NSString alloc] initWithBytes:linkDetail->href.text 
                                                             length:linkDetail->href.size 
                                                           encoding:NSUTF8StringEncoding];
                    [node setAttribute:@"url" value:url];
                }
            }
            break;
        }
        default:
            return 0;
    }
    
    addNodeToContext(node, context);
    return 0;
}

static int md4c_leave_span_callback(MD_SPANTYPE type, void *detail, void *userdata) {
    MD4CContext *context = (MD4CContext *)userdata;
    
    if ([context->nodeStack count] > 0) {
        [context->nodeStack removeLastObject];
    }
    
    return 0;
}

static int md4c_text_callback(MD_TEXTTYPE type, const MD_CHAR *text, MD_SIZE size, void *userdata) {
    MD4CContext *context = (MD4CContext *)userdata;

    // Handle soft/hard line breaks (MD4C provides these for explicit line breaks within paragraphs)
    // Note: MD4C does NOT provide empty lines between blocks - those are added by renderers
    if (type == MD_TEXT_SOFTBR || type == MD_TEXT_BR) {
        MarkdownASTNode *brNode = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeLineBreak];
        addInlineNodeToContext(brNode, context);
        return 0;
    }

    if (size > 0) {
        NSString *textString = [[NSString alloc] initWithBytes:text
                                                        length:size
                                                      encoding:NSUTF8StringEncoding];
        if (textString) {
            MarkdownASTNode *textNode = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeText];
            textNode.content = textString;
            addInlineNodeToContext(textNode, context);
        }
    }
    
    return 0;
}

@implementation MarkdownParser

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown {
    if (!markdown.length) {
        return [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
    }
    
    // Initialize context
    MD4CContext context = {
        .root = nil,
        .nodeStack = [[NSMutableArray alloc] init]
    };
    
    // Configure MD4C parser
    MD_PARSER parser = {
        .enter_block = md4c_enter_block_callback,
        .leave_block = md4c_leave_block_callback,
        .enter_span = md4c_enter_span_callback,
        .leave_span = md4c_leave_span_callback,
        .text = md4c_text_callback,
        .debug_log = NULL,
        .syntax = NULL
    };
    
    // Parse the markdown
    const char *markdownCString = markdown.UTF8String;
    MD_SIZE markdownLength = (MD_SIZE)strlen(markdownCString);
    int result = md_parse(markdownCString, markdownLength, &parser, &context);
    
    if (result != 0) {
        NSLog(@"MarkdownParser: MD4C parsing failed with error: %d", result);
        return [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
    }
    
    return context.root ?: [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
}

@end