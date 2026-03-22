#import "ENRMMarkdownSerializer.h"

static NSString *openingDelimiterForType(ENRMInputStyleType type)
{
  switch (type) {
    case ENRMInputStyleTypeStrong:
      return @"**";
    case ENRMInputStyleTypeEmphasis:
      return @"*";
    case ENRMInputStyleTypeUnderline:
      return @"_";
    case ENRMInputStyleTypeStrikethrough:
      return @"~~";
    case ENRMInputStyleTypeLink:
      return @"[";
    default:
      return @"";
  }
}

static NSString *closingDelimiterForType(ENRMInputStyleType type, NSString *url)
{
  switch (type) {
    case ENRMInputStyleTypeStrong:
      return @"**";
    case ENRMInputStyleTypeEmphasis:
      return @"*";
    case ENRMInputStyleTypeUnderline:
      return @"_";
    case ENRMInputStyleTypeStrikethrough:
      return @"~~";
    case ENRMInputStyleTypeLink:
      return [NSString stringWithFormat:@"](%@)", url ?: @""];
    default:
      return @"";
  }
}

/// Lower value = outermost wrapper. Font styles wrap around structural styles (link).
static int nestingPriorityForType(ENRMInputStyleType type)
{
  switch (type) {
    case ENRMInputStyleTypeEmphasis:
      return 0;
    case ENRMInputStyleTypeStrong:
      return 1;
    case ENRMInputStyleTypeUnderline:
      return 2;
    case ENRMInputStyleTypeStrikethrough:
      return 3;
    case ENRMInputStyleTypeLink:
      return 4;
    default:
      return 99;
  }
}

typedef struct {
  NSUInteger position;
  BOOL isOpening;
  ENRMInputStyleType type;
  NSString *__unsafe_unretained url;
} BoundaryEvent;

static int compareBoundaryEvents(const void *first, const void *second)
{
  const BoundaryEvent *eventA = (const BoundaryEvent *)first;
  const BoundaryEvent *eventB = (const BoundaryEvent *)second;

  if (eventA->position != eventB->position) {
    return eventA->position < eventB->position ? -1 : 1;
  }
  // Closing events before opening events at the same position
  if (eventA->isOpening != eventB->isOpening) {
    return eventA->isOpening ? 1 : -1;
  }
  // Among openings: outer first (lower priority emitted first)
  // Among closings: inner first (higher priority emitted first) — LIFO order
  int priorityA = nestingPriorityForType(eventA->type);
  int priorityB = nestingPriorityForType(eventB->type);
  if (eventA->isOpening) {
    return priorityA - priorityB;
  } else {
    return priorityB - priorityA;
  }
}

@implementation ENRMMarkdownSerializer

+ (NSString *)serializePlainText:(NSString *)text ranges:(NSArray<ENRMFormattingRange *> *)ranges
{
  if (ranges.count == 0) {
    return text;
  }

  NSUInteger textLength = text.length;
  NSUInteger eventCount = ranges.count * 2;

  BoundaryEvent *events = (BoundaryEvent *)malloc(sizeof(BoundaryEvent) * eventCount);
  if (!events)
    return text;

  NSUInteger eventIndex = 0;
  for (ENRMFormattingRange *formattingRange in ranges) {
    events[eventIndex++] = (BoundaryEvent){
        .position = formattingRange.range.location,
        .isOpening = YES,
        .type = formattingRange.type,
        .url = formattingRange.url,
    };
    events[eventIndex++] = (BoundaryEvent){
        .position = NSMaxRange(formattingRange.range),
        .isOpening = NO,
        .type = formattingRange.type,
        .url = formattingRange.url,
    };
  }

  qsort(events, eventCount, sizeof(BoundaryEvent), compareBoundaryEvents);

  NSMutableString *markdown = [NSMutableString stringWithCapacity:textLength + eventCount * 4];
  NSUInteger lastPosition = 0;

  for (NSUInteger currentEvent = 0; currentEvent < eventCount; currentEvent++) {
    BoundaryEvent event = events[currentEvent];
    NSUInteger position = MIN(event.position, textLength);

    if (position > lastPosition) {
      [markdown appendString:[text substringWithRange:NSMakeRange(lastPosition, position - lastPosition)]];
      lastPosition = position;
    }

    if (event.isOpening) {
      [markdown appendString:openingDelimiterForType(event.type)];
    } else {
      [markdown appendString:closingDelimiterForType(event.type, event.url)];
    }
  }

  if (lastPosition < textLength) {
    [markdown appendString:[text substringFromIndex:lastPosition]];
  }

  free(events);
  return markdown;
}

@end
