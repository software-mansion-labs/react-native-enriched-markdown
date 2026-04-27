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

static NSUInteger ENRMPipeCount(NSString *line)
{
  NSUInteger count = 0;
  for (NSUInteger i = 0; i < line.length; i++) {
    if ([line characterAtIndex:i] == '|') {
      count++;
    }
  }
  return count;
}

static BOOL ENRMLineLooksLikeTableSeparator(NSString *line)
{
  NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if (trimmed.length == 0) {
    return NO;
  }
  if ([trimmed characterAtIndex:0] != '|') {
    return NO;
  }
  BOOL hasTripleDash = NO;
  NSUInteger dashRun = 0;
  for (NSUInteger i = 0; i < trimmed.length; i++) {
    unichar ch = [trimmed characterAtIndex:i];
    if (ch == '-') {
      dashRun++;
      if (dashRun >= 3) {
        hasTripleDash = YES;
      }
    } else {
      dashRun = 0;
      if (ch != '|' && ch != ':' && ch != ' ') {
        return NO;
      }
    }
  }
  return hasTripleDash;
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

static NSString *ENRMRemovePendingStreamingTableBlock(NSString *markdown, ENRMTableStreamingMode tableMode)
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

  if (tableMode == ENRMTableStreamingModeProgressive) {
    NSInteger tableLineCount = lastNonBlankLineIndex - blockStartIndex + 1;

    // Need at least header + separator to show anything.
    if (tableLineCount < 2 || !ENRMLineLooksLikeTableSeparator(lines[(NSUInteger)blockStartIndex + 1])) {
      NSUInteger offset = ENRMLineStartOffset(lines, (NSUInteger)blockStartIndex);
      return [markdown substringToIndex:offset];
    }

    // Trim the last data row if it's incomplete: either doesn't end with '|'
    // or has fewer pipe characters than the header (mid-cell streaming).
    if (tableLineCount > 2) {
      NSString *lastRow = lines[(NSUInteger)lastNonBlankLineIndex];
      NSString *lastRowTrimmed = [lastRow stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      NSString *headerRow = lines[(NSUInteger)blockStartIndex];
      if (![lastRowTrimmed hasSuffix:@"|"] || ENRMPipeCount(lastRow) < ENRMPipeCount(headerRow)) {
        NSUInteger offset = ENRMLineStartOffset(lines, (NSUInteger)lastNonBlankLineIndex);
        return [markdown substringToIndex:offset];
      }
    }

    return markdown;
  }

  NSUInteger offset = ENRMLineStartOffset(lines, (NSUInteger)blockStartIndex);
  return [markdown substringToIndex:offset];
}

NSString *ENRMRenderableMarkdownForStreaming(NSString *markdown, ENRMTableStreamingMode tableMode)
{
  NSString *withoutPendingMath = ENRMRemovePendingStreamingMathBlock(markdown);
  return ENRMRemovePendingStreamingTableBlock(withoutPendingMath, tableMode);
}
