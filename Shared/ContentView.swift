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
        let worksSet = Set(works!.allObjects as! [Work]).sorted()

        return Array(worksSet)
    }

}

extension Work: Comparable {

    public static func < (lhs: Work, rhs: Work) -> Bool {
        return (lhs.title ?? "").caseInsensitiveCompare(rhs.title ?? "") == .orderedAscending
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
        .padding()
        .navigationTitle(work.title ?? "")
        .task {
            DispatchQueue(label: "xml-parser").async {
                if let perseusID = work.perseusID,
                   let perseusXML = PerseusBookParser(perseusID: perseusID) {
                    perseusXML.parse()
                    DispatchQueue.main.async {
                        text = perseusXML.book.text
                    }
                }
            }
        }
    }

}
struct ContentView: View {

    @ObservedObject var authorsModel = AuthorsModel()

    @Environment(\.managedObjectContext) private var viewContext: NSManagedObjectContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Author.sortName, ascending: true)],
        animation: .default)
    private var authors: FetchedResults<Author>

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8.0) {
                    ForEach(authors, id: \Author.sortName) { (author) in
                        NavigationLink(destination: AuthorView(author: author)) {
                            Text(author.fullName ?? "(unknown)")
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Authors")
        }
        .task {
            authorsModel.fetchAuthors(viewContext: viewContext)
        }
    }

}

struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
