import AppKit
import Combine
import SwiftUI

final class IslandPanel: NSPanel {
    /// Called on a plain left click while the island is closed. Handled here, before SwiftUI, so it's instant.
    var onCollapsedClick: (() -> Void)?
    var isCollapsed: () -> Bool = { true }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown, isCollapsed(),
           !event.modifierFlags.contains(.control) {
            onCollapsedClick?()
            return
        }
        super.sendEvent(event)
    }
}

final class IslandHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Owns the panel that sits over the notch and resizes it as the island opens and closes.
final class IslandController {
    let panel: IslandPanel
    private let model: IslandModel
    private let nowPlaying: NowPlayingController
    private var bag = Set<AnyCancellable>()
    private var outsideMonitor: Any?
    private var keyMonitor: Any?
    private var shrinkToken = UUID()

    init(model: IslandModel,
         nowPlaying: NowPlayingController,
         battery: BatteryMonitor,
         shelf: ShelfStore,
         actions: ActionRunner,
         settings: IslandSettings,
         openSettings: @escaping () -> Void) {
        self.model = model
        self.nowPlaying = nowPlaying

        panel = IslandPanel(contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 2)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        let root = IslandView(openSettings: openSettings)
            .environmentObject(model)
            .environmentObject(nowPlaying)
            .environmentObject(battery)
            .environmentObject(shelf)
            .environmentObject(actions)
            .environmentObject(settings)
        let host = IslandHostingView(rootView: root)
        host.sizingOptions = []
        panel.contentView = host
        panel.isCollapsed = { [weak model] in !(model?.expanded ?? false) }
        panel.onCollapsedClick = { [weak model] in model?.open() }

        applyFrame(immediately: true)

        model.$expanded
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] expanded in self?.expandedChanged(expanded) }
            .store(in: &bag)

        nowPlaying.$isPlaying
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyFrame(immediately: false) }
            .store(in: &bag)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.model.refreshGeometry()
                self?.applyFrame(immediately: true)
            }
            .store(in: &bag)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel, self.model.expanded else { return event }
            switch event.keyCode {
            case 53: // esc
                self.model.close()
                return nil
            case 49: // space
                self.nowPlaying.playPause()
                return nil
            default:
                return event
            }
        }
    }

    func show() {
        panel.orderFrontRegardless()
    }

    private func expandedChanged(_ expanded: Bool) {
        if expanded {
            applyFrame(immediately: true)
            panel.makeKey()
            installOutsideMonitor()
            nowPlaying.pollInterval = 1
            nowPlaying.poll()
        } else {
            removeOutsideMonitor()
            nowPlaying.pollInterval = 2
            applyFrame(immediately: false)
        }
    }

    private func targetFrame() -> NSRect {
        model.windowFrame(expanded: model.expanded, compactPlaying: nowPlaying.isPlaying && !model.expanded)
    }

    /// Grow at once (the SwiftUI body animates inside); shrink only after the collapse animation.
    private func applyFrame(immediately: Bool) {
        let target = targetFrame()
        let grows = target.width > panel.frame.width + 0.5 || target.height > panel.frame.height + 0.5
        if immediately || grows {
            shrinkToken = UUID()
            panel.setFrame(target, display: true)
            return
        }
        let token = UUID()
        shrinkToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.shrinkToken == token else { return }
            self.panel.setFrame(self.targetFrame(), display: true)
        }
    }

    private func installOutsideMonitor() {
        removeOutsideMonitor()
        outsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.model.close()
        }
    }

    private func removeOutsideMonitor() {
        if let m = outsideMonitor {
            NSEvent.removeMonitor(m)
            outsideMonitor = nil
        }
    }
}
