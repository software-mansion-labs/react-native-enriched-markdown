export const sampleMarkdown2 = `# Markdown Renderer Test Document

> This document intentionally includes a wide variety of Markdown elements and edge cases.

---

## Table of Contents

1. [Headings](#headings)
2. [Text Formatting](#text-formatting)
3. [Blockquotes](#blockquotes)
4. [Lists](#lists)
5. [Task Lists](#task-lists)
6. [Links and References](#links-and-references)
7. [Images](#images)
8. [Code](#code)
9. [Tables](#tables)
10. [Horizontal Rules](#horizontal-rules)
11. [HTML in Markdown](#html-in-markdown)
12. [Footnotes](#footnotes)
13. [Definition Lists](#definition-lists)
14. [Math (if supported)](#math-if-supported)
15. [Escaping Characters](#escaping-characters)
16. [Emoji and Entities](#emoji-and-entities)
17. [Mixed Nesting Stress Test](#mixed-nesting-stress-test)

---

## Headings

# H1 Heading
## H2 Heading
### H3 Heading
#### H4 Heading
##### H5 Heading
###### H6 Heading

Alternate heading styles:

Heading Level 1
===============

Heading Level 2
---------------

---

## Text Formatting

Plain text paragraph with **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and \`inline code\`.

You can also use __bold__ and _italic_ forms.

Combination example: **bold with _nested italic_ and \`code\` inside**.

Superscript (renderer-dependent): X^2^  
Subscript (renderer-dependent): H~2~O  
Highlight (renderer-dependent): ==marked text==

Abbreviation example: HTML, CSS, JS.

---

## Blockquotes

> Single-level quote.
>
> Still inside the same quote.
>
>> Nested quote level 2.
>>
>>> Nested quote level 3.
>
> Back to level 1.

> ### Quoted Heading
> - Quoted list item 1
> - Quoted list item 2
>
> \`Quoted inline code\`

---

## Lists

### Unordered Lists

- Item A
- Item B
  - Nested B.1
  - Nested B.2
    - Deep B.2.a
- Item C

* Alternate bullet 1
* Alternate bullet 2
  + Mixed bullet nested
  + Another nested

### Ordered Lists

1. First
2. Second
3. Third
   1. Third.A
   2. Third.B
4. Fourth

1. Ordered list can
1. also use all ones
1. and still auto-number

### Mixed List

1. Step one
   - Note A
   - Note B
2. Step two
   - Subnote with \`code\`
   - Subnote with **bold**

---

## Task Lists

- [x] Completed task
- [ ] Incomplete task
- [x] Another completed task
  - [ ] Nested incomplete task
  - [x] Nested complete task

---

## Links and References

Inline link: [OpenAI](https://openai.com)

Link with title: [Markdown Guide](https://www.markdownguide.org "Markdown Guide Website")

Autolink: <https://example.com>

Email autolink: <test@example.com>

Reference-style link: [Example][example-ref]

Collapsed reference link: [Example][]

Shortcut reference link: [OpenAI]

[example-ref]: https://example.com/reference "Reference Example"
[example]: https://example.com/collapsed "Collapsed Reference"
[openai]: https://openai.com "Shortcut Reference"

---

## Images

Inline image:

![Sample Alt Text](https://via.placeholder.com/120x60 "Placeholder Image")

Reference image:

![Reference Image][img-ref]

[img-ref]: https://via.placeholder.com/100 "Reference Placeholder"

Image wrapped in link:

[![Clickable Image](https://via.placeholder.com/80)](https://example.com)

---

## Code

Inline code example: \`const x = 42;\`

Indented code block:

    function indentedExample() {
        return "Indented code block";
    }

Fenced code block (no language):

\`\`\`
No language specified
Line 2
\`\`\`

Fenced code block (language: javascript):

\`\`\`javascript
function greet(name) {
  console.log(\`Hello, \${name}!\`);
}
greet("Markdown");
\`\`\`

Fenced code block (language: python):

\`\`\`python
def fib(n):
    a, b = 0, 1
    out = []
    while len(out) < n:
        out.append(a)
        a, b = b, a + b
    return out
\`\`\`

Fenced code block (language: json):

\`\`\`json
{
  "name": "Renderer Test",
  "version": 1,
  "features": ["tables", "footnotes", "task-lists"]
}
\`\`\`

---

## Tables

| Left Align | Center Align | Right Align |
|:-----------|:------------:|------------:|
| alpha      | beta         |        1234 |
| gamma      | delta        |          56 |
| long text that wraps | centered text |         789 |

Table with inline formatting:

| Syntax | Example |
|--------|---------|
| Bold   | **strong** |
| Italic | *emphasis* |
| Code   | \`let y = 1\` |
| Link   | [Example](https://example.com) |

---

## Horizontal Rules

---
***
___

---

## HTML in Markdown

<div>
  <strong>Inline HTML block</strong> with <em>emphasis</em>.
</div>

<span style="color: red;">Styled span (if sanitizer allows)</span>

<details>
  <summary>Expandable section</summary>
  Hidden content inside details/summary.
</details>

---

## Footnotes

Here is a sentence with a footnote.[^1]

Here is another footnote reference.[^longnote]

[^1]: This is the first footnote.
[^longnote]: This is a longer footnote
    that spans multiple lines
    and includes \`inline code\`.

---

## Definition Lists

Term 1
: Definition for term 1

Term 2
: First definition for term 2
: Second definition for term 2

---

## Math (if supported)

Inline math: $E = mc^2$

Block math:

$$
\\int_0^\\infty e^{-x} \\, dx = 1
$$

---

## Escaping Characters

\\*This should not be italic\\*  
\\\`This should not be inline code\\\`  
\\# This should not be a heading  
\\[This should not be a link\\](https://example.com)

Escaped pipe in table-like text: a \\| b \\| c

---

## Emoji and Entities

Emoji shortcodes (renderer-dependent): :smile: :rocket: :white_check_mark:

Unicode emoji: 😄 🚀 ✅

HTML entities: &copy; &amp; &lt; &gt; &quot; &nbsp;

---

## Mixed Nesting Stress Test

> 1. Quoted ordered item
>    - Nested unordered
>      - Deep item with **bold** and \`code\`
>    - Another nested item
> 2. Second quoted ordered item
>
> \`\`\`text
> Quoted fenced code block
> with multiple lines
> \`\`\`
>
> | Quoted | Table |
> |--------|-------|
> | A      | B     |

1. Top ordered
   > Blockquote inside list
   >
   > - Quoted bullet inside ordered item
   > - Another bullet
2. Second item
   \`\`\`bash
   echo "Fenced code inside list"
   \`\`\`

- Bullet item with table below:

  | Col1 | Col2 |
  |------|------|
  | v1   | v2   |

- Bullet item with HTML:

  <kbd>Ctrl</kbd> + <kbd>C</kbd>

---

## Line Break Behavior

This line ends with two spaces.  
So this should be a hard line break.

This paragraph uses an explicit break tag.<br>
Next line after \`<br>\`.

---

## Final Paragraph

If your renderer supports extended Markdown, most features above should render correctly.  
If not, unsupported features should degrade gracefully as plain text.
`;
