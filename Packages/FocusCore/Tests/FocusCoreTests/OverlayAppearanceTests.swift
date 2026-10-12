import Testing

@testable import FocusCore

struct OverlayAppearanceTests {
    @Test func intensityScalesBlurAndDim() {
        let low = OverlayAppearance(intensity: 0)
        let high = OverlayAppearance(intensity: 1)
        #expect(low.blurOpacity < high.blurOpacity)
        #expect(low.dimOpacity == 0)
        #expect(high.blurOpacity == 1)
    }

    @Test func intensityIsClamped() {
        #expect(OverlayAppearance(intensity: 4) == OverlayAppearance(intensity: 1))
        #expect(OverlayAppearance(intensity: -1) == OverlayAppearance(intensity: 0))
    }
}
