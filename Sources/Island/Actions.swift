import AppKit
import ServiceManagement
import SwiftUI

extension Color {
    /// "#RRGGBB" → Color (sRGB). Nil if the string doesn't parse.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255,
                  opacity: 1)
    }

    var hexString: String? {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int((c.redComponent * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

enum ActionType: String, Codable, CaseIterable, Identifiable {
    case builtin, openApp, openURL, shortcut, shell

    var id: String { rawValue }

    var label: String {
        switch self {
        case .builtin: return "Built-in"
        case .openApp: return "Open app"
        case .openURL: return "Open URL"
        case .shortcut: return "Run Shortcut"
        case .shell: return "Shell command"
        }
    }

    var placeholder: String {
        switch self {
        case .builtin: return ""
        case .openApp: return "App name, e.g. Fusion 360"
        case .openURL: return "https://…"
        case .shortcut: return "Shortcut name"
        case .shell: return "open ~/Downloads"
        }
    }
}

enum Builtin: String, CaseIterable, Identifiable {
    // Capture
    case screenshot, screenshotClipboard
    // System toggles
    case caffeine, darkMode, mute, volumeUp, volumeDown, wifiToggle, dockAutohide, stageManager, hiddenFiles
    // Windows & navigation
    case missionControl, showDesktop, launchpad, spotlight
    // Power
    case lockScreen, sleepDisplay, sleep, restart, shutDown
    // Files & disks
    case emptyTrash, ejectDisks, openDownloads, openDesktop, openDocuments, openScreenshots
    // Apps
    case openTerminal, openActivityMonitor, openSystemSettings, openCalculator, openNotes, newEmail
    // Clipboard & network
    case copyIP, clearClipboard

    var id: String { rawValue }

    /// Group heading in the "Add button" menu.
    var group: String {
        switch self {
        case .screenshot, .screenshotClipboard: return "Capture"
        case .caffeine, .darkMode, .mute, .volumeUp, .volumeDown, .wifiToggle, .dockAutohide, .stageManager, .hiddenFiles: return "Toggles"
        case .missionControl, .showDesktop, .launchpad, .spotlight: return "Windows"
        case .lockScreen, .sleepDisplay, .sleep, .restart, .shutDown: return "Power"
        case .emptyTrash, .ejectDisks, .openDownloads, .openDesktop, .openDocuments, .openScreenshots: return "Files"
        case .openTerminal, .openActivityMonitor, .openSystemSettings, .openCalculator, .openNotes, .newEmail: return "Apps"
        case .copyIP, .clearClipboard: return "Clipboard"
        }
    }

    static var groups: [String] { ["Capture", "Toggles", "Windows", "Power", "Files", "Apps", "Clipboard"] }

    var label: String {
        switch self {
        case .screenshot: return "Screenshot (⌘⇧5 panel)"
        case .screenshotClipboard: return "Screenshot area → clipboard"
        case .caffeine: return "Caffeine (keep awake)"
        case .darkMode: return "Toggle dark mode"
        case .mute: return "Mute / unmute"
        case .volumeUp: return "Volume up"
        case .volumeDown: return "Volume down"
        case .wifiToggle: return "Toggle Wi-Fi"
        case .dockAutohide: return "Toggle Dock auto-hide"
        case .stageManager: return "Toggle Stage Manager"
        case .hiddenFiles: return "Toggle hidden files in Finder"
        case .missionControl: return "Mission Control"
        case .showDesktop: return "Show Desktop"
        case .launchpad: return "Launchpad"
        case .spotlight: return "Spotlight"
        case .lockScreen: return "Lock screen"
        case .sleepDisplay: return "Sleep display"
        case .sleep: return "Sleep Mac"
        case .restart: return "Restart… (asks first)"
        case .shutDown: return "Shut down… (asks first)"
        case .emptyTrash: return "Empty Trash"
        case .ejectDisks: return "Eject all disks"
        case .openDownloads: return "Open Downloads"
        case .openDesktop: return "Open Desktop folder"
        case .openDocuments: return "Open Documents"
        case .openScreenshots: return "Open Screenshots folder"
        case .openTerminal: return "Open Terminal"
        case .openActivityMonitor: return "Open Activity Monitor"
        case .openSystemSettings: return "Open System Settings"
        case .openCalculator: return "Open Calculator"
        case .openNotes: return "Open Notes"
        case .newEmail: return "New email"
        case .copyIP: return "Copy local IP address"
        case .clearClipboard: return "Clear clipboard"
        }
    }

    var defaultSymbol: String {
        switch self {
        case .screenshot: return "camera.viewfinder"
        case .screenshotClipboard: return "camera.on.rectangle"
        case .caffeine: return "cup.and.saucer.fill"
        case .darkMode: return "moon.fill"
        case .mute: return "speaker.slash.fill"
        case .volumeUp: return "speaker.wave.3.fill"
        case .volumeDown: return "speaker.wave.1.fill"
        case .wifiToggle: return "wifi"
        case .dockAutohide: return "dock.rectangle"
        case .stageManager: return "squares.leading.rectangle"
        case .hiddenFiles: return "eye.fill"
        case .missionControl: return "rectangle.3.group"
        case .showDesktop: return "menubar.dock.rectangle"
        case .launchpad: return "square.grid.3x3.fill"
        case .spotlight: return "magnifyingglass"
        case .lockScreen: return "lock.fill"
        case .sleepDisplay: return "display"
        case .sleep: return "moon.zzz.fill"
        case .restart: return "arrow.clockwise.circle.fill"
        case .shutDown: return "power"
        case .emptyTrash: return "trash.fill"
        case .ejectDisks: return "eject.fill"
        case .openDownloads: return "arrow.down.circle.fill"
        case .openDesktop: return "menubar.dock.rectangle.badge.record"
        case .openDocuments: return "doc.fill"
        case .openScreenshots: return "photo.on.rectangle"
        case .openTerminal: return "terminal.fill"
        case .openActivityMonitor: return "waveform.path.ecg"
        case .openSystemSettings: return "gearshape.2.fill"
        case .openCalculator: return "plus.forwardslash.minus"
        case .openNotes: return "note.text"
        case .newEmail: return "envelope.fill"
        case .copyIP: return "network"
        case .clearClipboard: return "doc.on.clipboard"
        }
    }

    var defaultTitle: String {
        switch self {
        case .screenshot: return "Screenshot"
        case .screenshotClipboard: return "Snip"
        case .caffeine: return "Caffeine"
        case .darkMode: return "Dark Mode"
        case .mute: return "Mute"
        case .volumeUp: return "Vol +"
        case .volumeDown: return "Vol −"
        case .wifiToggle: return "Wi-Fi"
        case .dockAutohide: return "Dock"
        case .stageManager: return "Stage Mgr"
        case .hiddenFiles: return "Hidden"
        case .missionControl: return "Mission Ctrl"
        case .showDesktop: return "Desktop"
        case .launchpad: return "Launchpad"
        case .spotlight: return "Spotlight"
        case .lockScreen: return "Lock"
        case .sleepDisplay: return "Display Off"
        case .sleep: return "Sleep"
        case .restart: return "Restart"
        case .shutDown: return "Shut Down"
        case .emptyTrash: return "Empty Trash"
        case .ejectDisks: return "Eject"
        case .openDownloads: return "Downloads"
        case .openDesktop: return "Desktop"
        case .openDocuments: return "Documents"
        case .openScreenshots: return "Screenshots"
        case .openTerminal: return "Terminal"
        case .openActivityMonitor: return "Activity"
        case .openSystemSettings: return "Settings"
        case .openCalculator: return "Calc"
        case .openNotes: return "Notes"
        case .newEmail: return "Email"
        case .copyIP: return "Copy IP"
        case .clearClipboard: return "Clear Clip"
        }
    }

    /// Toggles stay open so you can see the new state.
    var keepsIslandOpen: Bool {
        switch self {
        case .caffeine, .mute, .volumeUp, .volumeDown, .wifiToggle, .dockAutohide, .stageManager, .hiddenFiles: return true
        default: return false
        }
    }
}

struct QuickAction: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var title: String
    var symbol: String
    var type: ActionType
    var param: String

    static func builtin(_ b: Builtin) -> QuickAction {
        QuickAction(title: b.defaultTitle, symbol: b.defaultSymbol, type: .builtin, param: b.rawValue)
    }

    /// Toggles stay open so you can see the new state.
    var keepsIslandOpen: Bool {
        guard type == .builtin, let b = Builtin(rawValue: param) else { return false }
        return b.keepsIslandOpen
    }

    static let defaults: [QuickAction] = [
        .builtin(.screenshot),
        .builtin(.caffeine),
        .builtin(.darkMode),
        .builtin(.mute),
        .builtin(.lockScreen),
        .builtin(.missionControl),
        .builtin(.openDownloads),
    ]
}

struct SettingsData: Codable {
    var actions: [QuickAction]
    var launchAtLogin: Bool
    var accentHex: String?
    var outlineEnabled: Bool?
}

/// Persisted settings: ~/Library/Application Support/Island/settings.json
final class IslandSettings: ObservableObject {
    static let shared = IslandSettings()
    static let defaultAccent = "#4F8CFF"
    static let presetAccents = ["#4F8CFF", "#30D158", "#FF9F0A", "#FF375F", "#BF5AF2", "#64D2FF", "#FFFFFF"]

    @Published var actions: [QuickAction] {
        didSet { save() }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            save()
            applyLaunchAtLogin()
        }
    }
    /// Outline colour of the open island, as #RRGGBB.
    @Published var accentHex: String {
        didSet { save() }
    }
    @Published var outlineEnabled: Bool {
        didSet { save() }
    }
    @Published var hotKeyActive = false

    var accentColor: Color {
        Color(hex: accentHex) ?? Color(hex: IslandSettings.defaultAccent) ?? .blue
    }

    private let fileURL: URL

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("Island", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("settings.json")
        fileURL = url

        if let data = try? Data(contentsOf: url),
           let loaded = try? JSONDecoder().decode(SettingsData.self, from: data) {
            actions = loaded.actions
            launchAtLogin = loaded.launchAtLogin
            accentHex = loaded.accentHex ?? IslandSettings.defaultAccent
            outlineEnabled = loaded.outlineEnabled ?? true
        } else {
            actions = QuickAction.defaults
            launchAtLogin = false
            accentHex = IslandSettings.defaultAccent
            outlineEnabled = true
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = SettingsData(actions: actions, launchAtLogin: launchAtLogin, accentHex: accentHex, outlineEnabled: outlineEnabled)
        if let encoded = try? encoder.encode(data) {
            try? encoded.write(to: fileURL, options: .atomic)
        }
    }

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Island: launch at login change failed: \(error)")
        }
    }
}

