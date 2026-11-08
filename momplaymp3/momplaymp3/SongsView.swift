import SwiftUI
import UniformTypeIdentifiers

struct SongsView: View {
    enum ImportMode { case files, folder }

    @EnvironmentObject var library: Library
    @EnvironmentObject var player: PlayerManager
    @State private var importing = false
    @State private var importMode: ImportMode = .files
    @State private var message: String?
    @State private var songForLists: Song?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if library.songs.isEmpty { emptyState } else { songList }

                if library.isImporting {
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.6)
                        Text("Adding songs… 🎶").font(kidFont(20))
                    }
                    .padding(28)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 28))
                    .shadow(radius: 10)
                }
            }
            .navigationTitle("My Songs 🎵")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { startImport(.folder) } label: {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 26))
                            .foregroundColor(Theme.color(5))
                    }
                    .buttonStyle(BounceStyle())
                    Button { startImport(.files) } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.color(0))
                    }
                    .buttonStyle(BounceStyle())
                }
            }
            .fileImporter(isPresented: $importing,
                          allowedContentTypes: importMode == .folder ? [.folder] : [.mp3, .audio],
                          allowsMultipleSelection: importMode == .files) { result in
                handle(result)
            }
            .alert("Import finished", isPresented: Binding(get: { message != nil },
                                                          set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .sheet(item: $songForLists) { song in
                AddToListsSheet(song: song)
                    .presentationDetents([.medium, .large])
            }
        }
        .miniPlayer()
    }

    private func startImport(_ mode: ImportMode) {
        importMode = mode
        importing = true
    }

    private func handle(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        switch importMode {
        case .files:
            report(library.importFiles(urls))
        case .folder:
            guard let folder = urls.first else { return }
            library.importFolder(folder) { n in report(n) }
        }
    }

    private func report(_ n: Int) {
        message = n == 0
            ? "No new songs were added. (Songs with the same name are skipped.)"
            : "Added \(n) song\(n == 1 ? "" : "s")! 🎉"
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🎧").font(.system(size: 90))
            Text("No songs yet!").font(kidFont(30))
            Text("Add MP3 files or a whole folder").font(kidFont(18, .semibold)).foregroundColor(.secondary)
            Button { startImport(.folder) } label: {
                Text("📁 Import folder")
                    .font(kidFont(22))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(Theme.color(5), in: Capsule())
            }
            .buttonStyle(BounceStyle())
            Button { startImport(.files) } label: {
                Text("➕ Add songs")
                    .font(kidFont(22))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(Theme.color(0), in: Capsule())
            }
            .buttonStyle(BounceStyle())
        }
    }

    private var songList: some View {
        List {
            ForEach(Array(library.songs.enumerated()), id: \.element.id) { i, song in
                SongRow(song: song,
                        color: Theme.color(i),
                        isCurrent: player.current?.id == song.id,
                        onAdd: { songForLists = song })
                    .contentShape(Rectangle())
                    .onTapGesture { player.start(library.songs, at: i, playlistID: nil) }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions {
                        Button(role: .destructive) {
                            player.stopIfQueued(song.id)
                            library.deleteSong(song)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct SongRow: View {
    let song: Song
    let color: Color
    let isCurrent: Bool
    var onAdd: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(isCurrent ? "🔊" : "🎵")
                .font(.system(size: 26))
                .frame(width: 52, height: 52)
                .background(color, in: Circle())
            Text(song.title)
                .font(kidFont(18))
                .foregroundColor(.primary)
                .lineLimit(2)
            Spacer()
            if let onAdd = onAdd {
                Button(action: onAdd) {
                    Image(systemName: "text.badge.plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(color)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: color.opacity(0.35), radius: 4, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(isCurrent ? color : Color.clear, lineWidth: 3)
        )
    }
}

/// Tick the lists this song should belong to. A song can be in many lists.
struct AddToListsSheet: View {
    @EnvironmentObject var library: Library
    @Environment(\.dismiss) private var dismiss
    let song: Song
    @State private var creating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        Text(song.title)
                            .font(kidFont(20))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)

                        ForEach(library.playlists) { p in
                            let isIn = p.songIDs.contains(song.id)
                            Button {
                                library.setMembership(song: song.id, playlist: p.id, isMember: !isIn)
                            } label: {
                                HStack(spacing: 12) {
                                    Text(p.emoji).font(.system(size: 30))
                                    Text(p.name).font(kidFont(20)).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: isIn ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                }
                                .padding(14)
                                .background(Theme.color(p.colorIndex), in: RoundedRectangle(cornerRadius: 22))
                            }
                            .buttonStyle(BounceStyle())
                        }

                        Button { creating = true } label: {
                            Text("➕ New list")
                                .font(kidFont(20))
                                .foregroundColor(Theme.color(5))
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(BounceStyle())
                    }
                    .padding()
                }
            }
            .navigationTitle("Add to lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(kidFont(17))
                }
            }
            .sheet(isPresented: $creating) {
                PlaylistEditor(playlist: nil)
            }
        }
    }
}
