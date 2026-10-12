/// Maps the single Intensity setting to the Overlay's blur and dim opacity.
public struct OverlayAppearance: Equatable, Sendable {
    public static let defaultIntensity = 0.6

    public let blurOpacity: Double
    public let dimOpacity: Double

    public init(intensity: Double) {
        let clamped = min(max(intensity, 0), 1)
        blurOpacity = 0.5 + 0.5 * clamped
        dimOpacity = 0.45 * clamped
    }
}
