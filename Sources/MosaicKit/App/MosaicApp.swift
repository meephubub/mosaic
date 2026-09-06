import SwiftUI

/// The application entry point. Declared without `@main` so that both the
/// SwiftPM executable (`Sources/MosaicMain`) and the Xcode app target
/// (`Sources/MosaicAppMain`) can host the same app definition.
public struct MosaicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var environment = AppEnvironment()

    public init() {}

    public var body: some Scene {
        Window("Mosaic", id: "workspace") {
            WorkspaceView()
                .environment(environment)
                .environment(environment.navigator)
                .environment(\.appServices, environment.services)
                .task { environment.start() }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("mosaic.showWorkspaceExternally"))) { _ in
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        Settings {
            SettingsView()
                .environment(environment)
        }
    }
}

/// Owns application lifecycle concerns that SwiftUI cannot express:
/// activating the app on launch so the workspace window is frontmost.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
