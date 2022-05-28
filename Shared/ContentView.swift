//
//  ContentView.swift
//  Shared
//
//  Created by Jason R Tibbetts on 5/25/22.
//

import SwiftUI
import CoreData

extension Author: Comparable {

    public static func < (lhs: Author, rhs: Author) -> Bool {
        return (lhs.sortName ?? "") < (rhs.sortName ?? "")
    }

    public func sortedWorks() -> [Work] {
        let worksSet = Set(works!.allObjects as! [Work])

        return Array(worksSet)
    }

}

extension Work: Comparable {

    public static func < (lhs: Work, rhs: Work) -> Bool {
        return (lhs.title ?? "") < (rhs.title ?? "")
    }

}

struct AuthorView: View {

    var author: Author

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            ForEach(author.sortedWorks()) { (work) in
                NavigationLink(destination: WorkView(work: work)) {
                    Text(work.title ?? "(untitled)")
                }
            }

            Spacer()
        }
        .navigationTitle(author.fullName ?? "")
    }

}

struct WorkView: View {

    @State private var text = "Downloading text…"

    var work: Work

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            ScrollView {
                Text(text)
            }
        }
        .navigationTitle(work.title ?? "")
        .task {
            if let perseusID = work.perseusID,
               let perseusXML = PerseusBookParser(perseusID: perseusID) {
                perseusXML.parse()
                text = perseusXML.book.text ?? "Failed to download text"
            }
        }
    }

}
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Author.sortName, ascending: true)],
        animation: .default)
    private var authors: FetchedResults<Author>

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8.0) {
                ForEach(authors, id: \Author.sortName) { (author) in
                    NavigationLink(destination: AuthorView(author: author)) {
                        Text(author.fullName ?? "(unknown)")
                    }
                }

                Spacer()
            }
            .navigationTitle("Authors")
        }
    }

}

struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
