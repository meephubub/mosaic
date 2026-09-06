import Foundation

/// Builds the default slash command registry with all Phase 1 commands wired
/// to shared services. Future commands register here — no view changes.
@MainActor
enum SlashCommandInstaller {
    static func makeRegistry(services: AppServices, navigator: WorkspaceNavigator) -> SlashCommandRegistry {
        let registry = SlashCommandRegistry()
        registry.register(
            SlashCommand(name: "task", description: "Create a task", placeholder: "Revise cell biology tomorrow"),
            handler: TaskCommandHandler(taskService: services.taskService)
        )
        registry.register(
            SlashCommand(name: "note", description: "Create a note", placeholder: "Photosynthesis"),
            handler: NoteCommandHandler(noteService: services.noteService)
        )
        registry.register(
            SlashCommand(name: "calendar", description: "View your calendar", placeholder: "What do I have tomorrow?"),
            handler: CalendarCommandHandler()
        )
        registry.register(
            SlashCommand(name: "search", description: "Search your workspace", placeholder: "photosynthesis"),
            handler: SearchCommandHandler(noteService: services.noteService)
        )
        registry.register(
            SlashCommand(name: "open", description: "Open a page", placeholder: "Biology"),
            handler: OpenCommandHandler(navigator: navigator)
        )
        registry.register(
            SlashCommand(name: "revise", description: "Start revision", placeholder: "Cell biology"),
            handler: ReviseCommandHandler()
        )
        registry.register(
            SlashCommand(name: "help", description: "Show available commands", placeholder: ""),
            handler: HelpCommandHandler(registry: registry)
        )
        return registry
    }
}
