# Mosaic

A premium, native macOS app for revision, productivity, personal knowledge
management, and AI assistance — with a floating AI companion that lives at the
edge of your screen and shares one source of truth with the full workspace.

Built with Swift + SwiftUI (AppKit isolated behind windowing abstractions).
No web views, no Electron, no third-party runtime dependencies.

## Development (macOS)

```bash
# Swift Package Manager (build + test)
swift build
swift test

# Or generate an Xcode project with XcodeGen
brew install xcodegen
xcodegen generate
open Mosaic.xcodeproj
```

CI builds and tests on macOS for every push via `.github/workflows/ci.yml`.

## Architecture

```
ChatView → ChatController → ConversationService → Agent → ToolRegistry
                                                            ↓
                                                    App Services (TaskService, NoteService…)
                                                            ↓
                                                    SwiftData (one shared store)
```

- **Floating assistant** — a transparent, borderless, non-activating `NSPanel`
  hosts both the edge notch and the chat. The notch→chat transition is one
  animated frame change plus SwiftUI springs, never two separate windows.
- **Edge detection** — global mouse-moved event monitoring with hysteresis and
  debounce (`EdgeGeometry` is pure and unit-tested). Multi-display aware.
- **Chat = command palette** — the chat input handles natural language, slash
  commands (`/task`, `/note`, `/calendar`, `/search`, `/open`, `/revise`,
  `/help`), and agentic tool calls. Slash commands are a registry, not
  view code.
- **Agent** — provider-agnostic loop (`AIProvider` → tool calls → results →
  response). `MockAIProvider` ships now; a real LLM provider slots in without
  UI changes.
- **One source of truth** — tools and manual UI both write through the same
  services onto the same SwiftData store. The AI never has separate data.

## First macOS session checklist

- [ ] `swift build && swift test` green
- [ ] Edge notch appears near left/right edge, multi-display correct
- [ ] Notch → chat morph feels physical; Esc / × closes
- [ ] `/task` creates a task visible in the workspace Tasks section
- [ ] Manual task visible to `listTodos` through the assistant
- [ ] Conversations survive relaunch
