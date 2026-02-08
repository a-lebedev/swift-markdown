/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// An interface for walking a `Markup` tree without altering it.
public protocol MarkupWalker: MarkupVisitor where Result == Void {}

extension MarkupWalker {
    /// Continue walking by descending in the given element.
    ///
    /// - Parameter markup: the element whose children the walker should visit.
    public mutating func descendInto(_ markup: Markup) {
        for child in markup.children {
            visit(child)
        }
    }
    public mutating func defaultVisit(_ markup: Markup) {
        descendInto(markup)
    }
}

// MARK: - Async Markup Walker

/// An interface for walking a `Markup` tree asynchronously without altering it.
///
/// Use `AsyncMarkupWalker` when you need to perform asynchronous operations during tree traversal,
/// such as network calls, file I/O, accessing `@MainActor`-isolated APIs, or expensive computations.
///
/// Example usage:
/// ```swift
/// struct LinkValidator: AsyncMarkupWalker {
///     func visitLink(_ link: Link) async {
///         guard let url = link.destination else { return }
///         let isValid = await validateURL(url)
///         print("\(url): \(isValid ? "✓" : "✗")")
///     }
/// }
///
/// let document = Document(parsing: markdownString)
/// var validator = LinkValidator()
/// await validator.visit(document)
/// ```
public protocol AsyncMarkupWalker: AsyncMarkupVisitor where Result == Void {}

extension AsyncMarkupWalker {
    /// Continue walking by descending into the given element asynchronously.
    ///
    /// - Parameter markup: the element whose children the walker should visit.
    public func descendInto(_ markup: Markup) async {
        for child in markup.children {
            await visit(child)
        }
    }

    public func defaultVisit(_ markup: Markup) async {
        await descendInto(markup)
    }
}
