import AppKit
import SwiftUI

/// Open/closed state and the geometry of the black body for each state.
final class IslandModel: ObservableObject {
    @Published var expanded = false
    @Published var hovering = false
    @Published var dropTargeted = false
    @Published private(set) var geometry = NotchGeometry.current()

    /// How far the top corners flare out to meet the menu bar (like the real notch).
    let ear: CGFloat = 8
    let expandedWidth: CGFloat = 560
    let expandedBodyHeight: CGFloat = 238
    /// Extra width on each side when music is playing and the island is closed.
    let compactEar: CGFloat = 78
    let shadowPad: CGFloat = 30

    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.78)

    func refreshGeometry() {
        geometry = NotchGeometry.current()
    }

    func open() {
        if !expanded { expanded = true }
    }

    func close() {
        if expanded { expanded = false }
        hovering = false
    }

    func toggle() {
        expanded.toggle()
        hovering = false
    }

    /// Size of the black body, not counting the ears.
    func bodySize(expanded: Bool, compactPlaying: Bool, hovering: Bool) -> CGSize {
        let g = geometry
        if expanded {
            return CGSize(width: expandedWidth, height: g.notchHeight + expandedBodyHeight)
        }
        if !g.hasNotch {
            return CGSize(width: compactPlaying ? 220 : 150, height: compactPlaying ? g.notchHeight : 10)
        }
        var w = g.notchWidth
        var h = g.notchHeight
        if compactPlaying { w += compactEar * 2 }
        if hovering {
            w += 14
            h += 5
        }
        return CGSize(width: w, height: h)
    }

    /// Window frame for a state (screen coordinates). Leaves room for hover growth and the shadow.
    func windowFrame(expanded: Bool, compactPlaying: Bool) -> NSRect {
        let g = geometry
        let body = bodySize(expanded: expanded, compactPlaying: compactPlaying, hovering: true)
        let pad: CGFloat = expanded ? shadowPad : 0
        let w = body.width + ear * 2 + pad * 2
        let h = body.height + pad
        return NSRect(x: (g.screenFrame.midX - w / 2).rounded(),
                      y: g.screenFrame.maxY - h,
                      width: w,
                      height: h)
    }
}
