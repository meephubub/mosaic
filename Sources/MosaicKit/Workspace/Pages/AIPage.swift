import SwiftUI

/// The workspace's AI section — hosts the exact same ChatView the floating
/// assistant uses, proving both interfaces share one state.
struct AIPage: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var chatController: ChatController?

    var body: some View {
        Group {
            if let chatController {
                ChatView(controller: chatController)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            if chatController == nil {
                chatController = ChatController.fromServices(
                    environment.services,
                    navigator: environment.navigator
                )
            }
        }
    }
}
