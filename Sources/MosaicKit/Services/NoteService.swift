import Foundation
import SwiftData
import Observation

/// The single writer for note state, shared by the Notes UI and the AI tools.
@MainActor
@Observable
final class NoteService {
    private let repository: NoteRepository

    private(set) var notes: [NoteModel] = []

    init(repository: NoteRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            notes = try repository.fetchAll()
        } catch {
            MosaicLog.error("NoteService.reload failed: \(error)")
        }
    }

    @discardableResult
    func create(title: String, content: String = "") -> NoteModel {
        let note = NoteModel(title: title, content: content)
        do {
            try repository.insert(note)
        } catch {
            MosaicLog.error("NoteService.create failed: \(error)")
        }
        reload()
        return note
    }

    func search(_ query: String) -> [NoteModel] {
        do {
            return try repository.search(query)
        } catch {
            MosaicLog.error("NoteService.search failed: \(error)")
            return []
        }
    }

    func findByID(_ id: UUID) -> NoteModel? {
        do {
            return try repository.findByID(id)
        } catch {
            MosaicLog.error("NoteService.findByID failed: \(error)")
            return nil
        }
    }

    func updateContent(_ note: NoteModel, title: String? = nil, content: String? = nil) {
        if let title { note.title = title }
        if let content { note.content = content }
        note.updatedAt = .now
        save()
    }

    func delete(_ note: NoteModel) {
        repository.context.delete(note)
        do {
            try repository.save()
        } catch {
            MosaicLog.error("NoteService.delete failed: \(error)")
        }
        reload()
    }

    private func save() {
        do {
            try repository.save()
        } catch {
            MosaicLog.error("NoteService.save failed: \(error)")
        }
    }
}
