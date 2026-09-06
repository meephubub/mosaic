import Foundation

/// What the AI knows about the user's current app state. Built from
/// structured application state — never screenshots.
struct AssistantContext: Sendable {
    var currentSection: WorkspaceSection
    var selectedNoteTitle: String?
    var selectedNoteContent: String?
    var openTaskTitles: [String]
    var now: Date

    init(
        currentSection: WorkspaceSection = .home,
        selectedNoteTitle: String? = nil,
        selectedNoteContent: String? = nil,
        openTaskTitles: [String] = [],
        now: Date = .now
    ) {
        self.currentSection = currentSection
        self.selectedNoteTitle = selectedNoteTitle
        self.selectedNoteContent = selectedNoteContent
        self.openTaskTitles = openTaskTitles
        self.now = now
    }
}
