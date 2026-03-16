//
//  SmartExpenseAIApp.swift
//  SmartExpenseAI
//
//  Created by irsalshydiq on 16/03/26.
//

import SwiftUI
import SwiftData

@main
struct SmartExpenseAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Category.self, Transaction.self, Budget.self])
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
