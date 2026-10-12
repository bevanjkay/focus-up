import FocusCore
import SwiftUI

extension FocusStyle {
    var title: LocalizedStringResource {
        switch self {
        case .blur: "Blur"
        case .hide: "Hide (show desktop)"
        case .hideBlurred: "Hide (blur desktop)"
        }
    }
}
