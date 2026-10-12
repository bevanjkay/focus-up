import FocusCore
import SwiftUI

extension FocusScope {
    var title: LocalizedStringResource {
        switch self {
        case .app: "App"
        case .window: "Window"
        }
    }
}

extension FocusStyle {
    var title: LocalizedStringResource {
        switch self {
        case .blur: "Blur"
        case .hide: "Hide (show desktop)"
        case .hideBlurred: "Hide (blur desktop)"
        }
    }
}
