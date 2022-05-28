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

    class WorkViewModel: ObservableObject {

        @Published var text: String?

        var work: Work? {
            didSet {
                if let perseusID = work?.perseusID,
                   let url = URL(string: "https://www.perseus.tufts.edu/hopper/xmlchunk?doc=Perseus%3atext%3a\(perseusID)") {
                    Task {
                        let (data, _) = try! await URLSession.shared.data(from: url)
                        text = String(data: data, encoding: .utf8)
                    }
                }
            }
        }

    }

    @ObservedObject var workViewModel = WorkViewModel()

    var work: Work

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(workViewModel.text ?? "Downloading text…")
        }
        .navigationTitle(work.title ?? "")
        .onAppear(perform: { workViewModel.work = work })
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
