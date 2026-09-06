import SwiftUI

/// The workspace's section identifiers.
enum WorkspaceSection: String, CaseIterable, Identifiable, Hashable {
    case home
    case notes
    case tasks
    case calendar
    case revision
    case ai

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .notes: "Notes"
        case .tasks: "Tasks"
        case .calendar: "Calendar"
        case .revision: "Revision"
        case .ai: "AI"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .notes: "doc.text"
        case .tasks: "checklist"
        case .calendar: "calendar"
        case .revision: "brain.head.profile"
        case .ai: "sparkles"
        }
    }
}

/// Single source of truth for which section is selected and which note is open.
/// The assistant's `openPage` tool and `/open` command drive this, so the
/// floating assistant can steer the workspace window.
@MainActor
@Observable
final class WorkspaceNavigator {
    var selectedSection: WorkspaceSection = .home
    var selectedNoteID: UUID?

    /// Requests that the workspace show a given section, optionally focusing content.
    func open(_ section: WorkspaceSection, noteID: UUID? = nil) {
        selectedNoteID = noteID
        withAnimation(.smooth(duration: 0.25)) {
            selectedSection = section
        }
    }
}
