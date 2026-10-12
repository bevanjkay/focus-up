/// Maps the single Intensity setting to the Overlay's dim. The blur itself always stays fully opaque, because a
/// partially transparent blur lets sharp content ghost through.
public struct OverlayAppearance: Equatable, Sendable {
    public static let defaultIntensity = 0.5

    public let dimOpacity: Double

    public init(intensity: Double) {
        let clamped = min(max(intensity, 0), 1)
        dimOpacity = 0.05 + 0.5 * clamped
    }
}
