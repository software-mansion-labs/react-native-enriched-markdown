#import "StreamingMarkdownFilter.h"

static BOOL ENRMLineIsBlank(NSString *line)
{
  return [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0;
}

static BOOL ENRMLineIsBlockMathDelimiter(NSString *line)
{
  return [[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@"$$"];
}

static BOOL ENRMLineLooksLikeTableRow(NSString *line)
{
  NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  return [trimmed hasPrefix:@"|"] && [trimmed containsString:@"|"];
}

static NSUInteger ENRMLineStartOffset(NSArray<NSString *> *lines, NSUInteger lineIndex)
{
  NSUInteger offset = 0;
  for (NSUInteger i = 0; i < lineIndex; i++) {
    offset += lines[i].length;
    offset += 1;
  }
  return offset;
}

static NSString *ENRMRemovePendingStreamingMathBlock(NSString *markdown)
{
  NSArray<NSString *> *lines = [markdown componentsSeparatedByString:@"\n"];
  NSInteger lastUnclosedDelimiterIndex = -1;

  for (NSUInteger i = 0; i < lines.count; i++) {
    if (ENRMLineIsBlockMathDelimiter(lines[i])) {
      lastUnclosedDelimiterIndex = lastUnclosedDelimiterIndex == -1 ? (NSInteger)i : -1;
    }
  }

  if (lastUnclosedDelimiterIndex == -1) {
    return markdown;
  }

  NSUInteger offset = ENRMLineStartOffset(lines, (NSUInteger)lastUnclosedDelimiterIndex);
  return [markdown substringToIndex:offset];
}

static NSString *ENRMRemovePendingStreamingTableBlock(NSString *markdown)
{
  NSArray<NSString *> *lines = [markdown componentsSeparatedByString:@"\n"];
  NSInteger lastNonBlankLineIndex = -1;

  for (NSInteger i = (NSInteger)lines.count - 1; i >= 0; i--) {
    if (!ENRMLineIsBlank(lines[(NSUInteger)i])) {
      lastNonBlankLineIndex = i;
      break;
    }
  }

  if (lastNonBlankLineIndex == -1) {
    return markdown;
  }

  // During streaming, treat a trailing table as complete only after a blank
  // separator line. A single trailing newline can still be followed by more rows.
  if ((NSUInteger)lastNonBlankLineIndex + 1 < lines.count - 1) {
    return markdown;
  }

  NSInteger blockStartIndex = lastNonBlankLineIndex;
  while (blockStartIndex > 0 && !ENRMLineIsBlank(lines[(NSUInteger)blockStartIndex - 1])) {
    blockStartIndex--;
  }

  BOOL blockLooksLikeTable = NO;
  for (NSInteger i = blockStartIndex; i <= lastNonBlankLineIndex; i++) {
    NSString *line = lines[(NSUInteger)i];
    if (!ENRMLineLooksLikeTableRow(line)) {
      return markdown;
    }
    blockLooksLikeTable = YES;
  }

  if (!blockLooksLikeTable) {
    return markdown;
  }

  NSUInteger offset = ENRMLineStartOffset(lines, (NSUInteger)blockStartIndex);
  return [markdown substringToIndex:offset];
}

NSString *ENRMRenderableMarkdownForStreaming(NSString *markdown)
{
  NSString *withoutPendingMath = ENRMRemovePendingStreamingMathBlock(markdown);
  return ENRMRemovePendingStreamingTableBlock(withoutPendingMath);
}
