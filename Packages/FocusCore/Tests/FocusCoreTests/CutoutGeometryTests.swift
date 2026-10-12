import CoreGraphics
import Testing

@testable import FocusCore

struct CutoutGeometryTests {
    @Test func flipsToBottomLeftOriginOnPrimaryDisplay() {
        let rects = CutoutGeometry.localRects(
            for: [CGRect(x: 100, y: 40, width: 200, height: 100)], in: mainDisplay.frame)
        #expect(rects == [CGRect(x: 100, y: 1300, width: 200, height: 100)])
    }

    @Test func offsetsBySecondaryDisplayOrigin() {
        let rects = CutoutGeometry.localRects(
            for: [CGRect(x: 3540, y: 245, width: 200, height: 100)], in: laptopDisplay.frame)
        #expect(rects == [CGRect(x: 100, y: 917, width: 200, height: 100)])
    }

    @Test func clipsWindowsSpanningDisplays() {
        let rects = CutoutGeometry.localRects(
            for: [CGRect(x: 3340, y: 200, width: 200, height: 100)], in: laptopDisplay.frame)
        #expect(rects == [CGRect(x: 0, y: 962, width: 100, height: 100)])
    }

    @Test func dropsWindowsOnOtherDisplays() {
        #expect(
            CutoutGeometry.localRects(for: [CGRect(x: 0, y: 0, width: 10, height: 10)], in: laptopDisplay.frame).isEmpty
        )
    }
}
