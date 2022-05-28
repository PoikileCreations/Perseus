//
//  PerseusApp.swift
//  Shared
//
//  Created by Jason R Tibbetts on 5/25/22.
//

import SwiftUI

@main
struct PerseusApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }

}
