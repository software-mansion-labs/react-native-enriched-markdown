#include "MD4CParser.hpp"
#import "MarkdownASTNode.h"
#include "MarkdownASTNode.hpp"

// Convert C++ AST node to Objective-C AST node
static MarkdownASTNode *convertCppASTToObjC(std::shared_ptr<Markdown::MarkdownASTNode> cppNode)
{
  if (!cppNode) {
    return [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
  }

  // Convert C++ NodeType enum to Objective-C MarkdownNodeType
  MarkdownNodeType objcType;
  switch (cppNode->type) {
    case Markdown::NodeType::Document:
      objcType = MarkdownNodeTypeDocument;
      break;
    case Markdown::NodeType::Paragraph:
      objcType = MarkdownNodeTypeParagraph;
      break;
    case Markdown::NodeType::Text:
      objcType = MarkdownNodeTypeText;
      break;
    case Markdown::NodeType::Link:
      objcType = MarkdownNodeTypeLink;
      break;
    case Markdown::NodeType::Heading:
      objcType = MarkdownNodeTypeHeading;
      break;
    case Markdown::NodeType::LineBreak:
      objcType = MarkdownNodeTypeLineBreak;
      break;
    case Markdown::NodeType::Strong:
      objcType = MarkdownNodeTypeStrong;
      break;
    case Markdown::NodeType::Emphasis:
      objcType = MarkdownNodeTypeEmphasis;
      break;
    case Markdown::NodeType::Code:
      objcType = MarkdownNodeTypeCode;
      break;
    case Markdown::NodeType::Image:
      objcType = MarkdownNodeTypeImage;
      break;
    case Markdown::NodeType::Blockquote:
      objcType = MarkdownNodeTypeBlockquote;
      break;
    case Markdown::NodeType::UnorderedList:
      objcType = MarkdownNodeTypeUnorderedList;
      break;
    case Markdown::NodeType::OrderedList:
      objcType = MarkdownNodeTypeOrderedList;
      break;
    case Markdown::NodeType::ListItem:
      objcType = MarkdownNodeTypeListItem;
      break;
    case Markdown::NodeType::CodeBlock:
      objcType = MarkdownNodeTypeCodeBlock;
      break;
    case Markdown::NodeType::ThematicBreak:
      objcType = MarkdownNodeTypeThematicBreak;
      break;
  }

  MarkdownASTNode *objcNode = [[MarkdownASTNode alloc] initWithType:objcType];

  // Convert content
  if (!cppNode->content.empty()) {
    objcNode.content = [NSString stringWithUTF8String:cppNode->content.c_str()];
  }

  // Convert attributes
  for (const auto &[key, value] : cppNode->attributes) {
    NSString *objcKey = [NSString stringWithUTF8String:key.c_str()];
    NSString *objcValue = [NSString stringWithUTF8String:value.c_str()];
    [objcNode setAttribute:objcKey value:objcValue];
  }

  // Convert children recursively
  for (const auto &child : cppNode->children) {
    MarkdownASTNode *objcChild = convertCppASTToObjC(child);
    [objcNode addChild:objcChild];
  }

  return objcNode;
}

// Public function to parse markdown using C++ parser and convert to Objective-C AST
MarkdownASTNode *parseMarkdownWithCppParser(NSString *markdown)
{
  if (markdown.length == 0) {
    return [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
  }

  // Convert NSString to std::string
  const char *utf8String = [markdown UTF8String];
  if (!utf8String) {
    NSLog(@"MarkdownParserBridge: Failed to convert markdown to UTF-8");
    return [[MarkdownASTNode alloc] initWithType:MarkdownNodeTypeDocument];
  }

  std::string cppMarkdown(utf8String);

  // Parse using C++ parser
  Markdown::MD4CParser parser;
  auto cppAST = parser.parse(cppMarkdown);

  // Convert C++ AST to Objective-C AST
  return convertCppASTToObjC(cppAST);
}
