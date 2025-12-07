#import "RichTextView.h"
#import "MarkdownParser.h"
#import "MarkdownASTNode.h"
#import "AttributedRenderer.h"
#import "RenderContext.h"
#import "RichTextConfig.h"
#import "RichTextLayoutManager.h"
#import "RichTextImageAttachment.h"
#import "RichTextRuntimeKeys.h"
#import <objc/runtime.h>

#import <react/renderer/components/RichTextViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/RichTextViewSpec/EventEmitters.h>
#import <react/renderer/components/RichTextViewSpec/Props.h>
#import <react/renderer/components/RichTextViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <React/RCTConversions.h>
#import <React/RCTFont.h>

using namespace facebook::react;

static const CGFloat kDefaultFontSize = 16.0;
static const CGFloat kMinimumHeight = 100.0;
static const CGFloat kLabelPadding = 10.0;

@interface RichTextView () <RCTRichTextViewViewProtocol>
- (void)setupTextView;
- (void)setupConstraints;
- (void)renderMarkdownContent:(NSString *)markdownString withProps:(const RichTextViewProps &)props;
- (void)textTapped:(UITapGestureRecognizer *)recognizer;
- (void)setupLayoutManager;
@end

@implementation RichTextView {
    UITextView * _textView;
    MarkdownParser * _parser;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<RichTextViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const RichTextViewProps>();
        _props = defaultProps;

        self.backgroundColor = [UIColor clearColor];  
        _parser = [[MarkdownParser alloc] init];
        
        [self setupTextView];
        [self setupConstraints];
    }

    return self;
}

- (void)setupTextView {
    _textView = [[UITextView alloc] init];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView.text = @"";
    _textView.font = [UIFont systemFontOfSize:16.0];
    _textView.backgroundColor = [UIColor clearColor];  
    _textView.textColor = [UIColor blackColor];
    _textView.editable = NO;
    // TODO: Calculate proper height to fit all content including images
    // Currently scrollEnabled = NO means content beyond viewport may not render
    _textView.scrollEnabled = NO;
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.textContainer.lineFragmentPadding = 0;
    // Disable UITextView's default link styling - we handle it directly in attributed strings
    _textView.linkTextAttributes = @{};
    // isSelectable controls text selection and link previews
    // Default to YES to match the prop default
    _textView.selectable = YES;
    
    // Add tap gesture recognizer
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTapped:)];
    [_textView addGestureRecognizer:tapRecognizer];
    
    [self addSubview:_textView];
}

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
    
    // Set up layout manager when text view is added
    if (subview == _textView) {
        [self setupLayoutManager];
    }
}

- (void)willRemoveSubview:(UIView *)subview {
    // Clean up layout manager when text view is removed
    if (subview == _textView && _textView.layoutManager != nil) {
        NSLayoutManager *layoutManager = _textView.layoutManager;
        if ([object_getClass(layoutManager) isEqual:[RichTextLayoutManager class]]) {
            [layoutManager setValue:nil forKey:@"config"];
            object_setClass(layoutManager, [NSLayoutManager class]);
        }
    }
    [super willRemoveSubview:subview];
}

- (void)setupLayoutManager {
    // Set up custom layout manager for rich text custom drawing (code, blockquotes, etc.)
    // This single manager can handle multiple element types
    NSLayoutManager *layoutManager = _textView.layoutManager;
    if (layoutManager != nil) {
        layoutManager.allowsNonContiguousLayout = NO; // workaround for onScroll issue (like react-native-live-markdown)
        object_setClass(layoutManager, [RichTextLayoutManager class]);
        
        // Set config on layout manager (like react-native-live-markdown sets markdownUtils)
        if (_config != nil) {
            [layoutManager setValue:_config forKey:@"config"];
        }
    }
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        [_textView.topAnchor constraintEqualToAnchor:self.topAnchor 
                                           constant:kLabelPadding],
        [_textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor 
                                                constant:kLabelPadding],
        [_textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor 
                                                 constant:-kLabelPadding],
        [_textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor 
                                               constant:-kLabelPadding],
        [self.heightAnchor constraintGreaterThanOrEqualToConstant:kMinimumHeight]
    ]];
}

