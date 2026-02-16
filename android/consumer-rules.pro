# ============================================================================
# ProGuard/R8 consumer rules for react-native-enriched-markdown
# These rules are automatically applied to consuming apps when R8/ProGuard
# is enabled (e.g. EAS Expo production builds).
# ============================================================================

# --------------------------------------------------------------------------
# JNI: Classes and members accessed from native code via FindClass/GetFieldID
# R8 cannot trace JNI string-based lookups, so these MUST be kept as-is.
# --------------------------------------------------------------------------
-keep class com.swmansion.enriched.markdown.parser.MarkdownASTNode { *; }
-keep class com.swmansion.enriched.markdown.parser.MarkdownASTNode$NodeType { *; }
-keep class com.swmansion.enriched.markdown.parser.Md4cFlags { *; }
-keep class com.swmansion.enriched.markdown.parser.Parser { *; }

# --------------------------------------------------------------------------
# React Native Fabric: ViewManager, Package, and codegen delegates
# These are resolved by reflection at runtime.
# --------------------------------------------------------------------------
-keep class com.swmansion.enriched.markdown.EnrichedMarkdownTextPackage { *; }
-keep class com.swmansion.enriched.markdown.EnrichedMarkdownTextManager { *; }
-keep class com.swmansion.enriched.markdown.EnrichedMarkdownText { *; }
-keep class com.swmansion.enriched.markdown.EnrichedMarkdownTextLayoutManager { *; }
-keep class com.swmansion.enriched.markdown.MeasurementStore { *; }

# --------------------------------------------------------------------------
# Events: Dispatched by name via React Native's event system
# --------------------------------------------------------------------------
-keep class com.swmansion.enriched.markdown.events.** { *; }

# --------------------------------------------------------------------------
# Renderer, Spans, and Styles: Core rendering pipeline
# Spans are set on SpannableStringBuilder and read back by the system
# via instanceof checks — R8 must not rename or remove them.
# --------------------------------------------------------------------------
-keep class com.swmansion.enriched.markdown.renderer.** { *; }
-keep class com.swmansion.enriched.markdown.spans.** { *; }
-keep class com.swmansion.enriched.markdown.styles.** { *; }

# --------------------------------------------------------------------------
# Accessibility: Delegate set via ViewCompat — resolved reflectively
# --------------------------------------------------------------------------
-keep class com.swmansion.enriched.markdown.accessibility.** { *; }

# --------------------------------------------------------------------------
# Utilities: Movement methods, drawables, etc. referenced indirectly
# --------------------------------------------------------------------------
-keep class com.swmansion.enriched.markdown.utils.** { *; }

