import SwiftUI

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue: AppServices? = nil
}

extension EnvironmentValues {
    /// The shared service bundle. Installed at the app root.
    var appServices: AppServices? {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }

    /// Unwrapped accessor — crashes only on programmer error (services are
    /// always installed at the root).
    var requireAppServices: AppServices {
        guard let services = appServices else {
            fatalError("AppServices not installed in environment")
        }
        return services
    }
}

extension Environment {
    /// Unwrapped shared services for view code: `@Environment(\.appServices)`.
    var appServices: AppServices {
        self[\.requireAppServices]
    }
}
