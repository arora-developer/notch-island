import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Root view inside the panel: the black island shape, top-centred, plus whatever state it's in.
struct IslandView: View {
    @EnvironmentObject var model: IslandModel
    @EnvironmentObject var nowPlaying: NowPlayingController
    @EnvironmentObject var shelf: ShelfStore
    @EnvironmentObject var settings: IslandSettings
    let openSettings: () -> Void

    var body: some View {
        let expanded = model.expanded
        let compact = !expanded && nowPlaying.isPlaying
        let hovering = !expanded && (model.hovering || model.dropTargeted)
        let size = model.bodySize(expanded: expanded, compactPlaying: compact, hovering: hovering)
        let frameW = size.width + model.ear * 2
        let notchH = model.geometry.notchHeight
        let corner: CGFloat = expanded ? 28 : 11

        ZStack(alignment: .top) {
            // Transparent catch-all: a click anywhere outside the island closes it.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { model.close() }

            ZStack(alignment: .top) {
                NotchShape(earRadius: model.ear, cornerRadius: corner)
                    .fill(Color.black)
                    .shadow(color: Color.black.opacity(expanded ? 0.55 : 0), radius: 16, x: 0, y: 10)

                // Outline, only while open. Colour lives in Settings.
                if expanded && settings.outlineEnabled {
                    NotchShape(earRadius: model.ear, cornerRadius: corner)
                        .stroke(settings.accentColor, lineWidth: 1.5)
                        .shadow(color: settings.accentColor.opacity(0.55), radius: 6)
                        .transition(.opacity)
                }

                if expanded {
                    ExpandedContent(openSettings: openSettings)
                        .frame(width: size.width - 28, alignment: .top)
                        .padding(.horizontal, 14)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                } else if compact {
                    CompactNowPlaying(width: size.width, notchWidth: model.geometry.hasNotch ? model.geometry.notchWidth : 0, height: notchH)
                        .transition(.opacity)
                }
            }
            .frame(width: frameW, height: size.height, alignment: .top)
            .contentShape(NotchShape(earRadius: model.ear, cornerRadius: 11))
            .onHover { model.hovering = $0 }
            // Opening on click is handled in IslandPanel.sendEvent (instant, no gesture recogniser lag).
            .contextMenu {
                Button("Settings…") { openSettings() }
                Divider()
                Button("Quit Island") { NSApp.terminate(nil) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(IslandModel.spring, value: expanded)
        .animation(IslandModel.spring, value: hovering)
        .animation(IslandModel.spring, value: compact)
        .onDrop(of: [.fileURL], isTargeted: $model.dropTargeted) { providers in
            DropHandling.extractURLs(from: providers) { urls in
                shelf.add(urls)
                model.open()
            }
            return true
        }
        .onChange(of: model.dropTargeted) { targeted in
            if targeted { model.open() }
        }
    }
}

// MARK: - Expanded

struct ExpandedContent: View {
    @EnvironmentObject var model: IslandModel
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            TopStrip(openSettings: openSettings)
                .frame(height: model.geometry.notchHeight)
            NowPlayingView()
            QuickActionsRow(width: model.expandedWidth - 28)
            ShelfView()
        }
        .padding(.bottom, 14)
    }
}

/// The row that shares the height of the hardware notch: just the settings and close buttons, right of the camera.
struct TopStrip: View {
    @EnvironmentObject var model: IslandModel
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            IconButton(symbol: "gearshape.fill") {
                openSettings()
                model.close()
            }
            IconButton(symbol: "xmark") { model.close() }
        }
        .padding(.horizontal, 4)
    }
}

struct IconButton: View {
    let symbol: String
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.white.opacity(hover ? 0.22 : 0.1)))
        }
        .buttonStyle(PressStyle())
        .onHover { hover = $0 }
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Now playing

struct NowPlayingView: View {
    @EnvironmentObject var nowPlaying: NowPlayingController

