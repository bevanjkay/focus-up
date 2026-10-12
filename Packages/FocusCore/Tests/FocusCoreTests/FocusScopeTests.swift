import Testing

@testable import FocusCore

@Test func appIsTheDefaultScope() {
    #expect(FocusScope.allCases.first == .app)
}
