#import "LinkTapUtils.h"

NSString *_Nullable linkURLAtTapLocation(ENRMPlatformTextView *textView, ENRMTapRecognizer *recognizer)
{
  NSLayoutManager *layoutManager = textView.layoutManager;
  CGPoint location = [recognizer locationInView:textView];
  location.x -= textView.textContainerInset.left;
  location.y -= textView.textContainerInset.top;

  NSUInteger characterIndex = [layoutManager characterIndexForPoint:location
                                                    inTextContainer:textView.textContainer
                           fractionOfDistanceBetweenInsertionPoints:NULL];

  NSAttributedString *attrText = ENRMGetAttributedText(textView);
  if (characterIndex < attrText.length) {
    NSRange range;
    return [attrText attribute:@"linkURL" atIndex:characterIndex effectiveRange:&range];
  }

  return nil;
}

NSString *_Nullable linkURLAtRange(ENRMPlatformTextView *textView, NSRange characterRange)
{
  NSAttributedString *attrText = ENRMGetAttributedText(textView);
  if (characterRange.location >= attrText.length) {
    return nil;
  }
  return [attrText attribute:@"linkURL" atIndex:characterRange.location effectiveRange:NULL];
}

BOOL isPointOnInteractiveElement(ENRMPlatformTextView *textView, CGPoint point)
{
  NSLayoutManager *layoutManager = textView.layoutManager;
  CGPoint adjusted = CGPointMake(point.x - textView.textContainerInset.left, point.y - textView.textContainerInset.top);

  NSUInteger charIndex = [layoutManager characterIndexForPoint:adjusted
                                               inTextContainer:textView.textContainer
                      fractionOfDistanceBetweenInsertionPoints:NULL];

  NSAttributedString *attrText = ENRMGetAttributedText(textView);
  if (charIndex >= attrText.length) {
    return NO;
  }

  NSDictionary *attrs = [attrText attributesAtIndex:charIndex effectiveRange:NULL];
  return attrs[@"linkURL"] != nil || [attrs[@"TaskItem"] boolValue];
}
