import Testing

@testable import FocusCore

struct OverlayAppearanceTests {
    @Test func intensityScalesDimOnly() {
        let low = OverlayAppearance(intensity: 0)
        let high = OverlayAppearance(intensity: 1)
        #expect(low.dimOpacity < high.dimOpacity)
        #expect(low.dimOpacity > 0)
    }

    @Test func intensityIsClamped() {
        #expect(OverlayAppearance(intensity: 4) == OverlayAppearance(intensity: 1))
        #expect(OverlayAppearance(intensity: -1) == OverlayAppearance(intensity: 0))
    }
}
