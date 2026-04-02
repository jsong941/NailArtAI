import SwiftUI
import SwiftData

@main
struct NailArtAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: HistorySession.self)
    }
}
