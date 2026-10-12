import AppKit

/// A screen's desktop picture and how to lay it out. `image` is nil while it can't be read or captured yet,
/// in which case only the fill colour shows.
struct Wallpaper: Equatable {
    let image: CGImage?
    let gravity: CALayerContentsGravity
    let fillColour: CGColor

    static func == (lhs: Wallpaper, rhs: Wallpaper) -> Bool {
        lhs.image === rhs.image && lhs.gravity == rhs.gravity && lhs.fillColour == rhs.fillColour
    }
}
