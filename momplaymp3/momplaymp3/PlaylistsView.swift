import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject var library: Library
    @EnvironmentObject var player: PlayerManager
    @State private var creating = false
    @State private var editing: Playlist?
    @State private var deleting: Playlist?

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if library.playlists.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(library.playlists) { p in
                                NavigationLink(value: p.id) {
                                    PlaylistCard(playlist: p,
                                                 count: library.songs(in: p).count,
                                                 isPlaying: player.playingPlaylistID == p.id)
                                }
                                .buttonStyle(BounceStyle())
                                .contextMenu {
                                    Button { editing = p } label: { Label("Edit", systemImage: "pencil") }
                                    Button(role: .destructive) { deleting = p } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("My Lists 📚")
            .navigationDestination(for: UUID.self) { id in
                PlaylistDetailView(playlistID: id)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { creating = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.color(0))
                    }
                    .buttonStyle(BounceStyle())
                }
            }
            .sheet(isPresented: $creating) { PlaylistEditor(playlist: nil) }
            .sheet(item: $editing) { p in PlaylistEditor(playlist: p) }
            .confirmationDialog(
                "Delete this list? Your songs stay in My Songs.",
                isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete list", role: .destructive) {
                    if let p = deleting {
                        player.stopIfPlaying(playlist: p.id)
                        library.deletePlaylist(p.id)
                    }
                    deleting = nil
                }
                Button("Cancel", role: .cancel) { deleting = nil }
            }
        }
        .miniPlayer()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📚").font(.system(size: 90))
            Text("Make your first list!").font(kidFont(28))
            Button { creating = true } label: {
                Text("➕ New list")
                    .font(kidFont(22))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(Theme.color(0), in: Capsule())
            }
            .buttonStyle(BounceStyle())
        }
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    let count: Int
    let isPlaying: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(playlist.emoji).font(.system(size: 58))
            Text(playlist.name)
                .font(kidFont(20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text("\(count) song\(count == 1 ? "" : "s")")
                .font(kidFont(14, .bold))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .padding(12)
        .background(Theme.color(playlist.colorIndex), in: RoundedRectangle(cornerRadius: 30))
        .overlay(alignment: .topTrailing) {
            if isPlaying { Text("🔊").font(.system(size: 26)).padding(12) }
        }
        .shadow(color: Theme.color(playlist.colorIndex).opacity(0.45), radius: 6, y: 4)
    }
}

/// Create a list (playlist == nil) or edit an existing one.
struct PlaylistEditor: View {
    @EnvironmentObject var library: Library
    @Environment(\.dismiss) private var dismiss
    let playlist: Playlist?

    @State private var name = ""
    @State private var emoji = Theme.emojis[0]
    @State private var colorIndex = 0

    private let emojiColumns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Text(emoji).font(.system(size: 80))

                        TextField("List name", text: $name)
                            .font(kidFont(22))
                            .multilineTextAlignment(.center)
                            .padding(14)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 20))

                        LazyVGrid(columns: emojiColumns, spacing: 10) {
                            ForEach(Theme.emojis, id: \.self) { e in
                                Button { emoji = e } label: {
                                    Text(e).font(.system(size: 36))
                                        .frame(maxWidth: .infinity, minHeight: 56)
                                        .background(emoji == e ? Theme.color(colorIndex).opacity(0.35) : Color.white,
                                                    in: RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(BounceStyle())
                            }
                        }

                        HStack(spacing: 10) {
                            ForEach(0..<Theme.palette.count, id: \.self) { i in
                                Button { colorIndex = i } label: {
                                    Circle().fill(Theme.color(i))
                                        .frame(width: 38, height: 38)
                                        .overlay(Circle().stroke(Color.white, lineWidth: colorIndex == i ? 4 : 0))
                                        .shadow(radius: colorIndex == i ? 4 : 0)
                                }
                                .buttonStyle(BounceStyle())
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(playlist == nil ? "New list" : "Edit list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(kidFont(17))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let p = playlist {
                    name = p.name
                    emoji = p.emoji
                    colorIndex = p.colorIndex
                } else {
                    colorIndex = library.playlists.count % Theme.palette.count
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let p = playlist {
            library.updatePlaylist(id: p.id, name: trimmed, emoji: emoji, colorIndex: colorIndex)
        } else {
            library.addPlaylist(name: trimmed, emoji: emoji, colorIndex: colorIndex)
        }
        dismiss()
    }
}
