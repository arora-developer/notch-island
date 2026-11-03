import AppKit

/// Files dropped onto the island are held here (by reference — nothing is moved until you drag one out).
final class ShelfStore: ObservableObject {
    @Published private(set) var items: [URL] = [] {
        didSet { save() }
    }

    init() {
        load()
    }

    func add(_ urls: [URL]) {
        var next = items
        for url in urls {
            let u = url.standardizedFileURL
            if !next.contains(u) { next.append(u) }
        }
        if next != items { items = next }
    }

    func remove(_ url: URL) {
        items.removeAll { $0 == url }
    }

    func clear() {
        items.removeAll()
    }

    private func save() {
        UserDefaults.standard.set(items.map { $0.path }, forKey: "shelfItems")
    }

    private func load() {
        let paths = UserDefaults.standard.stringArray(forKey: "shelfItems") ?? []
        items = paths.map { URL(fileURLWithPath: $0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
