#include "MD4C/src/md4c.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// Callback functions for MD4C
static int enter_block_callback(MD_BLOCKTYPE type, void* detail, void* userdata);
static int leave_block_callback(MD_BLOCKTYPE type, void* detail, void* userdata);
static int enter_span_callback(MD_SPANTYPE type, void* detail, void* userdata);
static int leave_span_callback(MD_SPANTYPE type, void* detail, void* userdata);
static int text_callback(MD_TEXTTYPE type, const MD_CHAR* text, MD_SIZE size, void* userdata);

int main() {
    printf("MD4C Test - Starting markdown parsing test\n");
    printf("==========================================\n");
    
    // Test markdown content with comprehensive features
    const char* markdown = 
        "# Main Header\n"
        "## Sub Header\n"
        "### Level 3 Header\n"
        "\n"
        "This is a **bold** text and *italic* text.\n"
        "You can also use __bold__ and _italic_ syntax.\n"
        "\n"
        "Here's some `inline code` and a [link](https://github.com/mity/md4c).\n"
        "\n"
        "## Code Block\n"
        "```javascript\n"
        "function hello() {\n"
        "    console.log('Hello, World!');\n"
        "}\n"
        "```\n"
        "\n"
        "## Lists\n"
        "### Unordered List\n"
        "- Item 1\n"
        "- Item 2\n"
        "  - Nested item 2.1\n"
        "  - Nested item 2.2\n"
        "- Item 3\n"
        "\n"
        "### Ordered List\n"
        "1. First item\n"
        "2. Second item\n"
        "   1. Nested numbered item\n"
        "   2. Another nested item\n"
        "3. Third item\n"
        "\n"
        "## Blockquote\n"
        "> This is a blockquote.\n"
        "> It can span multiple lines.\n"
        "> \n"
        "> > Nested blockquote\n"
        "\n"
        "## Tables\n"
        "| Header 1 | Header 2 | Header 3 |\n"
        "|----------|----------|----------|\n"
        "| Cell 1   | Cell 2   | Cell 3   |\n"
        "| Cell 4   | Cell 5   | Cell 6   |\n"
        "\n"
        "## Task Lists\n"
        "- [x] Completed task\n"
        "- [ ] Incomplete task\n"
        "- [x] Another completed task\n"
        "\n"
        "## Strikethrough and Emphasis\n"
        "This text has ~~strikethrough~~ and ***bold italic*** text.\n"
        "\n"
        "## Horizontal Rule\n"
        "---\n"
        "\n"
        "## Links and Images\n"
        "Here's an [external link](https://example.com) and an ![image](https://example.com/image.png).\n"
        "\n"
        "## Auto-links\n"
        "Visit https://github.com/mity/md4c for more info.\n"
        "Email me at test@example.com for questions.\n"
        "\n"
        "## Line Breaks\n"
        "This line has two spaces at the end.  \n"
        "This creates a line break.\n"
        "\n"
        "This line has a backslash at the end.\\\n"
        "This also creates a line break.\n"
        "\n"
        "## Final Test\n"
        "This is the end of our comprehensive markdown test! 🎉";
    
    printf("Input markdown:\n%s\n\n", markdown);
    printf("Parsing results:\n");
    printf("================\n");
    
    // Set up MD4C parser
    MD_PARSER parser = {0};
    parser.abi_version = 0;
    parser.flags = MD_FLAG_TABLES | MD_FLAG_TASKLISTS | MD_FLAG_STRIKETHROUGH | 
                   MD_FLAG_PERMISSIVEURLAUTOLINKS | MD_FLAG_PERMISSIVEEMAILAUTOLINKS | 
                   MD_FLAG_PERMISSIVEWWWAUTOLINKS;
    parser.enter_block = enter_block_callback;
    parser.leave_block = leave_block_callback;
    parser.enter_span = enter_span_callback;
    parser.leave_span = leave_span_callback;
    parser.text = text_callback;
    parser.debug_log = NULL;
    parser.syntax = NULL;
    
    // Parse the markdown
    int result = md_parse((MD_CHAR*)markdown, strlen(markdown), &parser, NULL);
    
    printf("\nParse result: %d (0 = success)\n", result);
    
    if (result == 0) {
        printf("✅ MD4C parsing successful!\n");
    } else {
        printf("❌ MD4C parsing failed!\n");
    }
    
    return result;
}

