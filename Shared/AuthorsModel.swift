//
//  AuthorsModel.swift
//  Perseus
//
//  Created by Jason R Tibbetts on 5/25/22.
//

import Foundation
import SwiftHTMLParser

extension Element {

    var asHTML: String {
        let indentation = String(repeating: "  ", count: depth)
        var str = "\(indentation)<" + tagName

        if id != nil { str.append(" id=\"\(id!)\"") }
        if !classNames.isEmpty { str.append(" class=\"\(classNames.joined(separator: ","))\"") }
        str.append(">")

        if isSelfClosingElement {
            return str
        }

        childElements.forEach { (child) in
            str.append("\n")
            str.append(child.asHTML)
        }

        str.append(textNodes.map { $0.text }.joined(separator: " "))

        if textNodes.isEmpty {
            str.append(indentation)
        }

        str.append("</\(tagName)>")

        return str
    }

}

extension String {

    func nodeSelectorPath() throws -> [NodeSelector] {
        return self.split(separator: "/").compactMap { (pathElement) in
            let trimmedPathElement = pathElement.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedPathElement.isEmpty {
                return nil
            } else {
                return ElementSelector().withTagName(String(trimmedPathElement))
            }
        }
    }

}

class AuthorsModel: ObservableObject {

    @Published var authors: [String] = []

    func fetchAuthors() {
        DispatchQueue(label: "download-authors").async {
            do {
                let authorsUrl = URL(string: "https://www.perseus.tufts.edu/hopper/collection?collection=Perseus:collection:Greco-Roman")!
                let authorsString = try String(contentsOf: authorsUrl)
                let authorsHtml = try HTMLParser.parse(authorsString)

                let authorPath = [
                    ElementSelector().withTagName("html"),
                    ElementSelector().withTagName("body"),
                    ElementSelector().withTagName("div").withId("main"),
                    ElementSelector().withTagName("div").withId("content"),
                    ElementSelector().withTagName("div").withId("index_main_col"),
                    ElementSelector().withTagName("div").withId("documents"),
                    ElementSelector().withTagName("table").withClassName("tResults"),
                    ElementSelector().withTagName("tr").withClassName("trResults")
                ]

                HTMLTraverser.findNodes(in: authorsHtml, matching: authorPath).forEach { self.parseAuthorNode($0) }

                let hiddenAuthorPath = [
                    ElementSelector().withTagName("html"),
                    ElementSelector().withTagName("body"),
                    ElementSelector().withTagName("div").withId("main"),
                    ElementSelector().withTagName("div").withId("content"),
                    ElementSelector().withTagName("div").withId("index_main_col"),
                    ElementSelector().withTagName("div").withId("documents"),
                    ElementSelector().withTagName("table").withClassName("tResults"),
                    ElementSelector().withTagName("tr").withClassName("trHiddenResults")
                ]

                HTMLTraverser.findNodes(in: authorsHtml, matching: hiddenAuthorPath).forEach { self.parseAuthorNode($0) }
            } catch {
                print("Failed to parse the authors: \(error)")
            }
        }
    }

    func parseAuthorNode(_ authorNode: Node) {
        guard let element = authorNode as? Element,
              let id = element.id else {
            print("Skipping \(authorNode)")

            return
        }

        let idElements = id.split(separator: ",")

        let authorName: String

        if idElements.count >= 3 {
            authorName = idElements.dropLast(2).joined()
        } else {
            authorName = "Anonymous"
        }

        print("Author: \(authorName)")

        let subdocWorkPath: [NodeSelector] = [
            ElementSelector().withTagName("tr"),
            ElementSelector().withTagName("td").withTagName("tdAuthor"),
            ElementSelector().withTagName("ul").withClassName("subdoc"),
            ElementSelector().withTagName("li"),
            ElementSelector().withTagName("a").withClassName("aResultsHeader")
        ]

        HTMLTraverser.findNodes(in: [authorNode], matching: subdocWorkPath).forEach { parseWorkNode($0) }

        let standaloneWorkPath = [
            ElementSelector().withTagName("tr"),
            ElementSelector().withTagName("td").withTagName("tdAuthor"),
            ElementSelector().withTagName("a").withClassName("aResultsHeader")
        ]

        HTMLTraverser.findNodes(in: [authorNode], matching: standaloneWorkPath).forEach { parseWorkNode($0) }
    }

    func parseWorkNode(_ node: Node) {
        if let workElement = node as? Element {
            print("\t" + workElement.attributeValue(for: "href")!)
            print("\t" + workElement.textNodes.first!.text)
        }
    }

//    func parseAuthorNode(_ node: Node) {
//        guard let authorElement = (node as? Element),
//        let firstChildNode = authorElement.childNodes.first else {
//            print("Unknown element: \(node)")
//
//            return
//        }
//
//        if let authorNameNode = (firstChildNode as? TextNode) {
//            let authorName = authorNameNode.text.trimmingCharacters(in: ["."])
//            print("Author: \(authorName)")
//            authors.append(authorName)
//        } else if let titleNode = (firstChildNode as? Element),
//                  titleNode.tagName == "a",
//                  let title = titleNode.textNodes.first?.text {
//            print("Title: \(title)")
//        }
//    }

}
