import SwiftUI

struct PlaylistDetailView: View {
    let playlistID: UUID
    @EnvironmentObject var library: Library
    @EnvironmentObject var player: PlayerManager
    @State private var showPicker = false

    private var playlist: Playlist? {
        library.playlists.first { $0.id == playlistID }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let playlist = playlist {
                content(for: playlist)
            }
        }
        .navigationTitle(playlist?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton()
                Button { showPicker = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Theme.color(playlist?.colorIndex ?? 0))
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            SongPickerSheet(playlistID: playlistID)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func content(for playlist: Playlist) -> some View {
        let songs = library.songs(in: playlist)
        let color = Theme.color(playlist.colorIndex)
        let isThisPlaying = player.playingPlaylistID == playlist.id

        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(playlist.emoji).font(.system(size: 64))
                Button {
                    if isThisPlaying {
                        player.toggle()
                    } else {
                        player.start(songs, playlistID: playlist.id)
                    }
                } label: {
                    Text(isThisPlaying && player.isPlaying ? "⏸ Pause" : "▶️ Play")
                        .font(kidFont(24))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40).padding(.vertical, 12)
                        .background(color, in: Capsule())
                        .shadow(color: color.opacity(0.5), radius: 5, y: 3)
                }
                .buttonStyle(BounceStyle())
                .disabled(songs.isEmpty)
                .opacity(songs.isEmpty ? 0.4 : 1)
            }
            .padding(.top, 8)

            if songs.isEmpty {
                Spacer()
                Text("This list is empty").font(kidFont(22))
                Button { showPicker = true } label: {
                    Text("➕ Add songs")
                        .font(kidFont(20))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(color, in: Capsule())
                }
                .buttonStyle(BounceStyle())
                Spacer()
            } else {
                List {
                    ForEach(Array(songs.enumerated()), id: \.element.id) { i, song in
                        SongRow(song: song,
                                color: color,
                                isCurrent: isThisPlaying && player.current?.id == song.id)
                            .contentShape(Rectangle())
                            .onTapGesture { player.start(songs, at: i, playlistID: playlist.id) }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { library.removeSongs(at: $0, from: playlist.id) }
                    .onMove { library.moveSongs(from: $0, to: $1, in: playlist.id) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

/// Pick which songs belong to this list.
struct SongPickerSheet: View {
    let playlistID: UUID
    @EnvironmentObject var library: Library
    @Environment(\.dismiss) private var dismiss

    private var playlist: Playlist? { library.playlists.first { $0.id == playlistID } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if library.songs.isEmpty {
                    Text("Add songs in the Songs tab first 🎵")
                        .font(kidFont(20))
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(library.songs.enumerated()), id: \.element.id) { i, song in
                                let isIn = playlist?.songIDs.contains(song.id) ?? false
                                Button {
                                    library.setMembership(song: song.id, playlist: playlistID, isMember: !isIn)
                                } label: {
                                    HStack(spacing: 12) {
                                        Text("🎵").font(.system(size: 24))
                                        Text(song.title)
                                            .font(kidFont(18))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: isIn ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 28))
                                            .foregroundColor(Theme.color(i))
                                    }
                                    .padding(12)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                                }
                                .buttonStyle(BounceStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Pick songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(kidFont(17))
                }
            }
        }
    }
}
