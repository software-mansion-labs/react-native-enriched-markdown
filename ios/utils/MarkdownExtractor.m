#import "MarkdownExtractor.h"
#import "BlockquoteBorder.h"
#import "CodeBlockBackground.h"
#import "ImageAttachment.h"
#import "RuntimeKeys.h"

#pragma mark - Extraction Context

/**
 * Holds state during markdown extraction to avoid many __block variables.
 */
typedef struct {
  NSInteger blockquoteDepth; // -1 = not in blockquote
  NSInteger listDepth;       // -1 = not in list
  BOOL needsBlankLine;       // True after block elements (heading, image, code block)
} ExtractionState;

#pragma mark - Helper Functions

/**
 * Ensures exactly one blank line at the end of result (for block separation).
 */
static void ensureBlankLine(NSMutableString *result)
{
  if (result.length == 0)
    return;
  if ([result hasSuffix:@"\n\n"])
    return;

  [result appendString:[result hasSuffix:@"\n"] ? @"\n" : @"\n\n"];
}

/**
 * Checks if result is at a line start (empty or ends with newline).
 */
static BOOL isAtLineStart(NSMutableString *result)
{
  return result.length == 0 || [result hasSuffix:@"\n"];
}

/**
 * Builds blockquote prefix string for given depth.
 * Depth 0 = "> ", Depth 1 = "> > ", etc.
 */
static NSString *buildBlockquotePrefix(NSInteger depth)
{
  NSMutableString *prefix = [NSMutableString string];
  for (NSInteger i = 0; i <= depth; i++) {
    [prefix appendString:@"> "];
  }
  return prefix;
}

/**
 * Builds list item prefix with indentation and marker.
 */
static NSString *buildListPrefix(NSInteger depth, BOOL isOrdered, NSInteger itemNumber)
{
  NSString *indent = [@"" stringByPaddingToLength:(depth * 2) withString:@" " startingAtIndex:0];
  NSString *marker = isOrdered ? [NSString stringWithFormat:@"%ld.", (long)itemNumber] : @"-";
  return [NSString stringWithFormat:@"%@%@ ", indent, marker];
}

/**
 * Builds heading prefix (e.g., "## " for level 2).
 */
static NSString *buildHeadingPrefix(NSInteger level)
{
  return [NSString stringWithFormat:@"%@ ", [@"" stringByPaddingToLength:level withString:@"#" startingAtIndex:0]];
}

/**
 * Extracts font traits from attributes.
 */
static void extractFontTraits(NSDictionary *attrs, BOOL *isBold, BOOL *isItalic, BOOL *isMonospace)
{
  UIFont *font = attrs[NSFontAttributeName];
  *isBold = NO;
  *isItalic = NO;
  *isMonospace = NO;

  if (font) {
    UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
    *isBold = (traits & UIFontDescriptorTraitBold) != 0;
    *isItalic = (traits & UIFontDescriptorTraitItalic) != 0;
    *isMonospace = (traits & UIFontDescriptorTraitMonoSpace) != 0;
  }
}

/**
 * Applies inline markdown formatting (bold, italic, code, link) to text.
 */
static NSString *applyInlineFormatting(NSString *text, BOOL isBold, BOOL isItalic, BOOL isMonospace, NSString *linkURL)
{
  NSMutableString *result = [NSMutableString stringWithString:text];

  // Apply innermost formatting first
  if (isMonospace && !linkURL) {
    result = [NSMutableString stringWithFormat:@"`%@`", result];
  }
  if (isItalic) {
    result = [NSMutableString stringWithFormat:@"*%@*", result];
  }
  if (isBold) {
    result = [NSMutableString stringWithFormat:@"**%@**", result];
  }
  if (linkURL) {
    result = [NSMutableString stringWithFormat:@"[%@](%@)", text, linkURL];
  }

  return result;
}

#pragma mark - Main Extraction Function

/**
 * Extracts markdown from attributed string attributes within a given range.
 * Best-effort reconstruction - may not match original exactly.
 *
 * Supports: headings, bold, italic, links, images, inline code,
 * code blocks, blockquotes, and lists.
 */
