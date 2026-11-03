import AppKit
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ButtonsTab()
                .tabItem { Label("Buttons", systemImage: "square.grid.2x2") }
            GeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 600, height: 440)
    }
}

/// Edit, reorder and add the quick-action buttons shown in the island.
struct ButtonsTab: View {
    @EnvironmentObject var settings: IslandSettings

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach($settings.actions) { $action in
                    ActionRow(action: $action)
                }
                .onMove { from, to in settings.actions.move(fromOffsets: from, toOffset: to) }
                .onDelete { offsets in settings.actions.remove(atOffsets: offsets) }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            HStack {
                Menu {
                    ForEach(Builtin.groups, id: \.self) { group in
                        Section(group) {
                            ForEach(Builtin.allCases.filter { $0.group == group }) { b in
                                Button(b.label) { settings.actions.append(.builtin(b)) }
                            }
                        }
                    }
                    Section("Custom") {
                        Button("Open an app…") { settings.actions.append(QuickAction(title: "App", symbol: "app.fill", type: .openApp, param: "")) }
                        Button("Open a URL…") { settings.actions.append(QuickAction(title: "Link", symbol: "link", type: .openURL, param: "https://")) }
                        Button("Run a Shortcut…") { settings.actions.append(QuickAction(title: "Shortcut", symbol: "wand.and.stars", type: .shortcut, param: "")) }
                        Button("Shell command…") { settings.actions.append(QuickAction(title: "Command", symbol: "terminal.fill", type: .shell, param: "")) }
                    }
                } label: {
                    Label("Add button", systemImage: "plus")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Spacer()
                Text("Icons are SF Symbol names (browse them in the SF Symbols app). Drag rows to reorder, swipe or ⌫ to delete.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(12)
        }
    }
}

struct ActionRow: View {
    @Binding var action: QuickAction

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: action.symbol.isEmpty ? "questionmark" : action.symbol)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 26)
            TextField("Title", text: $action.title)
                .textFieldStyle(.roundedBorder)
                .frame(width: 110)
            TextField("SF Symbol", text: $action.symbol)
                .textFieldStyle(.roundedBorder)
                .frame(width: 140)
            Picker("", selection: $action.type) {
                ForEach(ActionType.allCases) { t in
                    Text(t.label).tag(t)
                }
            }
            .labelsHidden()
            .frame(width: 120)
            if action.type == .builtin {
                Picker("", selection: $action.param) {
                    ForEach(Builtin.allCases) { b in
                        Text(b.label).tag(b.rawValue)
                    }
                }
                .labelsHidden()
            } else {
                TextField(action.type.placeholder, text: $action.param)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, 3)
    }
}

struct GeneralTab: View {
    @EnvironmentObject var settings: IslandSettings

    private var accentBinding: Binding<Color> {
        Binding(get: { settings.accentColor },
                set: { newColor in
                    if let hex = newColor.hexString { settings.accentHex = hex }
                })
    }

    var body: some View {
        Form {
            Section("Shortcut") {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("fn + W  opens and closes the island")
                            .font(.body.weight(.medium))
                        Text("Needs Accessibility access so the Globe key can be seen from any app. Clicking the notch always works.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if settings.hotKeyActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant access…") {
                            _ = AccessibilityAccess.isTrusted(prompt: true)
                            AccessibilityAccess.openSystemSettings()
                        }
                    }
                }
            }
            Section("Outline") {
                Toggle("Show a coloured outline when the island is open", isOn: $settings.outlineEnabled)
                HStack(spacing: 10) {
                    ColorPicker("Colour", selection: accentBinding, supportsOpacity: false)
                    Spacer()
                    ForEach(IslandSettings.presetAccents, id: \.self) { hex in
                        Button {
                            settings.accentHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().strokeBorder(Color.primary.opacity(settings.accentHex.uppercased() == hex ? 0.9 : 0.15), lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .help(hex)
                    }
                }
                .disabled(!settings.outlineEnabled)
            }
            Section("General") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Text("Click or hover the notch to open it. Drop files on it to hold them on the shelf. Right-click the notch for this window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                HStack {
                    Spacer()
                    Button("Quit Island", role: .destructive) { NSApp.terminate(nil) }
                }
            }
        }
        .formStyle(.grouped)
    }
}

/// Standard window hosting the settings.
final class SettingsWindowController {
    private var window: NSWindow?

    func show(settings: IslandSettings) {
        if window == nil {
            let host = NSHostingView(rootView: SettingsView().environmentObject(settings))
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 440),
                             styleMask: [.titled, .closable, .miniaturizable],
                             backing: .buffered,
                             defer: false)
            w.title = "Island"
            w.contentView = host
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
