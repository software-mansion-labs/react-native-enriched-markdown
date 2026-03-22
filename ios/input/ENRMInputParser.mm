#import "ENRMInputParser.h"
#import "ENRMFormattingRange.h"
#import "ENRMInputRemend.h"
#include "md4c.h"
#include <string>
#include <vector>

@implementation ENRMParseResult
@end

namespace {

static const size_t kByteOffsetUnset = SIZE_MAX;

struct SpanTypeMapping {
  MD_SPANTYPE md4cType;
  ENRMInputStyleType styleType;
};

static const SpanTypeMapping kSupportedSpans[] = {
    {MD_SPAN_STRONG, ENRMInputStyleTypeStrong}, {MD_SPAN_EM, ENRMInputStyleTypeEmphasis},
    {MD_SPAN_U, ENRMInputStyleTypeUnderline},   {MD_SPAN_DEL, ENRMInputStyleTypeStrikethrough},
    {MD_SPAN_A, ENRMInputStyleTypeLink},
};
static const size_t kSupportedSpanCount = sizeof(kSupportedSpans) / sizeof(kSupportedSpans[0]);

static bool isSupportedSpan(MD_SPANTYPE md4cType, ENRMInputStyleType &outStyleType)
{
  for (size_t index = 0; index < kSupportedSpanCount; index++) {
    if (kSupportedSpans[index].md4cType == md4cType) {
      outStyleType = kSupportedSpans[index].styleType;
      return true;
    }
  }
  return false;
}

struct InlineSpanInfo {
  ENRMInputStyleType type;
  size_t openingDelimiterByteOffset;
  size_t contentStartByteOffset = kByteOffsetUnset;
  size_t contentEndByteOffset = kByteOffsetUnset;
  std::string linkURL;
};

struct ParseContext {
  const char *buffer;
  size_t bufferLength;
  size_t originalLength;
  std::vector<InlineSpanInfo> openStack;
  std::vector<InlineSpanInfo> resolved;
  size_t lastTextEnd = 0;
};

static std::vector<NSUInteger> buildByteToUTF16Map(const char *utf8, size_t byteLength)
{
  std::vector<NSUInteger> map(byteLength + 1, 0);
  NSUInteger utf16Index = 0;
  size_t byteIndex = 0;

  while (byteIndex < byteLength) {
    unsigned char leadByte = (unsigned char)utf8[byteIndex];
    size_t sequenceLength;
    uint32_t codepoint;

    if (leadByte < 0x80) {
      sequenceLength = 1;
      codepoint = leadByte;
    } else if ((leadByte & 0xE0) == 0xC0) {
      sequenceLength = 2;
      codepoint = leadByte & 0x1F;
    } else if ((leadByte & 0xF0) == 0xE0) {
      sequenceLength = 3;
      codepoint = leadByte & 0x0F;
    } else {
      sequenceLength = 4;
      codepoint = leadByte & 0x07;
    }

    for (size_t offset = 1; offset < sequenceLength && (byteIndex + offset) < byteLength; offset++) {
      codepoint = (codepoint << 6) | (utf8[byteIndex + offset] & 0x3F);
    }

    for (size_t offset = 0; offset < sequenceLength && (byteIndex + offset) <= byteLength; offset++) {
      map[byteIndex + offset] = utf16Index;
    }

    utf16Index += (codepoint > 0xFFFF) ? 2 : 1;
    byteIndex += sequenceLength;
  }

  map[byteLength] = utf16Index;
  return map;
}

static inline NSUInteger mapByteOffset(const std::vector<NSUInteger> &map, size_t offset, size_t maxOffset)
{
  return map[std::min(offset, maxOffset)];
}

static size_t closingDelimiterEndByte(const InlineSpanInfo &span, const char *utf8, size_t bufferLength)
{
  size_t position = span.contentEndByteOffset;
  switch (span.type) {
    case ENRMInputStyleTypeStrong:
      return position + 2;
    case ENRMInputStyleTypeEmphasis:
      return position + 1;
    case ENRMInputStyleTypeUnderline:
      return position + 1;
    case ENRMInputStyleTypeStrikethrough:
      return position + 2;
    case ENRMInputStyleTypeLink:
      while (position < bufferLength && utf8[position] != ')') {
        position++;
      }
      if (position < bufferLength) {
        position++;
      }
      return position;
  }
  return position;
}

static int onEnterBlock(MD_BLOCKTYPE, void *, void *)
{
  return 0;
}
static int onLeaveBlock(MD_BLOCKTYPE, void *, void *)
{
  return 0;
}

static int onEnterSpan(MD_SPANTYPE spanType, void *detail, void *userdata)
{
  ENRMInputStyleType styleType;
  if (!isSupportedSpan(spanType, styleType)) {
    return 0;
  }

  auto *context = static_cast<ParseContext *>(userdata);
  InlineSpanInfo spanInfo;
  spanInfo.type = styleType;
  spanInfo.openingDelimiterByteOffset = context->lastTextEnd;

  if (spanType == MD_SPAN_A && detail) {
    auto *linkDetail = static_cast<MD_SPAN_A_DETAIL *>(detail);
    if (linkDetail->href.text && linkDetail->href.size > 0) {
      spanInfo.linkURL = std::string(linkDetail->href.text, linkDetail->href.size);
    }
  }

  context->openStack.push_back(spanInfo);
  return 0;
}

static int onLeaveSpan(MD_SPANTYPE spanType, void *, void *userdata)
{
  ENRMInputStyleType unused;
  if (!isSupportedSpan(spanType, unused)) {
    return 0;
  }

  auto *context = static_cast<ParseContext *>(userdata);
  if (context->openStack.empty()) {
    return 0;
  }

  context->resolved.push_back(context->openStack.back());
  context->openStack.pop_back();
  return 0;
}

static int onText(MD_TEXTTYPE, const MD_CHAR *text, MD_SIZE size, void *userdata)
{
  if (!text || size == 0) {
    return 0;
  }
  auto *context = static_cast<ParseContext *>(userdata);
  size_t textStart = text - context->buffer;
  size_t textEnd = textStart + size;

  for (auto &openSpan : context->openStack) {
    if (openSpan.contentStartByteOffset == kByteOffsetUnset) {
      openSpan.contentStartByteOffset = textStart;
    }
    openSpan.contentEndByteOffset = textEnd;
  }
  context->lastTextEnd = textEnd;
  return 0;
}

static bool runMd4cParse(NSString *markdown, ParseContext &context)
{
  NSString *completed = ENRMInputRemendComplete(markdown);
  const char *completedUTF8 = [completed UTF8String];
  size_t completedLength = strlen(completedUTF8);
  size_t originalLength = [markdown lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

  context.buffer = completedUTF8;
  context.bufferLength = completedLength;
  context.originalLength = originalLength;

  MD_PARSER parser = {
      .abi_version = 0,
      .flags = MD_FLAG_NOHTML | MD_FLAG_PERMISSIVEAUTOLINKS | MD_FLAG_UNDERLINE | MD_FLAG_STRIKETHROUGH,
      .enter_block = onEnterBlock,
      .leave_block = onLeaveBlock,
      .enter_span = onEnterSpan,
      .leave_span = onLeaveSpan,
      .text = onText,
      .debug_log = nullptr,
      .syntax = nullptr,
  };

  return md_parse(completedUTF8, (MD_SIZE)completedLength, &parser, &context) == 0;
}

} // namespace

@implementation ENRMInputParser

- (NSArray<ENRMInputStyledRange *> *)parse:(NSString *)markdown
{
  if (markdown.length == 0) {
    return @[];
  }

  ParseContext context;
  if (!runMd4cParse(markdown, context)) {
    return @[];
  }

  auto byteMap = buildByteToUTF16Map(context.buffer, context.bufferLength);

  NSMutableArray<ENRMInputStyledRange *> *results = [NSMutableArray arrayWithCapacity:context.resolved.size()];

  for (const auto &spanInfo : context.resolved) {
    if (spanInfo.contentStartByteOffset == kByteOffsetUnset || spanInfo.contentEndByteOffset == kByteOffsetUnset ||
        spanInfo.contentStartByteOffset > context.originalLength) {
      continue;
    }

    ENRMInputStyledRange *styledRange = [[ENRMInputStyledRange alloc] init];
    styledRange.type = spanInfo.type;

    if (spanInfo.type == ENRMInputStyleTypeLink && !spanInfo.linkURL.empty()) {
      styledRange.url = [NSString stringWithUTF8String:spanInfo.linkURL.c_str()];
    }

    NSUInteger contentStart = mapByteOffset(byteMap, spanInfo.contentStartByteOffset, context.bufferLength);
    NSUInteger contentEnd = mapByteOffset(byteMap, spanInfo.contentEndByteOffset, context.originalLength);
    styledRange.contentRange = NSMakeRange(contentStart, contentEnd - contentStart);

    NSUInteger openStart = mapByteOffset(byteMap, spanInfo.openingDelimiterByteOffset, context.bufferLength);
    NSRange openingRange = NSMakeRange(openStart, contentStart - openStart);

    size_t closingEndByte =
        std::min(closingDelimiterEndByte(spanInfo, context.buffer, context.bufferLength), context.bufferLength);
    NSUInteger closingStart = mapByteOffset(byteMap, spanInfo.contentEndByteOffset, context.bufferLength);
    NSUInteger closingEnd = mapByteOffset(byteMap, closingEndByte, context.bufferLength);
    NSRange closingRange = NSMakeRange(closingStart, closingEnd - closingStart);

    styledRange.syntaxRanges = @[ [NSValue valueWithRange:openingRange], [NSValue valueWithRange:closingRange] ];

    NSUInteger fullStart = openingRange.location;
    NSUInteger fullEnd = NSMaxRange(closingRange);
    styledRange.fullRange = NSMakeRange(fullStart, fullEnd - fullStart);

    styledRange.isComplete = (closingEndByte <= context.originalLength);

    [results addObject:styledRange];
  }

  [results sortUsingComparator:^NSComparisonResult(ENRMInputStyledRange *first, ENRMInputStyledRange *second) {
    if (first.fullRange.location < second.fullRange.location)
      return NSOrderedAscending;
    if (first.fullRange.location > second.fullRange.location)
      return NSOrderedDescending;
    return NSOrderedSame;
  }];

  return results;
}

- (ENRMParseResult *)parseToPlainTextAndRanges:(NSString *)markdown
{
  ENRMParseResult *parseResult = [[ENRMParseResult alloc] init];

  if (markdown.length == 0) {
    parseResult.plainText = @"";
    parseResult.formattingRanges = @[];
    return parseResult;
  }

  NSArray<ENRMInputStyledRange *> *styledRanges = [self parse:markdown];

  NSMutableIndexSet *syntaxIndexes = [NSMutableIndexSet indexSet];
  for (ENRMInputStyledRange *styledRange in styledRanges) {
    if (!styledRange.isComplete)
      continue;
    for (NSValue *syntaxValue in styledRange.syntaxRanges) {
      [syntaxIndexes addIndexesInRange:[syntaxValue rangeValue]];
    }
  }

  NSUInteger rawLength = markdown.length;
  NSMutableString *plainText = [NSMutableString stringWithCapacity:rawLength];
  NSUInteger *rawToPlainMap = (NSUInteger *)malloc(sizeof(NSUInteger) * (rawLength + 1));
  if (!rawToPlainMap) {
    parseResult.plainText = markdown;
    parseResult.formattingRanges = @[];
    return parseResult;
  }

  __block NSUInteger plainPosition = 0;
  __block NSUInteger previousEnd = 0;

  [syntaxIndexes enumerateRangesUsingBlock:^(NSRange syntaxRange, BOOL *stop) {
    if (syntaxRange.location > previousEnd) {
      NSRange visibleRange = NSMakeRange(previousEnd, syntaxRange.location - previousEnd);
      [plainText appendString:[markdown substringWithRange:visibleRange]];
      for (NSUInteger rawIndex = previousEnd; rawIndex < syntaxRange.location; rawIndex++) {
        rawToPlainMap[rawIndex] = plainPosition++;
      }
    }
    for (NSUInteger rawIndex = syntaxRange.location; rawIndex < NSMaxRange(syntaxRange); rawIndex++) {
      rawToPlainMap[rawIndex] = plainPosition;
    }
    previousEnd = NSMaxRange(syntaxRange);
  }];

  if (previousEnd < rawLength) {
    [plainText appendString:[markdown substringFromIndex:previousEnd]];
    for (NSUInteger rawIndex = previousEnd; rawIndex < rawLength; rawIndex++) {
      rawToPlainMap[rawIndex] = plainPosition++;
    }
  }
  rawToPlainMap[rawLength] = plainPosition;

  NSMutableArray<ENRMFormattingRange *> *formattingRanges = [NSMutableArray arrayWithCapacity:styledRanges.count];

  for (ENRMInputStyledRange *styledRange in styledRanges) {
    if (!styledRange.isComplete)
      continue;

    NSUInteger contentStart = styledRange.contentRange.location;
    NSUInteger contentEnd = NSMaxRange(styledRange.contentRange);

    if (contentStart > rawLength || contentEnd > rawLength)
      continue;

    NSUInteger plainStart = rawToPlainMap[contentStart];
    NSUInteger plainEnd = rawToPlainMap[contentEnd];

    if (plainEnd <= plainStart)
      continue;

    ENRMFormattingRange *formattingRange =
        [ENRMFormattingRange rangeWithType:styledRange.type
                                     range:NSMakeRange(plainStart, plainEnd - plainStart)
                                       url:styledRange.url];
    [formattingRanges addObject:formattingRange];
  }

  free(rawToPlainMap);

  parseResult.plainText = plainText;
  parseResult.formattingRanges = formattingRanges;
  return parseResult;
}

@end
