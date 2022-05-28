//
//  XMLBookParser.swift
//  Perseus
//
//  Created by Jason R Tibbetts on 5/28/22.
//

import Foundation

public protocol PerseusElement {

    static var tag: String { get }

    var text: String? { get }

}

public struct Milestone: PerseusElement {

    public static var tag = "milestone"
    public var number: Int = -1
    public var text: String?
    public var unit: String = "section"

    public init(_ attributes: [String : String] = [:]) {
        if let numberString = attributes["n"] {
           number = Int(numberString)!
        }

        unit = attributes["unit"]!
    }

}

public struct PerseusBook: PerseusElement {

    public static var tag = "TEI.2"

    public var milestones: [Milestone] = []

    public var text: String? {
        return milestones
            .filter { $0.text != nil }
            .map { "[\($0.number)] \($0.text!)" }
            .joined(separator: "")
    }

}

public class PerseusBookParser: XMLParser {

    public var book = PerseusBook()

    private var currentMilestone: Milestone?

    private var currentText = ""

    // MARK: - Initialization

    public convenience init?(perseusID: String) {
        let url = URL(string: "https://www.perseus.tufts.edu/hopper/xmlchunk?doc=Perseus%3atext%3a\(perseusID)%3Abook%3D1")!
        self.init(contentsOf: url)

        self.delegate = self
    }

}

extension PerseusBookParser: XMLParserDelegate {

    public func parser(_ parser: XMLParser,
                       didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                       attributes: [String : String] = [:]) {
        switch elementName {
        case "gap":
            currentText = currentText + "…"
        case Milestone.tag:
            currentMilestone?.text = currentText

            if let milestone = currentMilestone {
                currentText = ""
                book.milestones.append(milestone)
            }

            currentMilestone = Milestone(attributes)
        default:
            return
        }
    }

    public func parser(_ parser: XMLParser,
                       didEndElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?) {
        switch elementName {
        case "p":
            currentMilestone?.text = currentText

            if let milestone = currentMilestone {
                currentText = ""
                book.milestones.append(milestone)
            }
        default:
            return
        }
    }

    public func parser(_ parser: XMLParser,
                       foundCharacters string: String) {
        currentText = currentText.appending(string.trimmingCharacters(in: .whitespacesAndNewlines) + " ")
    }

}