    var body: some View {
        let hasPlayer = nowPlaying.player != nil
        HStack(spacing: 14) {
            Artwork(image: nowPlaying.track?.artwork, size: 60)
            VStack(alignment: .leading, spacing: 3) {
                Text(nowPlaying.track?.title ?? "Nothing playing")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(nowPlaying.track?.artist ?? (hasPlayer ? "Paused" : "Open Music or Spotify"))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                ProgressBar(progress: nowPlaying.progress)
                    .frame(height: 3)
                    .padding(.top, 6)
            }
            Spacer(minLength: 10)
            HStack(spacing: 14) {
                ControlButton(symbol: "backward.fill", size: 15) { nowPlaying.previous() }
                ControlButton(symbol: nowPlaying.isPlaying ? "pause.fill" : "play.fill", size: 22) { nowPlaying.playPause() }
                ControlButton(symbol: "forward.fill", size: 15) { nowPlaying.next() }
            }
            .opacity(hasPlayer ? 1 : 0.3)
            .disabled(!hasPlayer)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.07)))
    }
}

struct Artwork: View {
    let image: NSImage?
    let size: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(colors: [Color(white: 0.3), Color(white: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 3)
    }
}

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.18))
                Capsule().fill(Color.white.opacity(0.9))
                    .frame(width: max(3, g.size.width * progress))
            }
        }
        .animation(.linear(duration: 0.9), value: progress)
    }
}

struct ControlButton: View {
    let symbol: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - Compact (closed, music playing): artwork on the left ear, bars on the right

struct CompactNowPlaying: View {
    @EnvironmentObject var nowPlaying: NowPlayingController
    let width: CGFloat
    let notchWidth: CGFloat
    let height: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Artwork(image: nowPlaying.track?.artwork, size: max(14, height - 12))
                .padding(.leading, 12)
            Spacer(minLength: notchWidth + 8)
            EqualizerBars()
                .frame(width: 18, height: 14)
                .padding(.trailing, 16)
        }
        .frame(width: width, height: height)
    }
}

struct EqualizerBars: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    let phase = t * (2.2 + Double(i) * 0.6) + Double(i) * 1.3
                    let h = 0.3 + 0.7 * abs(sin(phase))
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white)
                        .frame(width: 3, height: 14 * h)
                }
            }
            .frame(height: 14, alignment: .bottom)
        }
    }
}

// MARK: - Quick actions

/// Buttons are centred when they fit; the row scrolls sideways when there are more than fit.
struct QuickActionsRow: View {
    @EnvironmentObject var settings: IslandSettings
    @EnvironmentObject var actions: ActionRunner
    @EnvironmentObject var model: IslandModel
    let width: CGFloat

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(settings.actions) { action in
                    ActionChip(action: action, active: actions.isActive(action), accent: settings.accentColor) {
                        actions.run(action)
                        if !action.keepsIslandOpen { model.close() }
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            .frame(minWidth: width)
        }
        .frame(width: width)
    }
}

struct ActionChip: View {
    let action: QuickAction
    let active: Bool
    let accent: Color
    let tap: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: tap) {
            VStack(spacing: 6) {
                Image(systemName: action.symbol.isEmpty ? "questionmark" : action.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(height: 20)
                Text(action.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(active ? Color.black : Color.white)
            .frame(width: 72, height: 58)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(active ? accent : Color.white.opacity(hover ? 0.17 : 0.08))
            )
        }
        .buttonStyle(PressStyle())
        .onHover { hover = $0 }
        .help(action.title)
    }
}

// MARK: - Shelf

struct ShelfView: View {
    @EnvironmentObject var shelf: ShelfStore

    var body: some View {
        Group {
            if shelf.items.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down")
                    Text("Drop files here to hold them")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .foregroundStyle(.white.opacity(0.22))
                )
            } else {
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(shelf.items, id: \.self) { url in
                                ShelfChip(url: url)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    Button { shelf.clear() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Clear shelf")
                }
                .frame(height: 46)
            }
        }
    }
}

struct ShelfChip: View {
    @EnvironmentObject var shelf: ShelfStore
    let url: URL

    var body: some View {
        HStack(spacing: 7) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 22, height: 22)
            Text(url.lastPathComponent)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: 120)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.1)))
        .overlay(
            DragSourceView(url: url,
                           onOpen: { NSWorkspace.shared.open(url) },
                           onMoved: { shelf.remove(url) },
                           menu: { contextMenu })
        )
        .help(url.path)
    }

    private var icon: NSImage {
        let image = NSWorkspace.shared.icon(forFile: url.path)
        image.size = NSSize(width: 22, height: 22)
        return image
    }

    private var contextMenu: NSMenu {
        let menu = NSMenu()
        menu.addItem(ClosureMenuItem("Open") { NSWorkspace.shared.open(url) })
        menu.addItem(ClosureMenuItem("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) })
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem("Remove from Shelf") { shelf.remove(url) })
        return menu
    }
}