NSString *_Nullable extractMarkdownFromAttributedString(NSAttributedString *attributedText, NSRange range)
{
  // Validate input
  if (!attributedText || range.length == 0 || range.location >= attributedText.length) {
    return nil;
  }

  // Clamp range to valid bounds
  range.length = MIN(range.length, attributedText.length - range.location);

  NSMutableString *result = [NSMutableString string];

  // Heading accumulator (headings may span multiple attribute runs)
  __block NSString *currentHeadingType = nil;
  __block NSMutableString *headingContent = nil;

  // Extraction state
  __block ExtractionState state = {.blockquoteDepth = -1, .listDepth = -1, .needsBlankLine = NO};

  // Helper to flush accumulated heading content
  void (^flushHeading)(void) = ^{
    if (!currentHeadingType || headingContent.length == 0)
      return;

    ensureBlankLine(result);
    NSInteger level = [[currentHeadingType substringFromIndex:8] integerValue];
    [result appendFormat:@"%@%@\n", buildHeadingPrefix(level), headingContent];

    currentHeadingType = nil;
    headingContent = nil;
    state.needsBlankLine = YES;
  };

  // Process each attribute run
  [attributedText
      enumerateAttributesInRange:range
                         options:0
                      usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange attrRange, BOOL *stop) {
                        NSString *text = [[attributedText attributedSubstringFromRange:attrRange] string];
                        if (text.length == 0)
                          return;

                        // ─────────────────────────────────────────────────────────────────────────
                        // IMAGES
                        // ─────────────────────────────────────────────────────────────────────────
                        NSTextAttachment *attachment = attrs[NSAttachmentAttributeName];
                        if ([attachment isKindOfClass:[ImageAttachment class]]) {
                          ImageAttachment *img = (ImageAttachment *)attachment;
                          if (!img.imageURL)
                            return;

                          if (img.isInline) {
                            // Inline: no spacing, stays with surrounding text
                            [result appendFormat:@"![image](%@)", img.imageURL];
                          } else {
                            // Block: ensure spacing around it
                            ensureBlankLine(result);
                            [result appendFormat:@"![image](%@)\n", img.imageURL];
                            state.needsBlankLine = YES;
                            state.blockquoteDepth = -1;
                            state.listDepth = -1;
                          }
                          return;
                        }

                        // Skip object replacement character (placeholder for attachments)
                        if ([text isEqualToString:@"\uFFFC"])
                          return;

                        // ─────────────────────────────────────────────────────────────────────────
                        // NEWLINES (paragraph breaks)
                        // ─────────────────────────────────────────────────────────────────────────
                        if ([text isEqualToString:@"\n"] || [text isEqualToString:@"\n\n"]) {
                          NSNumber *bqDepth = attrs[RichTextBlockquoteDepthAttributeName];
                          NSNumber *listDepth = attrs[@"ListDepth"];
                          BOOL inBlockquote = (bqDepth != nil);
                          BOOL inList = (listDepth != nil);

                          // Exiting blockquote → blank line between blocks
                          if (!inBlockquote && state.blockquoteDepth >= 0) {
                            ensureBlankLine(result);
                            state.blockquoteDepth = -1;
                            return;
                          }

                          // Exiting list → blank line between blocks
                          if (!inList && state.listDepth >= 0) {
                            ensureBlankLine(result);
                            state.listDepth = -1;
                            return;
                          }

                          // Inside blockquote or list → single newline (prefix added on next line)
                          if (inBlockquote || inList) {
                            if (![result hasSuffix:@"\n"]) {
                              [result appendString:@"\n"];
                            }
                            return;
                          }

                          // Outside blocks → blank line for paragraph separation
                          ensureBlankLine(result);
                          return;
                        }

                        // ─────────────────────────────────────────────────────────────────────────
                        // HEADINGS
                        // ─────────────────────────────────────────────────────────────────────────
                        NSString *markdownType = attrs[MarkdownTypeAttributeName];

                        if (markdownType && [markdownType hasPrefix:@"heading-"]) {
                          // Starting a new heading or continuing current one
                          if (![markdownType isEqualToString:currentHeadingType]) {
                            flushHeading();
                            currentHeadingType = markdownType;
                            headingContent = [NSMutableString string];
                          }
                          // Accumulate content (strip trailing newlines)
                          [headingContent
                              appendString:[text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
                          return;
                        } else if (currentHeadingType) {
                          // Exiting heading → flush it
                          flushHeading();
                        }

                        // ─────────────────────────────────────────────────────────────────────────
                        // CODE BLOCKS
                        // ─────────────────────────────────────────────────────────────────────────
                        NSNumber *isCodeBlock = attrs[CodeBlockAttributeName];
                        if ([isCodeBlock boolValue]) {
                          if (state.needsBlankLine) {
                            ensureBlankLine(result);
                            state.needsBlankLine = NO;
                          }

                          BOOL needsFence = (result.length == 0) || [result hasSuffix:@"\n\n"];
                          if (needsFence) {
                            [result appendString:@"```\n"];
                          }

                          [result appendString:text];

                          if ([text hasSuffix:@"\n"]) {
                            [result appendString:@"```\n"];
                            state.needsBlankLine = YES;
                          }
                          return;
                        }

                        // ─────────────────────────────────────────────────────────────────────────
                        // BLOCKQUOTES - detect and track depth
                        // ─────────────────────────────────────────────────────────────────────────
                        NSNumber *bqDepthNum = attrs[RichTextBlockquoteDepthAttributeName];
                        NSInteger currentBqDepth = bqDepthNum ? [bqDepthNum integerValue] : -1;
                        NSString *blockquotePrefix = nil;

                        if (currentBqDepth >= 0) {
                          blockquotePrefix = buildBlockquotePrefix(currentBqDepth);
                          state.blockquoteDepth = currentBqDepth;
                        } else if (state.blockquoteDepth >= 0) {
                          // Exiting blockquote
                          ensureBlankLine(result);
                          state.blockquoteDepth = -1;
                        }

                        // ─────────────────────────────────────────────────────────────────────────
                        // LISTS - detect and track depth
                        // ─────────────────────────────────────────────────────────────────────────
                        NSNumber *listDepthNum = attrs[@"ListDepth"];
                        NSNumber *listTypeNum = attrs[@"ListType"];
                        NSNumber *listItemNum = attrs[@"ListItemNumber"];
                        NSInteger currentListDepth = listDepthNum ? [listDepthNum integerValue] : -1;

                        if (currentListDepth >= 0) {
                          state.listDepth = currentListDepth;
                        } else if (state.listDepth >= 0) {
                          // Exiting list
                          ensureBlankLine(result);
                          state.listDepth = -1;
                        }

                        // ─────────────────────────────────────────────────────────────────────────
                        // BUILD SEGMENT WITH INLINE FORMATTING
                        // ─────────────────────────────────────────────────────────────────────────
                        BOOL isBold, isItalic, isMonospace;
                        extractFontTraits(attrs, &isBold, &isItalic, &isMonospace);

                        NSString *linkURL = attrs[NSLinkAttributeName];
                        NSString *segment = applyInlineFormatting(text, isBold, isItalic, isMonospace, linkURL);

                        // ─────────────────────────────────────────────────────────────────────────
                        // ADD BLOCK PREFIXES (list markers, blockquote ">")
                        // ─────────────────────────────────────────────────────────────────────────
                        if (isAtLineStart(result)) {
                          NSMutableString *prefixedSegment = [NSMutableString string];

                          // List prefix
                          if (listDepthNum && ![text hasPrefix:@"\n"]) {
                            BOOL isOrdered = ([listTypeNum integerValue] == 1);
                            NSInteger itemNumber = listItemNum ? [listItemNum integerValue] : 1;
                            [prefixedSegment appendString:buildListPrefix(currentListDepth, isOrdered, itemNumber)];
                          }

                          // Blockquote prefix
                          if (blockquotePrefix) {
                            [prefixedSegment insertString:blockquotePrefix atIndex:0];
                          }

                          [prefixedSegment appendString:segment];
                          segment = prefixedSegment;
                        }

                        // ─────────────────────────────────────────────────────────────────────────
                        // APPEND SEGMENT TO RESULT
                        // ─────────────────────────────────────────────────────────────────────────
                        if (state.needsBlankLine && result.length > 0) {
                          ensureBlankLine(result);
                          state.needsBlankLine = NO;
                        }

                        [result appendString:segment];
                      }];

  // Flush any remaining heading at end of selection
  if (currentHeadingType && headingContent.length > 0) {
    ensureBlankLine(result);
    NSInteger level = [[currentHeadingType substringFromIndex:8] integerValue];
    [result appendFormat:@"%@%@\n", buildHeadingPrefix(level), headingContent];
  }

  return result.length > 0 ? result : nil;
}
