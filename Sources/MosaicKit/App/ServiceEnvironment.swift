import SwiftUI

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue: AppServices = fatalError("AppServices not installed in environment")
}

extension EnvironmentValues {
    /// The shared service bundle installed at the app root.
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
