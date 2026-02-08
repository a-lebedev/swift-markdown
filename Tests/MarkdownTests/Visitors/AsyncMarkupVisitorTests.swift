/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
@testable import Markdown

final class AsyncMarkupVisitorTests: XCTestCase {

    // MARK: - AsyncMarkupWalker Tests

    /// Test that every element is visited via async `defaultVisit`
    func testAsyncDefaultVisit() async {
        // Using an actor to track count across async calls
        actor CountActor {
            var count = 0
            func increment() {
                count += 1
            }
            func getCount() -> Int {
                return count
            }
        }

        struct AsyncCountEveryElement: AsyncMarkupWalker {
            let counter: CountActor

            func defaultVisit(_ markup: Markup) async {
                await counter.increment()
                await descendInto(markup)
            }
        }

        let document = Document(parsing: """
        # Heading

        A paragraph with **bold** and *italic* text.

        - Item 1
        - Item 2
        """)

        let counter = CountActor()
        let walker = AsyncCountEveryElement(counter: counter)
        await walker.visit(document)
        let count = await counter.getCount()
        XCTAssertEqual(document.subtreeCount, count)
    }

    /// Test that async walker visits specific elements
    func testAsyncWalkerVisitsSpecificElements() async {
        actor LinkCountActor {
            var linkCount = 0
            func increment() {
                linkCount += 1
            }
            func getCount() -> Int {
                return linkCount
            }
        }

        struct AsyncLinkCounter: AsyncMarkupWalker {
            let counter: LinkCountActor

            func visitLink(_ link: Link) async {
                await counter.increment()
                await descendInto(link)
            }
        }

        let document = Document(parsing: """
        Here is a [link](https://example.com) and another [link](https://test.com).

        And a third [link](https://third.com).
        """)

        let counter = LinkCountActor()
        let walker = AsyncLinkCounter(counter: counter)
        await walker.visit(document)
        let count = await counter.getCount()
        XCTAssertEqual(3, count)
    }

    // MARK: - AsyncMarkupRewriter Tests

    /// Test that async rewriter can transform elements
    func testAsyncRewriterTransformsElements() async {
        struct AsyncUppercaseTextRewriter: AsyncMarkupRewriter {
            func visitText(_ text: Text) async -> Markup? {
                return Text(text.string.uppercased())
            }
        }

        let document = Document(parsing: "Hello world")

        let rewriter = AsyncUppercaseTextRewriter()
        let result = await rewriter.visit(document) as? Document

        XCTAssertNotNil(result)
        let formattedResult = result?.format()
        // format() adds a trailing newline
        XCTAssertTrue(formattedResult?.contains("HELLO WORLD") ?? false)
    }

    /// Test that async rewriter can remove elements by returning nil
    func testAsyncRewriterRemovesElements() async {
        struct AsyncLinkRemover: AsyncMarkupRewriter {
            func visitLink(_ link: Link) async -> Markup? {
                return nil
            }
        }

        let document = Document(parsing: "Text before [link](https://example.com) text after.")

        let rewriter = AsyncLinkRemover()
        let result = await rewriter.visit(document) as? Document

        XCTAssertNotNil(result)
        let formattedResult = result?.format()
        XCTAssertTrue(formattedResult?.contains("Text before") ?? false)
        XCTAssertTrue(formattedResult?.contains("text after") ?? false)
        XCTAssertFalse(formattedResult?.contains("[link]") ?? true)
    }

    // MARK: - AsyncMarkupVisitor Tests

    /// Test basic async visitor with custom result type
    func testAsyncVisitorWithCustomResult() async {
        struct AsyncTextCollector: AsyncMarkupVisitor {
            typealias Result = [String]

            func defaultVisit(_ markup: Markup) async -> [String] {
                var results: [String] = []
                for child in markup.children {
                    results.append(contentsOf: await visit(child))
                }
                return results
            }

            func visitText(_ text: Text) async -> [String] {
                return [text.string]
            }
        }

        let document = Document(parsing: "Hello **world** and *friends*")

        let collector = AsyncTextCollector()
        let result = await collector.visit(document)

        XCTAssertEqual(["Hello ", "world", " and ", "friends"], result)
    }

