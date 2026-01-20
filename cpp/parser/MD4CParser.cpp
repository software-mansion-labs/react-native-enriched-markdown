#include "MD4CParser.hpp"
#include "../md4c/md4c.h"
#include <cstring>
#include <vector>

namespace Markdown {

class MD4CParser::Impl {
public:
  std::shared_ptr<MarkdownASTNode> root;
  std::vector<std::shared_ptr<MarkdownASTNode>> nodeStack;
  std::string currentText;
  const char *inputText = nullptr;

  static const std::string ATTR_LEVEL;
  static const std::string ATTR_URL;
  static const std::string ATTR_TITLE;
  static const std::string ATTR_FENCE_CHAR;
  static const std::string ATTR_LANGUAGE;

  void reset(size_t estimatedDepth) {
    root = std::make_shared<MarkdownASTNode>(NodeType::Document);
    nodeStack.clear();
    // Reserve based on estimated depth, with reasonable bounds
    // Typical markdown has 5-15 levels, but can go deeper with nested structures
    // Cap at 128 to avoid excessive memory for extreme cases
    nodeStack.reserve(std::min(estimatedDepth, static_cast<size_t>(128)));
    nodeStack.push_back(root);
    currentText.clear();
    currentText.reserve(256);
  }

  void flushText() {
    if (!currentText.empty() && !nodeStack.empty()) {
      auto textNode = std::make_shared<MarkdownASTNode>(NodeType::Text);
      textNode->content = std::move(currentText);
      nodeStack.back()->addChild(std::move(textNode));
      currentText.clear();
    }
  }

  void pushNode(std::shared_ptr<MarkdownASTNode> node) {
    flushText();
    if (node && !nodeStack.empty()) {
      nodeStack.back()->addChild(node);
      nodeStack.push_back(std::move(node));
    }
  }

  void popNode() {
    flushText();
    if (nodeStack.size() > 1) {
      nodeStack.pop_back();
    }
  }

  void addInlineNode(std::shared_ptr<MarkdownASTNode> node) {
    if (node && !nodeStack.empty()) {
      nodeStack.back()->addChild(node);
    }
  }

  std::string getAttributeText(const MD_ATTRIBUTE *attr) {
    if (!attr || attr->size == 0 || !attr->text)
      return {};

    // Use string constructor directly - let SSO handle small strings efficiently
    // Empty return {} avoids allocating empty string object
    return std::string(attr->text, attr->size);
  }

  static int enterBlock(MD_BLOCKTYPE type, void *detail, void *userdata) {
    if (!userdata)
      return 1;
    auto *impl = static_cast<Impl *>(userdata);

    switch (type) {
      case MD_BLOCK_DOC:
        // Document node already created in reset()
        break;

      case MD_BLOCK_P: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::Paragraph));
        break;
      }

      case MD_BLOCK_H: {
        auto node = std::make_shared<MarkdownASTNode>(NodeType::Heading);
        if (detail) {
          auto *h = static_cast<MD_BLOCK_H_DETAIL *>(detail);
          int level = static_cast<int>(h->level);
          // Clamp level to valid range (1-6)
          level = (level < 1) ? 1 : (level > 6) ? 6 : level;
          // Use char conversion for small integers (1-6)
          // Avoids std::to_string() allocation overhead
          char levelStr[2] = {static_cast<char>('0' + level), '\0'};
          node->setAttribute(ATTR_LEVEL, levelStr);
        }
        impl->pushNode(node);
        break;
      }