// Block callbacks
static int enter_block_callback(MD_BLOCKTYPE type, void* detail, void* userdata) {
    (void)userdata; // Suppress unused parameter warning
    switch (type) {
        case MD_BLOCK_H:
            printf("📝 Entering header (level %d)\n", ((MD_BLOCK_H_DETAIL*)detail)->level);
            break;
        case MD_BLOCK_P:
            printf("📝 Entering paragraph\n");
            break;
        case MD_BLOCK_UL:
            printf("📝 Entering unordered list\n");
            break;
        case MD_BLOCK_OL:
            printf("📝 Entering ordered list\n");
            break;
        case MD_BLOCK_LI:
            printf("📝 Entering list item\n");
            break;
        case MD_BLOCK_CODE:
            printf("📝 Entering code block\n");
            break;
        case MD_BLOCK_QUOTE:
            printf("📝 Entering blockquote\n");
            break;
        case MD_BLOCK_TABLE:
            printf("📝 Entering table\n");
            break;
        case MD_BLOCK_THEAD:
            printf("📝 Entering table header\n");
            break;
        case MD_BLOCK_TBODY:
            printf("📝 Entering table body\n");
            break;
        case MD_BLOCK_TR:
            printf("📝 Entering table row\n");
            break;
        case MD_BLOCK_TH:
            printf("📝 Entering table header cell\n");
            break;
        case MD_BLOCK_TD:
            printf("📝 Entering table data cell\n");
            break;
        case MD_BLOCK_HR:
            printf("📝 Entering horizontal rule\n");
            break;
        default:
            printf("📝 Entering block type %d\n", type);
            break;
    }
    return 0;
}

static int leave_block_callback(MD_BLOCKTYPE type, void* detail, void* userdata) {
    (void)detail; (void)userdata; // Suppress unused parameter warnings
    switch (type) {
        case MD_BLOCK_H:
            printf("📝 Leaving header\n");
            break;
        case MD_BLOCK_P:
            printf("📝 Leaving paragraph\n");
            break;
        case MD_BLOCK_UL:
            printf("📝 Leaving unordered list\n");
            break;
        case MD_BLOCK_OL:
            printf("📝 Leaving ordered list\n");
            break;
        case MD_BLOCK_LI:
            printf("📝 Leaving list item\n");
            break;
        case MD_BLOCK_CODE:
            printf("📝 Leaving code block\n");
            break;
        case MD_BLOCK_QUOTE:
            printf("📝 Leaving blockquote\n");
            break;
        case MD_BLOCK_TABLE:
            printf("📝 Leaving table\n");
            break;
        case MD_BLOCK_THEAD:
            printf("📝 Leaving table header\n");
            break;
        case MD_BLOCK_TBODY:
            printf("📝 Leaving table body\n");
            break;
        case MD_BLOCK_TR:
            printf("📝 Leaving table row\n");
            break;
        case MD_BLOCK_TH:
            printf("📝 Leaving table header cell\n");
            break;
        case MD_BLOCK_TD:
            printf("📝 Leaving table data cell\n");
            break;
        case MD_BLOCK_HR:
            printf("📝 Leaving horizontal rule\n");
            break;
        default:
            printf("📝 Leaving block type %d\n", type);
            break;
    }
    return 0;
}

