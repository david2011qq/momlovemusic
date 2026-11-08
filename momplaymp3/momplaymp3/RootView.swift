import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            SongsView()
                .tabItem { Label("Songs", systemImage: "music.note") }
            PlaylistsView()
                .tabItem { Label("Lists", systemImage: "square.grid.2x2.fill") }
        }
        .tint(Theme.color(0))
        .preferredColorScheme(.light)
    }
}