- (void)renderMarkdownContent:(NSString *)markdownString {
    MarkdownASTNode *ast = [_parser parseMarkdown:markdownString];
    if (!ast) {
        NSLog(@"RichTextView: Failed to parse markdown");
        return;
    }
    
    AttributedRenderer *renderer = [[AttributedRenderer alloc] initWithConfig:_config];
    RenderContext *renderContext = [RenderContext new];
    
    UIFont *font = [_config primaryFont];
    UIColor *color = _textView.textColor ?: [UIColor blackColor];
    if ([_config primaryColor]) {
        color = [_config primaryColor];
    }
    
    NSMutableAttributedString *attributedText = [renderer renderRoot:ast font:font color:color context:renderContext];
    
    // Add custom attributes for links
    for (NSUInteger i = 0; i < renderContext.linkRanges.count; i++) {
        NSValue *rangeValue = renderContext.linkRanges[i];
        NSRange range = [rangeValue rangeValue];
        NSString *url = renderContext.linkURLs[i];
        // Add custom attribute for link detection
        [attributedText addAttribute:@"linkURL" value:url range:range];
    }
    
    // Set config on the layout manager
    // Use setValue:forKey: for runtime class changes (more reliable than direct property access)
    NSLayoutManager *layoutManager = _textView.layoutManager;
    if ([layoutManager isKindOfClass:[RichTextLayoutManager class]]) {
        [layoutManager setValue:_config forKey:@"config"];
    }
    
    // Store text view on text container so attachments can access it
    objc_setAssociatedObject(_textView.textContainer, kRichTextTextViewKey, _textView, OBJC_ASSOCIATION_ASSIGN);
    
    _textView.attributedText = attributedText;
    
    // Ensure layout is updated
    [_textView.layoutManager ensureLayoutForTextContainer:_textView.textContainer];
    [_textView.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, attributedText.length) actualCharacterRange:NULL];
    
    [_textView setNeedsLayout];
    [_textView setNeedsDisplay];
    [self setNeedsLayout];
}


