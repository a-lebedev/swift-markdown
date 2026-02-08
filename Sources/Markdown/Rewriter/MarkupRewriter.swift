/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// A `MarkupVisitor` with the capability to rewrite elements in the tree.
public protocol MarkupRewriter: MarkupVisitor where Result == Markup? {}

extension MarkupRewriter {
    public mutating func defaultVisit(_ markup: Markup) -> Markup? {
        let newChildren = markup.children.compactMap {
            return self.visit($0)
        }
        return markup.withUncheckedChildren(newChildren)
    }
    public mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Result {
        return defaultVisit(blockQuote)
    }
    public mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> Result {
        return defaultVisit(codeBlock)
    }
    public mutating func visitCustomBlock(_ customBlock: CustomBlock) -> Result {
        return defaultVisit(customBlock)
    }
    public mutating func visitDocument(_ document: Document) -> Result {
        return defaultVisit(document)
    }
    public mutating func visitHeading(_ heading: Heading) -> Result {
        return defaultVisit(heading)
    }
    public mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Result {
        return defaultVisit(thematicBreak)
    }
    public mutating func visitHTMLBlock(_ html: HTMLBlock) -> Result {
        return defaultVisit(html)
    }
    public mutating func visitListItem(_ listItem: ListItem) -> Result {
        return defaultVisit(listItem)
    }
    public mutating func visitOrderedList(_ orderedList: OrderedList) -> Result {
        return defaultVisit(orderedList)
    }
    public mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> Result {
        return defaultVisit(unorderedList)
    }
    public mutating func visitParagraph(_ paragraph: Paragraph) -> Result {
        return defaultVisit(paragraph)
    }
    public mutating func visitBlockDirective(_ blockDirective: BlockDirective) -> Result {
        return defaultVisit(blockDirective)
    }
    public mutating func visitInlineCode(_ inlineCode: InlineCode) -> Result {
        return defaultVisit(inlineCode)
    }
    public mutating func visitCustomInline(_ customInline: CustomInline) -> Result {
        return defaultVisit(customInline)
    }
    public mutating func visitEmphasis(_ emphasis: Emphasis) -> Result {
        return defaultVisit(emphasis)
    }
    public mutating func visitImage(_ image: Image) -> Result {
        return defaultVisit(image)
    }
    public mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> Result {
        return defaultVisit(inlineHTML)
    }
    public mutating func visitLineBreak(_ lineBreak: LineBreak) -> Result {
        return defaultVisit(lineBreak)
    }
    public mutating func visitLink(_ link: Link) -> Result {
        return defaultVisit(link)
    }
    public mutating func visitInlineAttributes(_ attributes: InlineAttributes) -> Result {
        return defaultVisit(attributes)
    }
    public mutating func visitSoftBreak(_ softBreak: SoftBreak) -> Result {
        return defaultVisit(softBreak)
    }
    public mutating func visitStrong(_ strong: Strong) -> Result {
        return defaultVisit(strong)
    }
    public mutating func visitText(_ text: Text) -> Result {
        return defaultVisit(text)
    }
}

// MARK: - Async Markup Rewriter

/// An `AsyncMarkupVisitor` with the capability to rewrite elements in the tree asynchronously.
///
/// Use `AsyncMarkupRewriter` when you need to transform a markup tree while performing
/// asynchronous operations, such as fetching remote content, processing images,
/// or any I/O-bound transformations.
///
/// Example usage:
/// ```swift
/// struct LinkTransformer: AsyncMarkupRewriter {
///     func visitLink(_ link: Link) async -> Markup? {
///         guard let destination = link.destination else { return link }
///         let resolvedURL = await resolveShortURL(destination)
///         var modified = link
///         modified.destination = resolvedURL
///         return modified
///     }
/// }
///
/// let document = Document(parsing: markdownString)
/// var transformer = LinkTransformer()
/// let newDocument = await transformer.visit(document) as? Document
/// ```
public protocol AsyncMarkupRewriter: AsyncMarkupVisitor where Result == Markup? {}

extension AsyncMarkupRewriter {
    public func defaultVisit(_ markup: Markup) async -> Markup? {
        var newChildren: [Markup] = []
        for child in markup.children {
            if let transformed = await visit(child) {
                newChildren.append(transformed)
            }
        }
        return markup.withUncheckedChildren(newChildren)
    }

    public func visitBlockQuote(_ blockQuote: BlockQuote) async -> Result {
        return await defaultVisit(blockQuote)
    }

    public func visitCodeBlock(_ codeBlock: CodeBlock) async -> Result {
        return await defaultVisit(codeBlock)
    }

    public func visitCustomBlock(_ customBlock: CustomBlock) async -> Result {
        return await defaultVisit(customBlock)
    }

    public func visitDocument(_ document: Document) async -> Result {
        return await defaultVisit(document)
    }

    public func visitHeading(_ heading: Heading) async -> Result {
        return await defaultVisit(heading)
    }

    public func visitThematicBreak(_ thematicBreak: ThematicBreak) async -> Result {
        return await defaultVisit(thematicBreak)
    }

    public func visitHTMLBlock(_ html: HTMLBlock) async -> Result {
        return await defaultVisit(html)
    }

    public func visitListItem(_ listItem: ListItem) async -> Result {
        return await defaultVisit(listItem)
    }

    public func visitOrderedList(_ orderedList: OrderedList) async -> Result {
        return await defaultVisit(orderedList)
    }

    public func visitUnorderedList(_ unorderedList: UnorderedList) async -> Result {
        return await defaultVisit(unorderedList)
    }

    public func visitParagraph(_ paragraph: Paragraph) async -> Result {
        return await defaultVisit(paragraph)
    }

    public func visitBlockDirective(_ blockDirective: BlockDirective) async -> Result {
        return await defaultVisit(blockDirective)
    }

    public func visitInlineCode(_ inlineCode: InlineCode) async -> Result {
        return await defaultVisit(inlineCode)
    }

    public func visitCustomInline(_ customInline: CustomInline) async -> Result {
        return await defaultVisit(customInline)
    }

    public func visitEmphasis(_ emphasis: Emphasis) async -> Result {
        return await defaultVisit(emphasis)
    }

    public func visitImage(_ image: Image) async -> Result {
        return await defaultVisit(image)
    }

    public func visitInlineHTML(_ inlineHTML: InlineHTML) async -> Result {
        return await defaultVisit(inlineHTML)
    }

    public func visitLineBreak(_ lineBreak: LineBreak) async -> Result {
        return await defaultVisit(lineBreak)
    }

    public func visitLink(_ link: Link) async -> Result {
        return await defaultVisit(link)
    }

    public func visitInlineAttributes(_ attributes: InlineAttributes) async -> Result {
        return await defaultVisit(attributes)
    }

    public func visitSoftBreak(_ softBreak: SoftBreak) async -> Result {
        return await defaultVisit(softBreak)
    }

    public func visitStrong(_ strong: Strong) async -> Result {
        return await defaultVisit(strong)
    }

    public func visitText(_ text: Text) async -> Result {
        return await defaultVisit(text)
    }
}