// Span callbacks
static int enter_span_callback(MD_SPANTYPE type, void* detail, void* userdata) {
    (void)userdata; // Suppress unused parameter warning
    switch (type) {
        case MD_SPAN_STRONG:
            printf("📝 Entering bold text\n");
            break;
        case MD_SPAN_EM:
            printf("📝 Entering italic text\n");
            break;
        case MD_SPAN_CODE:
            printf("📝 Entering inline code\n");
            break;
        case MD_SPAN_A:
            {
                MD_SPAN_A_DETAIL *a_detail = (MD_SPAN_A_DETAIL*)detail;
                char* url = malloc(a_detail->href.size + 1);
                if (url) {
                    memcpy(url, a_detail->href.text, a_detail->href.size);
                    url[a_detail->href.size] = '\0';
                    printf("📝 Entering link to: %s\n", url);
                    free(url);
                }
            }
            break;
        case MD_SPAN_IMG:
            {
                MD_SPAN_IMG_DETAIL *img_detail = (MD_SPAN_IMG_DETAIL*)detail;
                char* src = malloc(img_detail->src.size + 1);
                char* title = malloc(img_detail->title.size + 1);
                if (src) {
                    memcpy(src, img_detail->src.text, img_detail->src.size);
                    src[img_detail->src.size] = '\0';
                    printf("📝 Entering image: %s", src);
                    if (title) {
                        memcpy(title, img_detail->title.text, img_detail->title.size);
                        title[img_detail->title.size] = '\0';
                        printf(" (title: %s)", title);
                        free(title);
                    }
                    printf("\n");
                    free(src);
                }
            }
            break;
        case MD_SPAN_DEL:
            printf("📝 Entering strikethrough text\n");
            break;
        case MD_SPAN_U:
            printf("📝 Entering underlined text\n");
            break;
        default:
            printf("📝 Entering span type %d\n", type);
            break;
    }
    return 0;
}

static int leave_span_callback(MD_SPANTYPE type, void* detail, void* userdata) {
    (void)detail; (void)userdata; // Suppress unused parameter warnings
    switch (type) {
        case MD_SPAN_STRONG:
            printf("📝 Leaving bold text\n");
            break;
        case MD_SPAN_EM:
            printf("📝 Leaving italic text\n");
            break;
        case MD_SPAN_CODE:
            printf("📝 Leaving inline code\n");
            break;
        case MD_SPAN_A:
            printf("📝 Leaving link\n");
            break;
        case MD_SPAN_IMG:
            printf("📝 Leaving image\n");
            break;
        case MD_SPAN_DEL:
            printf("📝 Leaving strikethrough text\n");
            break;
        case MD_SPAN_U:
            printf("📝 Leaving underlined text\n");
            break;
        default:
            printf("📝 Leaving span type %d\n", type);
            break;
    }
    return 0;
}

// Text callback
static int text_callback(MD_TEXTTYPE type, const MD_CHAR* text, MD_SIZE size, void* userdata) {
    (void)userdata; // Suppress unused parameter warning
    // Create a null-terminated string for printing
    char* text_str = malloc(size + 1);
    if (text_str) {
        memcpy(text_str, text, size);
        text_str[size] = '\0';
        
        switch (type) {
            case MD_TEXT_NORMAL:
                printf("📝 Text: \"%s\"\n", text_str);
                break;
            case MD_TEXT_CODE:
                printf("📝 Code: \"%s\"\n", text_str);
                break;
            case MD_TEXT_HTML:
                printf("📝 HTML: \"%s\"\n", text_str);
                break;
            case MD_TEXT_ENTITY:
                printf("📝 Entity: \"%s\"\n", text_str);
                break;
            case MD_TEXT_BR:
                printf("📝 Line break\n");
                break;
            case MD_TEXT_SOFTBR:
                printf("📝 Soft break\n");
                break;
            default:
                printf("📝 Text type %d: \"%s\"\n", type, text_str);
                break;
        }
        
        free(text_str);
    }
    return 0;
}
