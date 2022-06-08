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

                let selectorPath: [NodeSelector] = [
                    ElementSelector().withTagName("html"),
                    ElementSelector().withTagName("body"),
                    ElementSelector().withTagName("div").withId("main"),
                    ElementSelector().withTagName("div").withId("content"),
                    ElementSelector().withTagName("div").withId("index_main_col"),
                    ElementSelector().withTagName("div").withId("documents"),
                    ElementSelector().withTagName("table").withClassName("tResults"),
                    ElementSelector().withTagName("tr").withClassName("trResults"),
                    ElementSelector().withTagName("td").withClassName("tdAuthor")
                ]
                HTMLTraverser.findNodes(in: authorsHtml, matching: selectorPath).forEach { self.parseAuthorNode($0) }
            } catch {
                print("Failed to parse the authors: \(error)")
            }
        }
    }

    func parseAuthorNode(_ node: Node) {
        guard let authorElement = (node as? Element) else {
            print("Unknown element: \(node)")

            return
        }

        guard let authorNameNode = (authorElement.childNodes[0] as? TextNode) else {
            print("First node was not the author's name!\n\(authorElement.asHTML)")

            return
        }

        let authorName = authorNameNode.text.trimmingCharacters(in: ["."])
        print(authorName)
    }

}