- (void)updateProps:(Props::Shared const &)props 
          oldProps:(Props::Shared const &)oldProps {
    const auto &oldViewProps = *std::static_pointer_cast<RichTextViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<RichTextViewProps const>(props);
    
    BOOL stylePropChanged = NO;
    
    if (_config == nil) {
        _config = [[RichTextConfig alloc] init];
    }
        
    if (newViewProps.color != oldViewProps.color) {
        if (newViewProps.color) {
            UIColor *uiColor = RCTUIColorFromSharedColor(newViewProps.color);
            [_config setPrimaryColor:uiColor];
        } else {
            [_config setPrimaryColor:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.fontSize != oldViewProps.fontSize) {
        if (newViewProps.fontSize > 0) {
            NSNumber *fontSize = @(newViewProps.fontSize);
            [_config setPrimaryFontSize:fontSize];
        } else {
            [_config setPrimaryFontSize:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.fontWeight != oldViewProps.fontWeight) {
        if (!newViewProps.fontWeight.empty()) {
            [_config setPrimaryFontWeight:[[NSString alloc] initWithUTF8String:newViewProps.fontWeight.c_str()]];
        } else {
            [_config setPrimaryFontWeight:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.fontFamily != oldViewProps.fontFamily) {
        if (!newViewProps.fontFamily.empty()) {
            [_config setPrimaryFontFamily:[[NSString alloc] initWithUTF8String:newViewProps.fontFamily.c_str()]];
        } else {
            [_config setPrimaryFontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h1.fontSize != oldViewProps.richTextStyle.h1.fontSize) {
        [_config setH1FontSize:newViewProps.richTextStyle.h1.fontSize];
        stylePropChanged = YES;
    }
    
    
    if (newViewProps.richTextStyle.h1.fontFamily != oldViewProps.richTextStyle.h1.fontFamily) {
        if (!newViewProps.richTextStyle.h1.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h1.fontFamily.c_str()];
            [_config setH1FontFamily:fontFamily];
        } else {
            [_config setH1FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h2.fontSize != oldViewProps.richTextStyle.h2.fontSize) {
        [_config setH2FontSize:newViewProps.richTextStyle.h2.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h2.fontFamily != oldViewProps.richTextStyle.h2.fontFamily) {
        if (!newViewProps.richTextStyle.h2.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h2.fontFamily.c_str()];
            [_config setH2FontFamily:fontFamily];
        } else {
            [_config setH2FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h3.fontSize != oldViewProps.richTextStyle.h3.fontSize) {
        [_config setH3FontSize:newViewProps.richTextStyle.h3.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h3.fontFamily != oldViewProps.richTextStyle.h3.fontFamily) {
        if (!newViewProps.richTextStyle.h3.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h3.fontFamily.c_str()];
            [_config setH3FontFamily:fontFamily];
        } else {
            [_config setH3FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h4.fontSize != oldViewProps.richTextStyle.h4.fontSize) {
        [_config setH4FontSize:newViewProps.richTextStyle.h4.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h4.fontFamily != oldViewProps.richTextStyle.h4.fontFamily) {
        if (!newViewProps.richTextStyle.h4.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h4.fontFamily.c_str()];
            [_config setH4FontFamily:fontFamily];
        } else {
            [_config setH4FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h5.fontSize != oldViewProps.richTextStyle.h5.fontSize) {
        [_config setH5FontSize:newViewProps.richTextStyle.h5.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h5.fontFamily != oldViewProps.richTextStyle.h5.fontFamily) {
        if (!newViewProps.richTextStyle.h5.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h5.fontFamily.c_str()];
            [_config setH5FontFamily:fontFamily];
        } else {
            [_config setH5FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h6.fontSize != oldViewProps.richTextStyle.h6.fontSize) {
        [_config setH6FontSize:newViewProps.richTextStyle.h6.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h6.fontFamily != oldViewProps.richTextStyle.h6.fontFamily) {
        if (!newViewProps.richTextStyle.h6.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h6.fontFamily.c_str()];
            [_config setH6FontFamily:fontFamily];
        } else {
            [_config setH6FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.link.color != oldViewProps.richTextStyle.link.color) {
        UIColor *linkColor = RCTUIColorFromSharedColor(newViewProps.richTextStyle.link.color);
        [_config setLinkColor:linkColor];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.link.underline != oldViewProps.richTextStyle.link.underline) {
        [_config setLinkUnderline:newViewProps.richTextStyle.link.underline];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.strong.color != oldViewProps.richTextStyle.strong.color) {
        if (newViewProps.richTextStyle.strong.color) {
            UIColor *strongColor = RCTUIColorFromSharedColor(newViewProps.richTextStyle.strong.color);
            [_config setStrongColor:strongColor];
        } else {
            [_config setStrongColor:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.em.color != oldViewProps.richTextStyle.em.color) {
        if (newViewProps.richTextStyle.em.color) {
            UIColor *emphasisColor = RCTUIColorFromSharedColor(newViewProps.richTextStyle.em.color);
            [_config setEmphasisColor:emphasisColor];
        } else {
            [_config setEmphasisColor:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.code.color != oldViewProps.richTextStyle.code.color) {
        if (newViewProps.richTextStyle.code.color) {
            UIColor *codeColor = RCTUIColorFromSharedColor(newViewProps.richTextStyle.code.color);
            [_config setCodeColor:codeColor];
        } else {
            [_config setCodeColor:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.code.backgroundColor != oldViewProps.richTextStyle.code.backgroundColor) {
        if (newViewProps.richTextStyle.code.backgroundColor) {
            UIColor *codeBackgroundColor = RCTUIColorFromSharedColor(newViewProps.richTextStyle.code.backgroundColor);
            [_config setCodeBackgroundColor:codeBackgroundColor];
        } else {
            [_config setCodeBackgroundColor:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.code.borderColor != oldViewProps.richTextStyle.code.borderColor) {
        if (newViewProps.richTextStyle.code.borderColor) {
            UIColor *codeBorderColor = RCTUIColorFromSharedColor(newViewProps.richTextStyle.code.borderColor);
            [_config setCodeBorderColor:codeBorderColor];
        } else {
            [_config setCodeBorderColor:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.image.height != oldViewProps.richTextStyle.image.height) {
        [_config setImageHeight:newViewProps.richTextStyle.image.height];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.image.borderRadius != oldViewProps.richTextStyle.image.borderRadius) {
        [_config setImageBorderRadius:newViewProps.richTextStyle.image.borderRadius];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.inlineImage.size != oldViewProps.richTextStyle.inlineImage.size) {
        [_config setInlineImageSize:newViewProps.richTextStyle.inlineImage.size];
        stylePropChanged = YES;
    }
    
    // Update config reference on layout manager if it's not already set
    NSLayoutManager *layoutManager = _textView.layoutManager;
    if ([layoutManager isKindOfClass:[RichTextLayoutManager class]]) {
        RichTextConfig *currentConfig = [layoutManager valueForKey:@"config"];
        if (currentConfig != _config) {
            // Only update reference if it's different (first time setup)
            [layoutManager setValue:_config forKey:@"config"];
        }
    }
    
    // Control text selection and link previews via isSelectable property
    // According to Apple docs, isSelectable controls whether text selection and link previews work
    // https://developer.apple.com/documentation/uikit/uitextview/isselectable
    if (_textView.selectable != newViewProps.isSelectable) {
        _textView.selectable = newViewProps.isSelectable;
    }
    
        if (stylePropChanged) {
            NSString *currentMarkdown = [[NSString alloc] initWithUTF8String:newViewProps.markdown.c_str()];
            [self renderMarkdownContent:currentMarkdown];
        }
    
    if (oldViewProps.markdown != newViewProps.markdown && !stylePropChanged) {
        NSString *markdownString = [[NSString alloc] initWithUTF8String:newViewProps.markdown.c_str()];
        [self renderMarkdownContent:markdownString];
    }

    [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> RichTextViewCls(void)
{
    return RichTextView.class;
}

- (void)textTapped:(UITapGestureRecognizer *)recognizer {
    /*
     * HOW LINK TAPPING WORKS:
     * 
     * 1. SETUP PHASE (During Rendering):
     *    - Each link gets a custom @"linkURL" attribute attached to its text range
     *    - The URL is stored as the attribute's value
     *    - This creates an "invisible map" of where links are in the text
     * 
     *    Example:
     *    Text: "Check out this [link to React Native](https://reactnative.dev)"
     *          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     *          |     |     |     |     |     |     |     |     |     |     |
     *          0     5    10    15    20    25    30    35    40    45    50
     * 
     *    Attributes:
     *    - Characters 15-29: @"linkURL" = "https://reactnative.dev"
     *    - Characters 0-14: no special attributes
     *    - Characters 30-50: no special attributes
     * 
     * 2. TOUCH DETECTION PHASE (When User Taps):
     *    - UITapGestureRecognizer detects the tap
     *    - We get the tap coordinates relative to the text view
     *    - We adjust for text container insets to get precise text coordinates
     */
    
    UITextView *textView = (UITextView *)recognizer.view;
    
    // Location of the tap in text-container coordinates
    NSLayoutManager *layoutManager = textView.layoutManager;
    CGPoint location = [recognizer locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;
    
    /*
     * 3. CHARACTER INDEX LOOKUP:
     *    - NSLayoutManager converts the tap coordinates to a character index
     *    - This tells us exactly which character in the text was tapped
     *    - Uses UIKit's built-in text layout system (very accurate)
     */
    NSUInteger characterIndex;
    characterIndex = [layoutManager characterIndexForPoint:location
                                           inTextContainer:textView.textContainer
                  fractionOfDistanceBetweenInsertionPoints:NULL];
    
    /*
     * 4. LINK DETECTION:
     *    - We check if there's a @"linkURL" attribute at the tapped character
     *    - If found, we get the URL value and the effective range
     *    - If it's a link, we emit the onLinkPress event to React Native
     * 
     * COMPLETE FLOW:
     * 1. User taps → UITapGestureRecognizer fires
     * 2. Get coordinates → Convert to text container coordinates  
     * 3. Find character → NSLayoutManager.characterIndexForPoint
     * 4. Check attributes → Look for @"linkURL" at that character
     * 5. If link found → Emit onLinkPress event with URL
     * 6. React Native → Receives event and shows alert
     */
    if (characterIndex < textView.textStorage.length) {
        NSRange range;
        NSString *url = [textView.attributedText attribute:@"linkURL" atIndex:characterIndex effectiveRange:&range];
        
        if (url) {            
            // Emit onLinkPress event to React Native
            const auto &eventEmitter = *std::static_pointer_cast<RichTextViewEventEmitter const>(_eventEmitter);
            eventEmitter.onLinkPress({
                .url = std::string([url UTF8String])
            });
        }
    }
}


@end
