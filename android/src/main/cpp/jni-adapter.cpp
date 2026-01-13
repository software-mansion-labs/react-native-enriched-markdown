#include "MD4CParser.hpp"
#include <android/log.h>
#include <jni.h>
#include <string>

using namespace Markdown;

#define ENRICHEDMARKDOWN_LOG_TAG "EnrichedMarkdownJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, ENRICHEDMARKDOWN_LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, ENRICHEDMARKDOWN_LOG_TAG, __VA_ARGS__)

// Helper function to convert C++ NodeType to Kotlin enum ordinal
static jint nodeTypeToJavaOrdinal(NodeType type) {
  switch (type) {
    case NodeType::Document:
      return 0;
    case NodeType::Paragraph:
      return 1;
    case NodeType::Text:
      return 2;
    case NodeType::Link:
      return 3;
    case NodeType::Heading:
      return 4;
    case NodeType::LineBreak:
      return 5;
    case NodeType::Strong:
      return 6;
    case NodeType::Emphasis:
      return 7;
    case NodeType::Code:
      return 8;
    case NodeType::Image:
      return 9;
    case NodeType::Blockquote:
      return 10;
    case NodeType::UnorderedList:
      return 11;
    case NodeType::OrderedList:
      return 12;
    case NodeType::ListItem:
      return 13;
    case NodeType::CodeBlock:
      return 14;
    default:
      return 0;
  }
}

// Helper function to create a Kotlin MarkdownASTNode object from C++ AST node
static jobject createJavaNode(JNIEnv *env, std::shared_ptr<MarkdownASTNode> node) {
  if (!node) {
    return nullptr;
  }

  // Find the MarkdownASTNode class
  jclass nodeClass = env->FindClass("com/swmansion/enriched/markdown/parser/MarkdownASTNode");
  if (!nodeClass) {
    LOGE("Failed to find MarkdownASTNode class");
    return nullptr;
  }

  // Find the NodeType enum class
  jclass nodeTypeClass = env->FindClass("com/swmansion/enriched/markdown/parser/MarkdownASTNode$NodeType");
  if (!nodeTypeClass) {
    LOGE("Failed to find NodeType enum class");
    return nullptr;
  }

  // Get the enum values array
  jmethodID valuesMethod = env->GetStaticMethodID(
      nodeTypeClass, "values", "()[Lcom/swmansion/enriched/markdown/parser/MarkdownASTNode$NodeType;");
  if (!valuesMethod) {
    LOGE("Failed to find NodeType.values() method");
    return nullptr;
  }

  jobjectArray enumValues = (jobjectArray)env->CallStaticObjectMethod(nodeTypeClass, valuesMethod);
  if (!enumValues) {
    LOGE("Failed to get NodeType enum values");
    return nullptr;
  }

  // Get the enum value for this node type
  jint ordinal = nodeTypeToJavaOrdinal(node->type);
  jobject nodeTypeEnum = env->GetObjectArrayElement(enumValues, ordinal);
  if (!nodeTypeEnum) {
    LOGE("Failed to get NodeType enum value at index %d", ordinal);
    return nullptr;
  }

  // Create content string
  jstring contentStr = env->NewStringUTF(node->content.c_str());
  if (!contentStr && !node->content.empty()) {
    LOGE("Failed to create content string");
    return nullptr;
  }

  // Create attributes HashMap
  jclass mapClass = env->FindClass("java/util/HashMap");
  jmethodID mapInit = env->GetMethodID(mapClass, "<init>", "(I)V");
  jmethodID mapPut = env->GetMethodID(mapClass, "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");

  jobject attributesMap = env->NewObject(mapClass, mapInit, static_cast<jint>(node->attributes.size()));

  for (const auto &pair : node->attributes) {
    jstring key = env->NewStringUTF(pair.first.c_str());
    jstring value = env->NewStringUTF(pair.second.c_str());
    env->CallObjectMethod(attributesMap, mapPut, key, value);
    env->DeleteLocalRef(key);
    env->DeleteLocalRef(value);
  }

  // Create children ArrayList
  jclass listClass = env->FindClass("java/util/ArrayList");
  jmethodID listInit = env->GetMethodID(listClass, "<init>", "(I)V");
  jmethodID listAdd = env->GetMethodID(listClass, "add", "(Ljava/lang/Object;)Z");

  jobject childrenList = env->NewObject(listClass, listInit, static_cast<jint>(node->children.size()));

  for (const auto &child : node->children) {
    jobject childObj = createJavaNode(env, child);
    if (childObj) {
      env->CallBooleanMethod(childrenList, listAdd, childObj);
      env->DeleteLocalRef(childObj);
    }
  }

  // Find the MarkdownASTNode constructor
  // Constructor signature: (Lcom/swmansion/enriched/markdown/parser/MarkdownASTNode$NodeType;Ljava/lang/String;Ljava/util/Map;Ljava/util/List;)V
  jmethodID constructor = env->GetMethodID(nodeClass, "<init>",
                                           "(Lcom/swmansion/enriched/markdown/parser/MarkdownASTNode$NodeType;Ljava/"
                                           "lang/String;Ljava/util/Map;Ljava/util/List;)V");
  if (!constructor) {
    LOGE("Failed to find MarkdownASTNode constructor");
    return nullptr;
  }

  // Create the Kotlin MarkdownASTNode object
  jobject javaNode = env->NewObject(nodeClass, constructor, nodeTypeEnum, contentStr, attributesMap, childrenList);

  // Clean up local references
  env->DeleteLocalRef(nodeTypeClass);
  env->DeleteLocalRef(enumValues);
  env->DeleteLocalRef(nodeTypeEnum);
  if (contentStr)
    env->DeleteLocalRef(contentStr);
  env->DeleteLocalRef(attributesMap);
  env->DeleteLocalRef(childrenList);

  return javaNode;
}

extern "C" {

JNIEXPORT jobject JNICALL Java_com_swmansion_enriched_markdown_parser_Parser_nativeParseMarkdown(JNIEnv *env,
                                                                                                 jobject /* this */,
                                                                                                 jstring markdown) {
  if (!markdown) {
    LOGE("Markdown string is null");
    return nullptr;
  }

  const char *markdownStr = env->GetStringUTFChars(markdown, nullptr);
  if (!markdownStr) {
    LOGE("Failed to get UTF-8 chars from markdown string");
    return nullptr;
  }

  try {
    // Parse markdown using C++ MD4CParser
    MD4CParser parser;
    auto ast = parser.parse(std::string(markdownStr));

    env->ReleaseStringUTFChars(markdown, markdownStr);

    if (!ast) {
      LOGE("Parser returned null AST");
      return nullptr;
    }

    // Convert C++ AST to Kotlin MarkdownASTNode object
    jobject javaNode = createJavaNode(env, ast);

    if (!javaNode) {
      LOGE("Failed to create Java node from AST");
    }

    return javaNode;
  } catch (const std::exception &e) {
    env->ReleaseStringUTFChars(markdown, markdownStr);
    LOGE("Exception during parsing: %s", e.what());
    return nullptr;
  } catch (...) {
    env->ReleaseStringUTFChars(markdown, markdownStr);
    LOGE("Unknown exception during parsing");
    return nullptr;
  }
}

} // extern "C"
