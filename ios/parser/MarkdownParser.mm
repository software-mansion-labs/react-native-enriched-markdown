#import "MarkdownParser.h"
#import "MarkdownASTNode.h"
#import "md4c.h"

typedef struct {
    MarkdownASTNode *root;
    NSMutableArray<MarkdownASTNode *> *nodeStack;
} MD4CContext;

static void addNodeToContext(MarkdownASTNode *node, MD4CContext *context) {
    if (!node || !context || !context->nodeStack) return;
    
    if (context->root == nil) {
        context->root = node;
    } else {
        MarkdownASTNode *parent = [context->nodeStack lastObject];
        if (parent) {
            [parent addChild:node];
        }
    }
    [context->nodeStack addObject:node];
}

static void addInlineNodeToContext(MarkdownASTNode *node, MD4CContext *context) {
    if (!node || !context || !context->nodeStack) return;
    
    MarkdownASTNode *parent = [context->nodeStack lastObject];
    if (parent) {
        [parent addChild:node];
    }
}

static NSString *stringFromMDAttribute(const MD_ATTRIBUTE *attr) {
    if (!attr || attr->size == 0) return nil;
    
    return [[NSString alloc] initWithBytes:attr->text
                                     length:attr->size
                                   encoding:NSUTF8StringEncoding];
}

// MD4C callback functions
// Note: All callbacks return 0 for success (continue parsing) or non-zero for error (stop parsing)
static int md4c_enter_block_callback(MD_BLOCKTYPE type, void *detail, void *userdata) {
    if (!userdata) return 1;
    
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
                // Clamp level to valid range (1-6)
                level = MAX(1, MIN(6, level));
                [node setAttribute:@"level" value:@(level).stringValue];
            }
            break;
        }
        default:
            return 0;
    }
    
    if (node) {
        addNodeToContext(node, context);
    }
    return 0;
}

static int md4c_leave_block_callback(MD_BLOCKTYPE type, void *detail, void *userdata) {
    if (!userdata) return 1;
    
    MD4CContext *context = (MD4CContext *)userdata;
    if (!context || !context->nodeStack) return 1;
    
    if ([context->nodeStack count] > 0) {
        [context->nodeStack removeLastObject];
    }
    
    return 0;
}

static int md4c_enter_span_callback(MD_SPANTYPE type, void *detail, void *userdata) {
    if (!userdata) return 1;
    
    MD4CContext *context = (MD4CContext *)userdata;
    MarkdownASTNode *node = nil;
    
    switch (type) {
        case MD_SPAN_A: {
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeLink];
            if (detail) {
                MD_SPAN_A_DETAIL *linkDetail = (MD_SPAN_A_DETAIL *)detail;
                NSString *url = stringFromMDAttribute(&linkDetail->href);
                if (url) {
                    [node setAttribute:@"url" value:url];
                }
            }
            break;
        }
        case MD_SPAN_STRONG: {
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeStrong];
            break;
        }
        case MD_SPAN_EM: {
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeEmphasis];
            break;
        }
        case MD_SPAN_CODE: {
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeCode];
            break;
        }
        case MD_SPAN_IMG: {
            node = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeImage];
            if (detail) {
                MD_SPAN_IMG_DETAIL *imgDetail = (MD_SPAN_IMG_DETAIL *)detail;
                NSString *url = stringFromMDAttribute(&imgDetail->src);
                if (url) {
                    [node setAttribute:@"url" value:url];
                }
                NSString *title = stringFromMDAttribute(&imgDetail->title);
                if (title) {
                    [node setAttribute:@"title" value:title];
                }
            }
            break;
        }
        default:
            return 0;
    }
    
    if (node) {
        addNodeToContext(node, context);
    }
    return 0;
}

static int md4c_leave_span_callback(MD_SPANTYPE type, void *detail, void *userdata) {
    if (!userdata) return 1;
    
    MD4CContext *context = (MD4CContext *)userdata;
    if (!context || !context->nodeStack) return 1;
    
    if ([context->nodeStack count] > 0) {
        [context->nodeStack removeLastObject];
    }
    
    return 0;
}

static int md4c_text_callback(MD_TEXTTYPE type, const MD_CHAR *text, MD_SIZE size, void *userdata) {
    if (!userdata) return 1;
    
    MD4CContext *context = (MD4CContext *)userdata;
    if (!context || !context->nodeStack) return 1;

    // Handle soft/hard line breaks (MD4C provides these for explicit line breaks within paragraphs)
    // Note: MD4C does NOT provide empty lines between blocks - those are added by renderers
    if (type == MD_TEXT_SOFTBR || type == MD_TEXT_BR) {
        MarkdownASTNode *brNode = [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeLineBreak];
        addInlineNodeToContext(brNode, context);
        return 0;
    }

    // Handle text content (normal text, code text, etc.)
    // MD_TEXT_CODE is text inside code spans, which should be rendered as text nodes
    if (size > 0 && (type == MD_TEXT_NORMAL || type == MD_TEXT_CODE)) {
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
    if (markdown.length == 0) {
        return [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
    }
    
    // Initialize context
    MD4CContext context = {
        .root = nil,
        .nodeStack = [[NSMutableArray alloc] init]
    };
    
    // Configure MD4C parser with callbacks
    MD_PARSER parser = {
        .enter_block = md4c_enter_block_callback,
        .leave_block = md4c_leave_block_callback,
        .enter_span = md4c_enter_span_callback,
        .leave_span = md4c_leave_span_callback,
        .text = md4c_text_callback,
        .debug_log = NULL,
        .syntax = NULL
    };
    
    // Parse the markdown with proper error handling
    const char *markdownCString = markdown.UTF8String;
    if (!markdownCString) {
        NSLog(@"MarkdownParser: Failed to convert markdown to UTF-8");
        return [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
    }
    
    MD_SIZE markdownLength = (MD_SIZE)strlen(markdownCString);
    int result = md_parse(markdownCString, markdownLength, &parser, &context);
    
    if (result != 0) {
        NSLog(@"MarkdownParser: MD4C parsing failed with error: %d", result);
        return [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
    }
    
    return context.root ?: [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
}

@end