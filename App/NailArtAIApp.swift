import SwiftUI
import SwiftData

@main
struct NailArtAIApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionManager)
        }
        .modelContainer(for: [HistorySession.self, FavoriteDesign.self])
    }
}
