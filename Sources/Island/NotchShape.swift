import SwiftUI

/// The island outline: flared top corners that blend into the menu bar (like the hardware notch),
/// straight sides, rounded bottom corners. The rect includes the ears; the body is inset by `earRadius`.
struct NotchShape: Shape {
    var earRadius: CGFloat
    var cornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(earRadius, cornerRadius) }
        set {
            earRadius = newValue.first
            cornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let e = max(0, earRadius)
        let x0 = rect.minX + e
        let x1 = rect.maxX - e
        let r = max(0, min(cornerRadius, (x1 - x0) / 2, rect.height / 2))

        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: x0, y: rect.minY + e), control: CGPoint(x: x0, y: rect.minY))
        p.addLine(to: CGPoint(x: x0, y: rect.maxY - r))
        p.addArc(tangent1End: CGPoint(x: x0, y: rect.maxY), tangent2End: CGPoint(x: x0 + r, y: rect.maxY), radius: r)
        p.addLine(to: CGPoint(x: x1 - r, y: rect.maxY))
        p.addArc(tangent1End: CGPoint(x: x1, y: rect.maxY), tangent2End: CGPoint(x: x1, y: rect.maxY - r), radius: r)
        p.addLine(to: CGPoint(x: x1, y: rect.minY + e))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: x1, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
