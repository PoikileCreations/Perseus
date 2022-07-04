//
//  AuthorsModel.swift
//  Perseus
//
//  Created by Jason R Tibbetts on 5/25/22.
//

import CoreData
import Foundation
import SwiftHTMLParser
import SwiftUI

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

    func fetchAuthors(viewContext: NSManagedObjectContext) {
        DispatchQueue(label: "download-authors").async {
            do {
                let authorsUrl = URL(string: "https://www.perseus.tufts.edu/hopper/collection?collection=Perseus:collection:Greco-Roman")!
                let authorsString = try String(contentsOf: authorsUrl)
                let authorsHtml = try HTMLParser.parse(authorsString)

                var authorNodes: [Node] = []

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

                authorNodes.append(contentsOf: HTMLTraverser.findNodes(in: authorsHtml, matching: authorPath))

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

                authorNodes.append(contentsOf: HTMLTraverser.findNodes(in: authorsHtml, matching: hiddenAuthorPath))

                authorNodes.forEach { self.parseAuthorNode($0, viewContext: viewContext) }

                if viewContext.hasChanges {
                    try viewContext.save()
                }
            } catch {
                print("Failed to parse the authors: \(error)")
            }
        }
    }

    func parseAuthorNode(_ authorNode: Node,
                         viewContext: NSManagedObjectContext) {
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

        var author: Author?

        let authorRequest = NSFetchRequest<Author>(entityName: "Author")
        authorRequest.predicate = NSPredicate(format: "sortName == %@", authorName)

        do {
            author = try viewContext.fetch(authorRequest).first
        } catch {
            print("Failed to fetch the author")
        }

        if author == nil {
            author = Author(context: viewContext)
            author?.fullName = authorName
            author?.sortName = authorName
        }

        var workNodes: [Node] = []

        let subdocWorkPath: [NodeSelector] = [
            ElementSelector().withTagName("tr"),
            ElementSelector().withTagName("td").withTagName("tdAuthor"),
            ElementSelector().withTagName("ul").withClassName("subdoc"),
            ElementSelector().withTagName("li"),
            ElementSelector().withTagName("a").withClassName("aResultsHeader")
        ]

        workNodes.append(contentsOf: HTMLTraverser.findNodes(in: [authorNode], matching: subdocWorkPath))

        let standaloneWorkPath = [
            ElementSelector().withTagName("tr"),
            ElementSelector().withTagName("td").withTagName("tdAuthor"),
            ElementSelector().withTagName("a").withClassName("aResultsHeader")
        ]

        workNodes.append(contentsOf: HTMLTraverser.findNodes(in: [authorNode], matching: standaloneWorkPath))

        workNodes.forEach { parseWorkNode($0, author: author!) }
    }

    func parseWorkNode(_ node: Node, author: Author) {
        if let workElement = node as? Element {
            print("\t" + workElement.attributeValue(for: "href")!)
            print("\t" + workElement.textNodes.first!.text)
        }
    }

}
