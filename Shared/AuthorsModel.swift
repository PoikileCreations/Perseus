//
//  AuthorsModel.swift
//  Perseus
//
//  Created by Jason R Tibbetts on 5/25/22.
//

import Foundation
import SwiftHTMLParser

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
                    ElementSelector().withTagName("tr").withClassName("trResults")
//                    TextNodeSelector()
//                    ElementSelector().withTagName("td").withClassName("tdAuthor")
                ]
//                let selectorPath = try "/html/body/div/div/".nodeSelectorPath()
                HTMLTraverser.findNodes(in: authorsHtml, matching: selectorPath).forEach { self.parseAuthorNode($0) }
            } catch {
                print("Failed to parse the authors: \(error)")
            }
        }
    }

    func parseAuthorNode(_ node: Node) {
        if let authorId = (node as? Element)?.id,
           let authorName = authorId.split(separator: ",").first {
            print(authorName)
        }
    }

}