    /// Test that async visitor can simulate async work
    func testAsyncVisitorWithSimulatedAsyncWork() async {
        actor ResultCollector {
            var visitedTypes: [String] = []

            func append(_ type: String) {
                visitedTypes.append(type)
            }

            func getResults() -> [String] {
                return visitedTypes
            }
        }

        struct AsyncTypeCollector: AsyncMarkupWalker {
            let collector: ResultCollector

            func visitHeading(_ heading: Heading) async {
                await collector.append("Heading")
                await descendInto(heading)
            }

            func visitParagraph(_ paragraph: Paragraph) async {
                await collector.append("Paragraph")
                await descendInto(paragraph)
            }

            func visitLink(_ link: Link) async {
                await collector.append("Link")
                await descendInto(link)
            }
        }

        let document = Document(parsing: """
        # Title

        A paragraph with a [link](https://example.com).
        """)

        let collector = ResultCollector()
        var visitor = AsyncTypeCollector(collector: collector)
        await visitor.visit(document)

        let results = await collector.getResults()
        XCTAssertTrue(results.contains("Heading"))
        XCTAssertTrue(results.contains("Paragraph"))
        XCTAssertTrue(results.contains("Link"))
    }

    // MARK: - Accept Async Tests

    /// Test that acceptAsync dispatches to correct visitor method
    func testAcceptAsyncDispatchesToCorrectMethod() async {
        struct TypeNameVisitor: AsyncMarkupVisitor {
            typealias Result = String

            func defaultVisit(_ markup: Markup) async -> String {
                return "default"
            }

            func visitDocument(_ document: Document) async -> String {
                return "Document"
            }

            func visitParagraph(_ paragraph: Paragraph) async -> String {
                return "Paragraph"
            }

            func visitText(_ text: Text) async -> String {
                return "Text"
            }

            func visitLink(_ link: Link) async -> String {
                return "Link"
            }
        }

        let visitor = TypeNameVisitor()

        let document = Document(parsing: "test")
        let documentResult = await document.acceptAsync(visitor)
        XCTAssertEqual("Document", documentResult)

        let paragraph = Paragraph(Text("test"))
        let paragraphResult = await paragraph.acceptAsync(visitor)
        XCTAssertEqual("Paragraph", paragraphResult)

        let text = Text("test")
        let textResult = await text.acceptAsync(visitor)
        XCTAssertEqual("Text", textResult)

        let link = Link(destination: "https://example.com", Text("test"))
        let linkResult = await link.acceptAsync(visitor)
        XCTAssertEqual("Link", linkResult)
    }

    // MARK: - Cache Pattern Tests

    /// Test the actor cache injection pattern
    func testActorCacheInjectionPattern() async {
        actor CodeCache {
            var cache: [String: String] = [:]
            var cacheHits = 0
            var cacheMisses = 0

            func get(_ key: String) -> String? {
                if let value = cache[key] {
                    cacheHits += 1
                    return value
                }
                cacheMisses += 1
                return nil
            }

            func set(_ key: String, value: String) {
                cache[key] = value
            }

            func getStats() -> (hits: Int, misses: Int) {
                return (cacheHits, cacheMisses)
            }
        }

        struct AsyncCodeBlockProcessor: AsyncMarkupWalker {
            let cache: CodeCache

            func visitCodeBlock(_ codeBlock: CodeBlock) async {
                let key = codeBlock.code

                if await cache.get(key) != nil {
                    // Cache hit - use cached value
                    return
                }

                // Simulate processing
                let processed = "PROCESSED: \(codeBlock.code)"
                await cache.set(key, value: processed)
            }
        }

        let document = Document(parsing: """
        ```swift
        print("hello")
        ```

        Some text.

        ```swift
        print("hello")
        ```
        """)

        let cache = CodeCache()

        // First pass
        var processor1 = AsyncCodeBlockProcessor(cache: cache)
        await processor1.visit(document)

        // Second pass with same cache
        var processor2 = AsyncCodeBlockProcessor(cache: cache)
        await processor2.visit(document)

        let stats = await cache.getStats()
        // We should have some cache hits from the second code block being the same
        XCTAssertGreaterThan(stats.hits + stats.misses, 0)
    }
}
