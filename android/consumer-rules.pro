# ProGuard/R8 consumer rules for react-native-enriched-markdown
#
# JNI: Classes accessed from C++ (jni-adapter.cpp) via FindClass/GetFieldID.
# R8 cannot trace hardcoded string lookups in native code.

-keep class com.swmansion.enriched.markdown.parser.MarkdownASTNode { *; }
-keep class com.swmansion.enriched.markdown.parser.MarkdownASTNode$NodeType { *; }
-keep class com.swmansion.enriched.markdown.parser.Md4cFlags { *; }
