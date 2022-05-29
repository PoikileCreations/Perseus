//
//  XMLBookParser.swift
//  Perseus
//
//  Created by Jason R Tibbetts on 5/28/22.
//

import Foundation

public protocol PerseusElement {

    static var tag: String { get }

    var text: String { get }

}

public struct Chapter: PerseusElement {

    public static var tag = "div2"

    public var milestones: [Milestone] = []
    public var number: Int = -1
    public var org: String = "uniform"
    public var sample: String = "complete"
    public var text: String {
        return milestones
            .map { "[\($0.number)] \($0.text)" }
            .joined(separator: "")
    }

    public init(_ attributes: [String: String] = [:]) {
        if let numberString = attributes["n"] {
            number = Int(numberString)!
        }

        if let orgAttr = attributes["org"] {
            org = orgAttr
        }
    }

}

public struct Milestone: PerseusElement {

    public static var tag = "milestone"
    public var number: Int = -1
    public var text: String = ""
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

    public var chapters: [Chapter] = []

    public var text: String {
        let fullText = chapters
            .map { "Chapter \($0.number)\n\($0.text)" }
            .joined(separator: "\n\n")

        return fullText
    }

}

public class PerseusBookParser: XMLParser {

    public var book = PerseusBook()

    private var currentChapter: Chapter?

    private var currentMilestone: Milestone?

    private var currentText = ""

    // MARK: - Initialization

    public convenience init?(perseusID: String) {
        // %3Abook%3D1
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
        case Chapter.tag:
            currentChapter = Chapter(attributes)
        case Milestone.tag:
            // Some works, like Caesar's _De bello Gallico_, use
            // <milestone n="*" unit="chapter"/> to denote chapters, not
            // <TEI.2> tags.
            if attributes["unit"]! == "chapter" {
                currentChapter = Chapter(attributes)
            } else {
                currentMilestone?.text = currentText

                if let milestone = currentMilestone {
                    currentText = ""
                    currentChapter?.milestones.append(milestone)
                }

                currentMilestone = Milestone(attributes)
            }
        default:
            return
        }
    }

    public func parser(_ parser: XMLParser,
                       didEndElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?) {
        switch elementName {
        case Chapter.tag:
            if let chapter = currentChapter {
                book.chapters.append(chapter)
            }

            currentChapter = nil
        case "p":
            currentMilestone?.text = currentText

            if let milestone = currentMilestone {
                currentText = ""
                currentChapter?.milestones.append(milestone)
                currentMilestone = nil
            }

            if let chapter = currentChapter {
                book.chapters.append(chapter)
                currentChapter = nil
            }
        default:
            return
        }
    }

    public func parser(_ parser: XMLParser,
                       foundCharacters string: String) {
        // For some reason, some strings contain seemingly random newlines,
        // like in Caesar _De bello civili_ 1.1.
        let trimmedText = string
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        currentText = currentText.appending(trimmedText + " ")
    }

}
