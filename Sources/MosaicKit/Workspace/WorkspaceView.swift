import SwiftUI

/// The traditional workspace window — the manual control centre. Every action
/// here is also achievable through the floating assistant.
struct WorkspaceView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(WorkspaceNavigator.self) private var navigator

    @State private var selectedSection: WorkspaceSection = .home

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            workspaceDetail(selectedSection)
        }
        .navigationTitle("Mosaic")
        .onAppear {
            // Adopt navigator state (e.g. set by the assistant's openPage tool).
            selectedSection = navigator.selectedSection
        }
        .onChange(of: navigator.selectedSection) { _, newValue in
            withAnimation(DS.Animations.smooth) {
                selectedSection = newValue
            }
        }
        .onChange(of: selectedSection) { _, newValue in
            if navigator.selectedSection != newValue {
                navigator.selectedSection = newValue
            }
        }
    }
}

@ViewBuilder
private func workspaceDetail(_ section: WorkspaceSection) -> some View {
    switch section {
    case .home: HomePage()
    case .notes: NotesPage()
    case .tasks: TasksPage()
    case .calendar: CalendarPage()
    case .revision: RevisionPage()
    case .ai: AIPage()
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selection: WorkspaceSection
    @Environment(WorkspaceNavigator.self) private var navigator

    var body: some View {
        List(selection: $selection) {
            ForEach(WorkspaceSection.allCases) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
                    .contextMenu {
                        Button("Open") { navigator.open(section) }
                    }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            assistantFooter
        }
    }

    private var assistantFooter: some View {
        VStack(spacing: DS.Spacing.xs) {
            Divider()
            Button {
                NotificationCenter.default.post(name: .openFloatingAssistant, object: nil)
            } label: {
                Label("Ask Mosaic", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dsPress)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.sm)
        }
    }
}

extension Notification.Name {
    static let openFloatingAssistant = Notification.Name("mosaic.openFloatingAssistant")
    static let closeFloatingAssistant = Notification.Name("mosaic.closeFloatingAssistant")
    static let openWorkspaceWindow = Notification.Name("mosaic.openWorkspaceWindow")
}