/// Runs quick actions.
final class ActionRunner: ObservableObject {
    @Published private(set) var caffeineOn = false
    private var caffeinate: Process?

    func isActive(_ action: QuickAction) -> Bool {
        action.type == .builtin && action.param == Builtin.caffeine.rawValue && caffeineOn
    }

    func run(_ action: QuickAction) {
        switch action.type {
        case .builtin:
            if let b = Builtin(rawValue: action.param) { runBuiltin(b) }
        case .openApp:
            launch("/usr/bin/open", ["-a", action.param])
        case .openURL:
            if let url = URL(string: action.param) { NSWorkspace.shared.open(url) }
        case .shortcut:
            launch("/usr/bin/shortcuts", ["run", action.param])
        case .shell:
            launch("/bin/zsh", ["-lc", action.param])
        }
    }

    private func runBuiltin(_ b: Builtin) {
        switch b {
        // Capture
        case .screenshot:
            launch("/usr/bin/open", ["-b", "com.apple.screenshot.launcher"])
        case .screenshotClipboard:
            launch("/usr/sbin/screencapture", ["-ic"])

        // Toggles
        case .caffeine:
            toggleCaffeine()
        case .darkMode:
            appleScript("tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode")
        case .mute:
            appleScript("set volume output muted not (output muted of (get volume settings))")
        case .volumeUp:
            appleScript("set v to (output volume of (get volume settings)) + 10\nif v > 100 then set v to 100\nset volume output volume v")
        case .volumeDown:
            appleScript("set v to (output volume of (get volume settings)) - 10\nif v < 0 then set v to 0\nset volume output volume v")
        case .wifiToggle:
            shell("if /usr/sbin/networksetup -getairportpower en0 | grep -q 'On'; then /usr/sbin/networksetup -setairportpower en0 off; else /usr/sbin/networksetup -setairportpower en0 on; fi")
        case .dockAutohide:
            appleScript("tell application \"System Events\" to tell dock preferences to set autohide to not autohide")
        case .stageManager:
            shell("if [ \"$(defaults read com.apple.WindowManager GloballyEnabled 2>/dev/null)\" = \"1\" ]; then defaults write com.apple.WindowManager GloballyEnabled -bool false; else defaults write com.apple.WindowManager GloballyEnabled -bool true; fi")
        case .hiddenFiles:
            shell("if [ \"$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)\" = \"1\" ]; then defaults write com.apple.finder AppleShowAllFiles -bool false; else defaults write com.apple.finder AppleShowAllFiles -bool true; fi; killall Finder")

        // Windows
        case .missionControl:
            launch("/usr/bin/open", ["-b", "com.apple.exposelauncher"])
        case .showDesktop:
            appleScript("tell application \"System Events\" to key code 103")
        case .launchpad:
            launch("/usr/bin/open", ["-b", "com.apple.launchpad.launcher"])
        case .spotlight:
            appleScript("tell application \"System Events\" to keystroke space using command down")

        // Power
        case .lockScreen:
            launch("/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession", ["-suspend"])
        case .sleepDisplay:
            launch("/usr/bin/pmset", ["displaysleepnow"])
        case .sleep:
            launch("/usr/bin/pmset", ["sleepnow"])
        case .restart:
            confirm("Restart now?", "Open apps will be asked to close.") { [self] in
                appleScript("tell application \"System Events\" to restart")
            }
        case .shutDown:
            confirm("Shut down now?", "Open apps will be asked to close.") { [self] in
                appleScript("tell application \"System Events\" to shut down")
            }

        // Files
        case .emptyTrash:
            appleScript("tell application \"Finder\" to empty trash")
        case .ejectDisks:
            appleScript("tell application \"Finder\" to eject (every disk whose ejectable is true)")
        case .openDownloads:
            shell("open ~/Downloads")
        case .openDesktop:
            shell("open ~/Desktop")
        case .openDocuments:
            shell("open ~/Documents")
        case .openScreenshots:
            shell("open \"$(defaults read com.apple.screencapture location 2>/dev/null || echo ~/Desktop)\"")

        // Apps
        case .openTerminal:
            launch("/usr/bin/open", ["-a", "Terminal"])
        case .openActivityMonitor:
            launch("/usr/bin/open", ["-a", "Activity Monitor"])
        case .openSystemSettings:
            launch("/usr/bin/open", ["-a", "System Settings"])
        case .openCalculator:
            launch("/usr/bin/open", ["-a", "Calculator"])
        case .openNotes:
            launch("/usr/bin/open", ["-a", "Notes"])
        case .newEmail:
            launch("/usr/bin/open", ["mailto:"])

        // Clipboard
        case .copyIP:
            shell("ipconfig getifaddr en0 | tr -d '\\n' | pbcopy")
        case .clearClipboard:
            shell("pbcopy < /dev/null")
        }
    }

    private func shell(_ command: String) {
        launch("/bin/zsh", ["-lc", command])
    }

    private func confirm(_ title: String, _ message: String, then action: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: title.replacingOccurrences(of: " now?", with: ""))
            alert.addButton(withTitle: "Cancel")
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn { action() }
        }
    }

    private func toggleCaffeine() {
        if let p = caffeinate {
            p.terminate()
            caffeinate = nil
            caffeineOn = false
            return
        }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = ["-dis"]
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.caffeinate = nil
                self?.caffeineOn = false
            }
        }
        do {
            try p.run()
            caffeinate = p
            caffeineOn = true
        } catch {
            NSSound.beep()
        }
    }

    private func launch(_ path: String, _ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        do {
            try p.run()
        } catch {
            NSSound.beep()
            NSLog("Island: could not run \(path): \(error)")
        }
    }

    private func appleScript(_ source: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = AppleScriptRunner.run(source)
        }
    }
}

/// Runs AppleScript through `osascript` so it can go on a background queue.
enum AppleScriptRunner {
    static func run(_ source: String) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", source]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        do {
            try p.run()
        } catch {
            return nil
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
