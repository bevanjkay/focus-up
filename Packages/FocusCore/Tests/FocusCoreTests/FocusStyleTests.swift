import Testing

@testable import FocusCore

struct FocusStyleTests {
    @Test func onlyHideStylesHideWindows() {
        #expect(!FocusStyle.blur.hidesWindows)
        #expect(FocusStyle.hide.hidesWindows)
        #expect(FocusStyle.hideBlurred.hidesWindows)
    }

    @Test func blurIsTheDefaultStyle() {
        #expect(FocusStyle.allCases.first == .blur)
    }
}