      case MD_BLOCK_QUOTE: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::Blockquote));
        break;
      }

      case MD_BLOCK_UL: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::UnorderedList));
        break;
      }

      case MD_BLOCK_OL: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::OrderedList));
        break;
      }

      case MD_BLOCK_LI: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::ListItem));
        break;
      }

      case MD_BLOCK_CODE: {
        auto node = std::make_shared<MarkdownASTNode>(NodeType::CodeBlock);
        if (detail) {
          auto *codeDetail = static_cast<MD_BLOCK_CODE_DETAIL *>(detail);
          // Extract fence character (if fenced code block)
          if (codeDetail->fence_char != 0) {
            char fenceStr[2] = {static_cast<char>(codeDetail->fence_char), '\0'};
            node->setAttribute(ATTR_FENCE_CHAR, fenceStr);
          }
          // Extract language from lang attribute
          std::string lang = impl->getAttributeText(&codeDetail->lang);
          if (!lang.empty()) {
            node->setAttribute(ATTR_LANGUAGE, lang);
          }
        }
        impl->pushNode(node);
        break;
      }

      case MD_BLOCK_HR: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::ThematicBreak));
        break;
      }

      default:
        // Other block types not yet implemented
        break;
    }

    return 0;
  }

  static int leaveBlock(MD_BLOCKTYPE type, void *detail, void *userdata) {
    (void)detail;
    if (!userdata)
      return 1;
    auto *impl = static_cast<Impl *>(userdata);

    if (type != MD_BLOCK_DOC && !impl->nodeStack.empty()) {
      impl->popNode();
    }

    return 0;
  }

  static int enterSpan(MD_SPANTYPE type, void *detail, void *userdata) {
    if (!userdata)
      return 1;
    auto *impl = static_cast<Impl *>(userdata);

    switch (type) {
      case MD_SPAN_A: {
        auto node = std::make_shared<MarkdownASTNode>(NodeType::Link);
        if (detail) {
          auto *linkDetail = static_cast<MD_SPAN_A_DETAIL *>(detail);
          std::string url = impl->getAttributeText(&linkDetail->href);
          if (!url.empty()) {
            node->setAttribute(ATTR_URL, url);
          }
        }
        impl->pushNode(node);
        break;
      }

      case MD_SPAN_STRONG: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::Strong));
        break;
      }

      case MD_SPAN_EM: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::Emphasis));
        break;
      }

      case MD_SPAN_CODE: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::Code));
        break;
      }

      case MD_SPAN_DEL: {
        impl->pushNode(std::make_shared<MarkdownASTNode>(NodeType::Strikethrough));
        break;
      }

      case MD_SPAN_IMG: {
        auto node = std::make_shared<MarkdownASTNode>(NodeType::Image);
        if (detail) {
          auto *imgDetail = static_cast<MD_SPAN_IMG_DETAIL *>(detail);
          std::string url = impl->getAttributeText(&imgDetail->src);
          if (!url.empty()) {
            node->setAttribute(ATTR_URL, url);
          }
          std::string title = impl->getAttributeText(&imgDetail->title);
          if (!title.empty()) {
            node->setAttribute(ATTR_TITLE, title);
          }
        }
        impl->pushNode(node);
        break;
      }

      default:
        break;
    }

    return 0;
  }

  static int leaveSpan(MD_SPANTYPE type, void *detail, void *userdata) {
    (void)detail;
    if (!userdata)
      return 1;
    auto *impl = static_cast<Impl *>(userdata);

    if (!impl->nodeStack.empty()) {
      impl->popNode();
    }

    return 0;
  }

  static int text(MD_TEXTTYPE type, const MD_CHAR *text, MD_SIZE size, void *userdata) {
    if (!userdata || !text || size == 0)
      return 0;
    auto *impl = static_cast<Impl *>(userdata);

    // Handle soft/hard line breaks
    if (type == MD_TEXT_SOFTBR || type == MD_TEXT_BR) {
      auto brNode = std::make_shared<MarkdownASTNode>(NodeType::LineBreak);
      impl->addInlineNode(brNode);
      return 0;
    }

    // Handle text content (normal text, code text, etc.)
    if (type == MD_TEXT_NORMAL || type == MD_TEXT_CODE) {
      impl->currentText.append(text, size);
    }

    return 0;
  }
};

MD4CParser::MD4CParser() : impl_(std::make_unique<Impl>()) {}

MD4CParser::~MD4CParser() = default;

std::shared_ptr<MarkdownASTNode> MD4CParser::parse(const std::string &markdown) {
  if (markdown.empty()) {
    return std::make_shared<MarkdownASTNode>(NodeType::Document);
  }

  // Estimate stack depth based on markdown size
  // Heuristic: ~1 nesting level per 500-1000 characters for typical markdown
  // This is a rough estimate - actual depth depends on structure, not just size
  // Base depth of 12 covers typical nested structures (blockquotes, future lists)
  size_t estimatedDepth = 12; // Base depth for small documents
  if (markdown.size() > 1000) {
    // Scale up for larger documents, but cap the growth
    estimatedDepth = std::min(static_cast<size_t>(12 + (markdown.size() / 1000)), static_cast<size_t>(64));
  }

  impl_->reset(estimatedDepth);
  impl_->inputText = markdown.c_str();

  // Configure MD4C parser with callbacks
  MD_PARSER parser = {
      0,                                      // abi_version
      MD_FLAG_NOHTML | MD_FLAG_STRIKETHROUGH, // flags - disable HTML
      &Impl::enterBlock,
      &Impl::leaveBlock,
      &Impl::enterSpan,
      &Impl::leaveSpan,
      &Impl::text,
      nullptr, // debug_log
      nullptr  // syntax
  };

  // Parse the markdown
  int result = md_parse(markdown.c_str(), static_cast<MD_SIZE>(markdown.size()), &parser, impl_.get());

  if (result != 0) {
    // Parsing failed, return empty document
    return std::make_shared<MarkdownASTNode>(NodeType::Document);
  }

  impl_->flushText();
  return impl_->root ? impl_->root : std::make_shared<MarkdownASTNode>(NodeType::Document);
}

// Static member definitions
const std::string MD4CParser::Impl::ATTR_LEVEL = "level";
const std::string MD4CParser::Impl::ATTR_URL = "url";
const std::string MD4CParser::Impl::ATTR_TITLE = "title";
const std::string MD4CParser::Impl::ATTR_FENCE_CHAR = "fenceChar";
const std::string MD4CParser::Impl::ATTR_LANGUAGE = "language";

} // namespace Markdown
