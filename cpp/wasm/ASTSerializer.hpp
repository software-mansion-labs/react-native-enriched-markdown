#pragma once

#include "../parser/MarkdownASTNode.hpp"
#include <string>

namespace Markdown {

// Serializes a MarkdownASTNode tree to a compact JSON string.
// Only non-empty fields are emitted: content, attributes, children.
class ASTSerializer {
public:
  static std::string serialize(const MarkdownASTNode &node);

private:
  static void serializeNode(const MarkdownASTNode &node, std::string &out);
  static void appendEscaped(const std::string &str, std::string &out);
};

} // namespace Markdown
