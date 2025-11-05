#import "RichTextView.h"
#import "MarkdownParser.h"
#import "MarkdownASTNode.h"
#import "AttributedRenderer.h"
#import "RenderContext.h"
#import "RichTextConfig.h"

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
- (UIFont *)createFontWithFamily:(NSString *)fontFamily size:(CGFloat)size weight:(NSString *)weight style:(NSString *)style;
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
    
    _textView.attributedText = attributedText;
}

- (void)updateProps:(Props::Shared const &)props 
oldProps:(Props::Shared const &)oldProps {
    const auto &oldViewProps = *std::static_pointer_cast<RichTextViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<RichTextViewProps const>(props);

    BOOL stylePropChanged = NO;
    
    if (_config == nil) {
        _config = [[RichTextConfig alloc] init];
    }
        
    RichTextConfig *newConfig = [_config copy];
    
    if (newViewProps.color != oldViewProps.color) {
        if (newViewProps.color) {
            UIColor *uiColor = RCTUIColorFromSharedColor(newViewProps.color);
            [newConfig setPrimaryColor:uiColor];
        } else {
            [newConfig setPrimaryColor:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.fontSize != oldViewProps.fontSize) {
        if (newViewProps.fontSize > 0) {
            NSNumber *fontSize = @(newViewProps.fontSize);
            [newConfig setPrimaryFontSize:fontSize];
        } else {
            [newConfig setPrimaryFontSize:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.fontWeight != oldViewProps.fontWeight) {
        if (!newViewProps.fontWeight.empty()) {
            [newConfig setPrimaryFontWeight:[[NSString alloc] initWithUTF8String:newViewProps.fontWeight.c_str()]];
        } else {
            [newConfig setPrimaryFontWeight:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.fontFamily != oldViewProps.fontFamily) {
        if (!newViewProps.fontFamily.empty()) {
            [newConfig setPrimaryFontFamily:[[NSString alloc] initWithUTF8String:newViewProps.fontFamily.c_str()]];
        } else {
            [newConfig setPrimaryFontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h1.fontSize != oldViewProps.richTextStyle.h1.fontSize) {
        [newConfig setH1FontSize:newViewProps.richTextStyle.h1.fontSize];
        stylePropChanged = YES;
    }
    
    
    if (newViewProps.richTextStyle.h1.fontFamily != oldViewProps.richTextStyle.h1.fontFamily) {
        if (!newViewProps.richTextStyle.h1.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h1.fontFamily.c_str()];
            [newConfig setH1FontFamily:fontFamily];
        } else {
            [newConfig setH1FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h2.fontSize != oldViewProps.richTextStyle.h2.fontSize) {
        [newConfig setH2FontSize:newViewProps.richTextStyle.h2.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h2.fontFamily != oldViewProps.richTextStyle.h2.fontFamily) {
        if (!newViewProps.richTextStyle.h2.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h2.fontFamily.c_str()];
            [newConfig setH2FontFamily:fontFamily];
        } else {
            [newConfig setH2FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h3.fontSize != oldViewProps.richTextStyle.h3.fontSize) {
        [newConfig setH3FontSize:newViewProps.richTextStyle.h3.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h3.fontFamily != oldViewProps.richTextStyle.h3.fontFamily) {
        if (!newViewProps.richTextStyle.h3.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h3.fontFamily.c_str()];
            [newConfig setH3FontFamily:fontFamily];
        } else {
            [newConfig setH3FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h4.fontSize != oldViewProps.richTextStyle.h4.fontSize) {
        [newConfig setH4FontSize:newViewProps.richTextStyle.h4.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h4.fontFamily != oldViewProps.richTextStyle.h4.fontFamily) {
        if (!newViewProps.richTextStyle.h4.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h4.fontFamily.c_str()];
            [newConfig setH4FontFamily:fontFamily];
        } else {
            [newConfig setH4FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h5.fontSize != oldViewProps.richTextStyle.h5.fontSize) {
        [newConfig setH5FontSize:newViewProps.richTextStyle.h5.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h5.fontFamily != oldViewProps.richTextStyle.h5.fontFamily) {
        if (!newViewProps.richTextStyle.h5.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h5.fontFamily.c_str()];
            [newConfig setH5FontFamily:fontFamily];
        } else {
            [newConfig setH5FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h6.fontSize != oldViewProps.richTextStyle.h6.fontSize) {
        [newConfig setH6FontSize:newViewProps.richTextStyle.h6.fontSize];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.h6.fontFamily != oldViewProps.richTextStyle.h6.fontFamily) {
        if (!newViewProps.richTextStyle.h6.fontFamily.empty()) {
            NSString *fontFamily = [[NSString alloc] initWithUTF8String:newViewProps.richTextStyle.h6.fontFamily.c_str()];
            [newConfig setH6FontFamily:fontFamily];
        } else {
            [newConfig setH6FontFamily:nullptr];
        }
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.link.color != oldViewProps.richTextStyle.link.color) {
        UIColor *linkColor = RCTUIColorFromSharedColor(newViewProps.richTextStyle.link.color);
        [newConfig setLinkColor:linkColor];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.link.underline != oldViewProps.richTextStyle.link.underline) {
        [newConfig setLinkUnderline:newViewProps.richTextStyle.link.underline];
        stylePropChanged = YES;
    }
    
    if (newViewProps.richTextStyle.bold.color != oldViewProps.richTextStyle.bold.color) {
        if (newViewProps.richTextStyle.bold.color) {
            UIColor *boldColor = RCTUIColorFromSharedColor(newViewProps.richTextStyle.bold.color);
            [newConfig setBoldColor:boldColor];
        } else {
            [newConfig setBoldColor:nullptr];
        }
        stylePropChanged = YES;
    }
    
    // Control text selection and link previews via isSelectable property
    // According to Apple docs, isSelectable controls whether text selection and link previews work
    // https://developer.apple.com/documentation/uikit/uitextview/isselectable
    if (_textView.selectable != newViewProps.isSelectable) {
        _textView.selectable = newViewProps.isSelectable;
    }
    
    if (stylePropChanged) {
        NSString *currentMarkdown = [[NSString alloc] initWithUTF8String:newViewProps.markdown.c_str()];
        
        _config = newConfig;
        
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

- (UIFont *)createFontWithFamily:(NSString *)fontFamily size:(CGFloat)size weight:(NSString *)weight style:(NSString *)style {
    // Use React Native's RCTFont.updateFont for consistent font handling
    NSString *fontWeight = weight && weight.length > 0 ? weight : nullptr;
    NSString *fontStyle = style && style.length > 0 ? style : nullptr;
    
    // Handle edge case: weight "0" should be treated as nullptr
    if ([fontWeight isEqualToString:@"0"]) {
        fontWeight = nullptr;
    }
    
    return [RCTFont updateFont:nullptr
                   withFamily:fontFamily
                          size:@(size)
                        weight:fontWeight
                         style:fontStyle
                      variant:nullptr
                scaleMultiplier:1];
}

@end
