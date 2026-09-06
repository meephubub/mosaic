import SwiftUI

/// Notes — list plus editor, Notion-flavoured but minimal for Phase 1.
struct NotesPage: View {
    @Environment(\.appServices) private var services
    @Environment(WorkspaceNavigator.self) private var navigator

    @State private var selectedID: UUID?
    @State private var searchQuery = ""

    private var noteService: NoteService { services.noteService }

    private var visibleNotes: [NoteModel] {
        if searchQuery.isEmpty { return noteService.notes }
        return noteService.search(searchQuery)
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                searchField
                noteList
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            detail
        }
    }

    private var searchField: some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search notes", text: $searchQuery)
                .textFieldStyle(.plain)
        }
        .padding(DS.Spacing.sm)
        .background(.background.secondary, in: .rect(cornerRadius: DS.Radii.sm))
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.top, DS.Spacing.sm)
    }

    private var noteList: some View {
        List(selection: $selectedID) {
            ForEach(visibleNotes, id: \.id) { note in
                NavigationLink(value: note.id) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.title)
                            .font(DS.Typography.cardTitle)
                        Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(DS.Typography.meta)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(note.id)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    if index < visibleNotes.count {
                        noteService.delete(visibleNotes[index])
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let note = noteService.create(title: "Untitled")
                    selectedID = note.id
                } label: {
                    Label("New note", systemImage: "square.and.pencil")
                }
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let id = selectedID ?? navigator.selectedNoteID,
           let note = noteService.findByID(id) {
            NoteEditor(note: note)
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Select a note")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Editor

struct NoteEditor: View {
    @Environment(\.appServices) private var services
    let note: NoteModel

    @State private var title: String
    @State private var content: String
    @State private var saveTask: Task<Void, Never>?

    init(note: NoteModel) {
        self.note = note
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Title", text: $title)
                .font(DS.Typography.pageTitle)
                .textFieldStyle(.plain)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.lg)

            TextEditor(text: $content)
                .font(DS.Typography.chatBody)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.sm)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onChange(of: title) { _, _ in scheduleSave() }
        .onChange(of: content) { _, _ in scheduleSave() }
        .onDisappear { saveNow() }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            saveNow()
        }
    }

    private func saveNow() {
        services.noteService.updateContent(note, title: title, content: content)
    }
}
