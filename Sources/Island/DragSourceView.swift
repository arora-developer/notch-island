import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Transparent AppKit layer over a shelf chip: double-click opens, right-click shows a menu,
/// dragging out *moves* the file to wherever it's dropped (Desktop, a Finder window…) via a file promise.
struct DragSourceView: NSViewRepresentable {
    let url: URL
    let onOpen: () -> Void
    let onMoved: () -> Void
    let menu: () -> NSMenu

    func makeNSView(context: Context) -> FileDragView {
        let view = FileDragView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: FileDragView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: FileDragView) {
        view.url = url
        view.onOpen = onOpen
        view.onMoved = onMoved
        view.menuProvider = menu
    }
}

final class FileDragView: NSView, NSDraggingSource, NSFilePromiseProviderDelegate {
    var url: URL?
    var onOpen: (() -> Void)?
    var onMoved: (() -> Void)?
    var menuProvider: (() -> NSMenu)?

    private var mouseDownLocation: NSPoint = .zero
    private var dragStarted = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        dragStarted = false
        if event.clickCount == 2 { onOpen?() }
    }

    override func mouseDragged(with event: NSEvent) {
        guard !dragStarted, let url else { return }
        let location = event.locationInWindow
        guard hypot(location.x - mouseDownLocation.x, location.y - mouseDownLocation.y) > 5 else { return }
        dragStarted = true

        let typeIdentifier = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType?.identifier
            ?? UTType.data.identifier
        let provider = NSFilePromiseProvider(fileType: typeIdentifier, delegate: self)
        let draggingItem = NSDraggingItem(pasteboardWriter: provider)
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 48, height: 48)
        draggingItem.setDraggingFrame(NSRect(x: bounds.midX - 24, y: bounds.midY - 24, width: 48, height: 48), contents: icon)
        _ = beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    override func rightMouseDown(with event: NSEvent) {
        if let menu = menuProvider?() {
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? .move : []
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        url?.lastPathComponent ?? "item"
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             writePromiseTo destination: URL,
                             completionHandler: @escaping (Error?) -> Void) {
        guard let url else {
            completionHandler(nil)
            return
        }
        do {
            try FileManager.default.moveItem(at: url, to: destination)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
        onMoved?()
    }

    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        .main
    }
}

/// NSMenuItem that runs a closure.
final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, _ handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: "")
        target = self
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func fire() {
        handler()
    }
}

enum DropHandling {
    static func extractURLs(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        let lock = NSLock()
        var urls: [URL] = []
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                var url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let u = item as? URL {
                    url = u
                } else if let s = item as? String {
                    url = URL(string: s)
                }
                if let url {
                    lock.lock()
                    urls.append(url)
                    lock.unlock()
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { completion(urls) }
    }
}
