import SwiftUI

@main
struct momplaymp3App: App {
    @StateObject private var library = Library()
    @StateObject private var player = PlayerManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .environmentObject(player)
        }
    }
}
