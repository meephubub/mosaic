import SwiftUI

/// Revision — the navigation space exists now; flashcards and spaced
/// repetition arrive in a later phase.
struct RevisionPage: View {
    @Environment(\.appServices) private var services

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Revision")
                .font(DS.Typography.pageTitle)

            DSCard {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Label("Coming soon", systemImage: "brain.head.profile")
                        .font(DS.Typography.cardTitle)
                    Text(
                        "Flashcards, quizzes, revision plans, and spaced repetition will live here. "
                        + "For now, the assistant can create revision tasks and notes."
                    )
                    .font(DS.Typography.chatBody)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
