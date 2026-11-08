import Foundation

struct Song: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var fileName: String
}

struct Playlist: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var emoji: String
    var colorIndex: Int
    var songIDs: [UUID] = []
}

final class Library: ObservableObject {
    @Published var songs: [Song] = []
    @Published var playlists: [Playlist] = []
    @Published var isImporting = false

    private static let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    static let songsDir: URL = {
        let dir = docs.appendingPathComponent("Songs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static let dataURL = docs.appendingPathComponent("library.json")

    static func fileURL(for song: Song) -> URL {
        songsDir.appendingPathComponent(song.fileName)
    }

    private struct Snapshot: Codable {
        var songs: [Song]
        var playlists: [Playlist]
    }

    init() { load() }

    private func load() {
        guard let data = try? Data(contentsOf: Self.dataURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        songs = snap.songs
        playlists = snap.playlists
    }

    private func save() {
        let snap = Snapshot(songs: songs, playlists: playlists)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: Self.dataURL, options: .atomic)
        }
    }

    // MARK: Songs

    static let audioExtensions: Set<String> = ["mp3", "m4a", "wav"]

    private static func copyIn(_ url: URL) -> Song? {
        let title = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension
        let stored = "\(UUID().uuidString).\(ext)"
        let dest = songsDir.appendingPathComponent(stored)
        do {
            try FileManager.default.copyItem(at: url, to: dest)
            return Song(title: title, fileName: stored)
        } catch {
            print("Import failed: \(error)")
            return nil
        }
    }

    private func sortAndSave() {
        songs.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        save()
    }

    /// Import individually picked files. Returns how many were added.
    @discardableResult
    func importFiles(_ urls: [URL]) -> Int {
        var added = 0
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }

            let title = url.deletingPathExtension().lastPathComponent
            if songs.contains(where: { $0.title == title }) { continue }
            if let song = Self.copyIn(url) {
                songs.append(song)
                added += 1
            }
        }
        sortAndSave()
        return added
    }

    /// Import every audio file inside a folder (and its subfolders), in the background.
    func importFolder(_ folder: URL, completion: @escaping (Int) -> Void) {
        isImporting = true
        let knownTitles = Set(songs.map { $0.title })

        DispatchQueue.global(qos: .userInitiated).async {
            let scoped = folder.startAccessingSecurityScopedResource()
            defer { if scoped { folder.stopAccessingSecurityScopedResource() } }

            var found: [Song] = []
            var seen = knownTitles
            if let en = FileManager.default.enumerator(
                at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let url as URL in en {
                    guard Self.audioExtensions.contains(url.pathExtension.lowercased()) else { continue }
                    let title = url.deletingPathExtension().lastPathComponent
                    if seen.contains(title) { continue }
                    if let song = Self.copyIn(url) {
                        found.append(song)
                        seen.insert(title)
                    }
                }
            }

            DispatchQueue.main.async {
                self.songs.append(contentsOf: found)
                self.sortAndSave()
                self.isImporting = false
                completion(found.count)
            }
        }
    }

    func deleteSong(_ song: Song) {
        try? FileManager.default.removeItem(at: Self.fileURL(for: song))
        songs.removeAll { $0.id == song.id }
        for i in playlists.indices {
            playlists[i].songIDs.removeAll { $0 == song.id }
        }
        save()
    }

    func songs(in playlist: Playlist) -> [Song] {
        playlist.songIDs.compactMap { id in songs.first { $0.id == id } }
    }

    // MARK: Playlists

    func addPlaylist(name: String, emoji: String, colorIndex: Int) {
        playlists.append(Playlist(name: name, emoji: emoji, colorIndex: colorIndex))
        save()
    }

    func updatePlaylist(id: UUID, name: String, emoji: String, colorIndex: Int) {
        guard let i = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[i].name = name
        playlists[i].emoji = emoji
        playlists[i].colorIndex = colorIndex
        save()
    }

    func deletePlaylist(_ id: UUID) {
        playlists.removeAll { $0.id == id }
        save()
    }

    func setMembership(song: UUID, playlist: UUID, isMember: Bool) {
        guard let i = playlists.firstIndex(where: { $0.id == playlist }) else { return }
        let has = playlists[i].songIDs.contains(song)
        if isMember && !has { playlists[i].songIDs.append(song) }
        if !isMember && has { playlists[i].songIDs.removeAll { $0 == song } }
        save()
    }

    func removeSongs(at offsets: IndexSet, from playlist: UUID) {
        guard let i = playlists.firstIndex(where: { $0.id == playlist }) else { return }
        playlists[i].songIDs.remove(atOffsets: offsets)
        save()
    }

    func moveSongs(from source: IndexSet, to destination: Int, in playlist: UUID) {
        guard let i = playlists.firstIndex(where: { $0.id == playlist }) else { return }
        playlists[i].songIDs.move(fromOffsets: source, toOffset: destination)
        save()
    }
}
