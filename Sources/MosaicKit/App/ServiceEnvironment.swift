import SwiftUI

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue: AppServices? = nil
}

extension EnvironmentValues {
    /// The shared service bundle installed at the app root.
    var appServices: AppServices {
        get {
            guard let services = self[AppServicesKey.self] else {
                fatalError("AppServices not installed in environment")
            }
            return services
        }
        set { self[AppServicesKey.self] = newValue }
    }
}
