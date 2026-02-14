#import "LinkTapUtils.h"

NSString *_Nullable linkURLAtTapLocation(UITextView *textView, UITapGestureRecognizer *recognizer)
{
  NSLayoutManager *layoutManager = textView.layoutManager;
  CGPoint location = [recognizer locationInView:textView];
  location.x -= textView.textContainerInset.left;
  location.y -= textView.textContainerInset.top;

  NSUInteger characterIndex = [layoutManager characterIndexForPoint:location
                                                    inTextContainer:textView.textContainer
                           fractionOfDistanceBetweenInsertionPoints:NULL];

  if (characterIndex < textView.textStorage.length) {
    NSRange range;
    return [textView.attributedText attribute:@"linkURL" atIndex:characterIndex effectiveRange:&range];
  }

  return nil;
}

NSString *_Nullable linkURLAtRange(UITextView *textView, NSRange characterRange)
{
  if (characterRange.location >= textView.attributedText.length) {
    return nil;
  }
  return [textView.attributedText attribute:@"linkURL" atIndex:characterRange.location effectiveRange:NULL];
}
