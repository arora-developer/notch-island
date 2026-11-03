import AppKit
import IOKit.ps

/// Battery level and charging state, refreshed every 30 s.
final class BatteryMonitor: ObservableObject {
    @Published private(set) var level: Int?
    @Published private(set) var charging = false
    @Published private(set) var onAC = false

    private var timer: Timer?

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        var found = false
        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?.takeUnretainedValue() as? [String: Any] else { continue }
            guard let capacity = info[kIOPSCurrentCapacityKey as String] as? Int else { continue }
            level = capacity
            charging = info[kIOPSIsChargingKey as String] as? Bool ?? false
            onAC = (info[kIOPSPowerSourceStateKey as String] as? String) == (kIOPSACPowerValue as String)
            found = true
            break
        }
        if !found { level = nil }
    }

    var symbolName: String {
        guard let level else { return "battery.100" }
        if charging || onAC { return "battery.100.bolt" }
        switch level {
        case 0..<13: return "battery.0"
        case 13..<38: return "battery.25"
        case 38..<63: return "battery.50"
        case 63..<88: return "battery.75"
        default: return "battery.100"
        }
    }
}
