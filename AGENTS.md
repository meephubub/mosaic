You are an expert macOS application engineer, SwiftUI developer, interaction designer, and product designer.

I am building a premium, native macOS application for revision, productivity, personal knowledge management, and AI assistance.

The long-term vision is a personal operating system: the user can store and organise notes, tasks, calendar events, revision material, and eventually personal information such as emails. An AI agent sits across all of this and can understand the user's information and perform actions on their behalf.

The application should feel like a combination of:

- Notion
- Duolingo
- Raycast
- Arc
- Apple's native macOS applications

However, it should have its own visual identity and should NOT simply imitate any of these products.

The most important concept is:

THE AI IS AN INTERACTION LAYER, NOT THE ENTIRE APPLICATION.

Everything must also be usable manually through the traditional UI.

The AI and manual UI must operate on the exact same underlying data and application state.

==================================================
TECHNOLOGY REQUIREMENTS
==================================================

Build the application entirely in:

- Swift
- SwiftUI

Target modern macOS.

Do NOT use:

- Electron
- Tauri
- React
- JavaScript
- TypeScript
- HTML/CSS
- web views

AppKit is allowed where SwiftUI does not provide sufficient control over native macOS functionality, especially for:

- transparent windows
- borderless windows
- NSPanel / NSWindow
- window levels
- global mouse/cursor tracking
- screen-edge detection
- window positioning
- macOS visual effects

Keep AppKit code isolated behind clean Swift abstractions.

The application should remain primarily SwiftUI.

Use modern Swift concurrency:

- async/await
- actors where appropriate
- @MainActor
- AsyncSequence where appropriate

Avoid unnecessary third-party dependencies.

Use Apple's native technologies wherever practical.

==================================================
CORE PRODUCT CONCEPT
==================================================

The application has two connected interfaces:

1. THE GLOBAL AI INTERFACE

A small AI companion that lives at the edge of the screen and can be summoned from anywhere.

2. THE FULL WORKSPACE

A traditional macOS application window containing:

- Home
- Notes
- Tasks
- Calendar
- Revision
- AI
- other future functionality

The user can accomplish the same things through either interface.

For example:

AI:
"add biology revision tomorrow"

Manual:
Tasks → Add Task → Biology → Tomorrow

AI:
"make a note about photosynthesis"

Manual:
Notes → New Note

AI:
"what do I have tomorrow?"

Manual:
Calendar → Tomorrow

AI:
"show me my chemistry notes"

Manual:
Notes → Search → Chemistry

Both must modify/read the same underlying models.

==================================================
GLOBAL AI / COMMAND INTERFACE
==================================================

The AI assistant should also function as the application's command palette.

Do NOT build a separate conventional command palette initially.

Instead, the chat input IS the command palette.

The user should be able to type natural language:

"make a task to revise biology tomorrow"

or use slash commands:

/task
/note
/calendar
/search
/open
/revise

The interface should intelligently combine both approaches.

For example:

/task Revise cell biology tomorrow

/note Photosynthesis
/calendar What do I have tomorrow?
/search photosynthesis
/open Biology
/revise Cell biology

Slash commands should provide fast, predictable interaction for users who know what they want.

Natural language should remain the primary conversational interface.

==================================================
SLASH COMMAND SYSTEM
==================================================

Create a proper extensible slash-command architecture.

Do NOT hard-code slash command behaviour directly into the ChatView.

Create abstractions such as:

SlashCommand
SlashCommandRegistry
SlashCommandSuggestion
SlashCommandHandler

or an equivalent clean architecture.

Initially support commands such as:

/task
/note
/calendar
/search
/open
/revise
/help

Potential future commands:

/email
/remind
/flashcards
/summarise
/plan
/settings

When the user types "/" in the chat input, display an animated command suggestion menu.

For example:

┌─────────────────────────────────────┐
│ /                                    │
├─────────────────────────────────────┤
│  /task       Create a task           │
│  /note       Create a note           │
│  /calendar   View your calendar      │
│  /search     Search your workspace   │
│  /open       Open a page             │
│  /revise     Start revision          │
└─────────────────────────────────────┘

The menu should:

- appear immediately
- filter as the user types
- support keyboard navigation
- support arrow keys
- support Enter
- support Escape
- support mouse selection
- animate smoothly
- disappear when the user returns to normal text
- understand partial commands

For example:

"/ta"

should filter to:

/task

The command menu should feel like part of the chat rather than a separate UI element.

==================================================
CHAT + COMMANDS
==================================================

The same input should handle:

1. Normal conversational messages

2. Slash commands

3. Agentic actions

4. Context-aware commands

For example:

"what should I revise tonight?"

is normal AI interaction.

"/task revise biology tomorrow"

is a structured command.

"create a task for that"

is a contextual AI command referring to the previous conversation.

The system should determine which mode is appropriate.

Do NOT force the user to understand the command system.

Natural language should always work when possible.

==================================================
CHAT EXPERIENCE
==================================================

The chat must NOT look like a standard AI chatbot.

Do not create large blocks of text resembling ChatGPT.

The experience should feel like texting a person.

AI responses should be split into multiple short conversational messages.

For example, instead of one huge response:

"Photosynthesis is the process by which plants convert light energy into chemical energy..."

the AI might send:

"yeah"

"photosynthesis is basically how plants turn light into chemical energy"

"there are two main stages"

"the bit you really need to remember is..."

Each should appear as a separate message.

The AI should decide when a response should be split.

Messages should arrive sequentially with natural timing.

Do not add excessive artificial delays.

The AI should be:

- informal
- conversational
- concise
- intelligent
- helpful
- natural
- slightly playful
- context-aware

Avoid generic AI language such as:

"Certainly!"
"Of course!"
"I'd be happy to help!"

The assistant should feel like a useful personal companion rather than a customer-service bot.

==================================================
CHAT VISUAL DESIGN
==================================================

The attached reference image shows the general visual direction for the floating assistant.

Use it as inspiration for:

- floating cards
- layered surfaces
- transparency
- depth
- rounded corners
- soft shadows
- desktop integration
- compact conversational UI

Do NOT directly copy the reference.

The pink mascot in the reference should be replaced with our own mascot.

The interface should feel like floating UI over the macOS desktop rather than a conventional window.

==================================================
BOT MASCOT
==================================================

The application's AI mascot should be extremely simple:

- black circular body
- two white eyes
- no mouth
- minimal geometry

The mascot should be created using SwiftUI rather than a static image.

It should be animated.

It should feel like a tiny living digital companion.

States should include:

IDLE

- subtle floating/bobbing
- occasional small eye movement

CURSOR APPROACHING

- becomes alert
- eyes subtly look toward the cursor

NOTCH OPENING

- reacts to the notch appearing

CHAT OPENING

- smoothly transitions into the chat

THINKING

- subtle eye movement
- small animation indicating thought/activity

MESSAGE SENT

- small reaction

AI RESPONSE

- subtle reaction

ERROR

- subtle confused/reaction animation

The animation should be subtle and premium.

Avoid cartoonish or childish behaviour.

==================================================
SCREEN EDGE INTERACTION
==================================================

The AI companion should normally remain hidden.

When the cursor approaches either the left or right edge of the screen, a small notch should appear from the edge.

It should resemble a small physical interface protruding from the screen.

The notch should:

- appear smoothly
- use a translucent macOS material
- have rounded corners
- contain the black bot mascot
- react to cursor proximity
- disappear when the cursor moves away
- remain open when being interacted with

Support:

- left edge
- right edge
- multiple monitors
- different display resolutions
- Retina scaling

The system must correctly determine which screen contains the cursor.

Do NOT use an inefficient tight polling loop.

Use appropriate macOS event monitoring.

Debounce edge detection so the interface does not flicker.

==================================================
FLOATING WINDOW
==================================================

The AI interface must NOT be a standard application window.

Use a true transparent borderless macOS window/panel.

Requirements:

- no title bar
- no visible window chrome
- transparent background
- no rectangular background behind the UI
- floating above other applications
- smooth positioning
- appropriate window level
- does not unnecessarily steal focus
- can overlay other applications
- supports multiple displays

The window should contain only the SwiftUI content.

The desktop should remain visible around the interface.

Create dedicated abstractions such as:

FloatingAssistantController
FloatingAssistantWindow

Do not scatter NSWindow configuration throughout SwiftUI views.

==================================================
CHAT OPEN/CLOSE ANIMATION
==================================================

When the user clicks the bot in the edge notch:

the notch should transform/expand into the floating chat.

Do NOT simply make a separate chat window appear somewhere else.

The transition should visually connect:

BOT
↓
NOTCH
↓
CHAT

Use spring-based animation and appropriate SwiftUI transitions.

The result should feel physical and intentional.

Closing the chat should reverse the interaction.

==================================================
CHAT LAYOUT
==================================================

The chat should be compact and elegant.

Potential structure:

       bot / assistant identity

       "hey, what can I help with?"

       user message

       assistant message

       assistant message

       assistant message


┌──────────────────────────────────┐
│ +   Ask anything...           ↑  │
└──────────────────────────────────┘

The input should be the primary control.

It should support:

- multiline input
- Enter to send
- Shift+Enter for newline
- slash commands
- autocomplete
- command selection
- keyboard navigation
- attachment support later
- contextual suggestions later

The plus button should eventually provide actions such as:

- new note
- new task
- attach file
- etc.

==================================================
AGENTIC AI ARCHITECTURE
==================================================

The AI must be designed as an agent, not simply a chat completion wrapper.

Create a clean abstraction such as:

AIProvider
ConversationService
Agent
Tool
ToolDefinition
ToolCall
ToolResult
ToolRegistry

The AI provider must be replaceable.

The UI should NOT know which AI model/provider is being used.

Architecture should roughly resemble:

ChatView
    ↓
ChatViewModel
    ↓
ConversationService
    ↓
Agent
    ↓
ToolRegistry
    ↓
Application Services
    ↓
Persistence

The agent should be capable of:

- reasoning about a request
- deciding when to use tools
- calling tools
- receiving tool results
- continuing its response
- producing conversational messages

Design this so future tools can be added without rewriting the agent.

==================================================
INITIAL TOOLS
==================================================

Initially implement safe local demonstration tools:

getCurrentDate
getCurrentTime
createTodo
listTodos
createNote
searchNotes
openPage

Future tools should be easy to add:

searchEmails
readEmail
createCalendarEvent
searchCalendar
createReminder
searchFiles
createFlashcards
createRevisionPlan

Do NOT implement email or external integrations yet.

Build the architecture for them.

==================================================
SHARED APPLICATION STATE
==================================================

The AI and manual UI MUST share one source of truth.

For example:

AI:
"add biology revision tomorrow"

↓

Agent

↓

createTodo tool

↓

Task service

↓

SwiftData

↓

Task appears immediately in Tasks UI

Likewise:

User manually creates a task

↓

SwiftData

↓

AI can access the updated task when appropriate

Never create separate "AI data".

Never hard-code AI actions into individual views.

==================================================
PERSISTENCE
==================================================

The application must be local-first.

Use SwiftData unless there is a strong technical reason to use another Apple-native persistence solution.

Persist locally:

- conversations
- messages
- notes
- tasks
- calendar-related local data
- settings
- application state where appropriate

The app must retain data after restarting.

The architecture should allow cloud synchronisation to be added in the future without replacing the entire persistence layer.

==================================================
FULL APPLICATION WINDOW
==================================================

Clicking the bot while the assistant is open should provide a way to transition into the full application.

The full application uses a conventional native macOS window.

The transition should feel like:

floating bot
    ↓
bot expands
    ↓
workspace opens

The full workspace should feel like a premium Notion-style application.

==================================================
MAIN NAVIGATION
==================================================

Initial sections:

Home
Notes
Tasks
Calendar
Revision
AI

Use a polished sidebar.

The user should be able to navigate manually without ever using the AI.

Navigation should have:

- hover states
- selected states
- subtle animations
- keyboard shortcuts
- context menus
- smooth transitions

==================================================
HOME
==================================================

The Home page should eventually act as a dashboard.

Potential content:

- today's tasks
- upcoming calendar
- revision priorities
- recently edited notes
- AI suggestions
- quick actions

Do not overcrowd it.

The design should feel calm and premium.

==================================================
NOTES
==================================================

Build a foundation for a Notion-like notes system.

Eventually support:

- pages
- nested pages
- rich text
- headings
- lists
- checkboxes
- links
- tags
- search
- AI interaction

Do NOT attempt to clone the entirety of Notion immediately.

Create scalable models and architecture.

The AI should eventually be able to interact with notes through tools.

==================================================
TASKS
==================================================

Tasks should support:

- title
- completion
- due date
- priority
- tags
- notes

The manual interface should make adding and completing tasks extremely fast.

Task completion should have a satisfying animation.

For example:

checkbox tap
→ slight scale
→ completion animation
→ text transition
→ subtle movement into completed state

Avoid excessive animation.

==================================================
CALENDAR
==================================================

Eventually support:

- month view
- week view
- events
- tasks
- deadlines

The architecture should allow future EventKit integration.

Do not over-engineer this in Phase 1.

==================================================
REVISION
==================================================

The revision section will eventually include tools such as:

- flashcards
- quizzes
- revision plans
- spaced repetition
- study sessions
- AI-generated questions
- subject organisation

Do not implement all of this yet.

Create the navigation and architectural space for it.

==================================================
COMMAND PALETTE PHILOSOPHY
==================================================

The chat itself is the command palette.

This is a key product principle.

Do not build:

AI chat + separate command palette

Instead:

AI chat = command palette + natural-language interface + agent.

The user should be able to type:

"/task"

and get structured commands.

Or:

"remind me to revise chemistry tomorrow"

and get the same result through natural language.

The command palette should therefore feel invisible when unnecessary and powerful when needed.

==================================================
CONTEXT AWARENESS
==================================================

The AI should understand application context.

Create an abstraction such as:

AssistantContext

It should eventually contain:

- current section
- current page
- selected object
- selected task
- current date
- recent actions
- relevant workspace state

For example, if the user is viewing:

Notes → Biology → Cell Structure

and types:

"turn this into flashcards"

the AI should know what "this" refers to.

Do not rely on screenshots for this.

Use structured application state.

==================================================
DESIGN SYSTEM
==================================================

Create a reusable SwiftUI design system.

Centralise:

- typography
- spacing
- corner radii
- shadows
- materials
- colours
- button styles
- cards
- chat bubbles
- animations
- transitions

The design should be consistent throughout the application.

The visual language should combine:

macOS native polish
+
Notion-like flexibility
+
Duolingo-like microinteractions
+
AI personality

But avoid making the application childish.

==================================================
VISUAL STYLE
==================================================

Aim for:

- extremely clean
- premium
- modern
- calm
- tactile
- slightly playful
- native
- minimal

Use macOS materials and translucency where appropriate.

Use depth carefully.

Avoid:

- excessive gradients
- excessive glassmorphism
- huge shadows
- excessive rounded rectangles
- generic AI aesthetics
- excessive neon
- visually noisy dashboards

The application should feel expensive.

==================================================
MICROINTERACTIONS
==================================================

Microinteractions are a major part of the product.

Use them intentionally.

Examples:

- sidebar items subtly respond to hover
- buttons slightly scale when pressed
- cards respond to pointer interaction
- task completion animates
- pages transition smoothly
- bot eyes follow cursor
- bot reacts to AI state
- slash command menu appears smoothly
- command selection has tactile feedback
- chat messages arrive naturally
- opening the assistant uses spring physics
- switching sections feels fluid
- creating content feels responsive

Use SwiftUI animation APIs appropriately:

withAnimation
Animation.spring
matchedGeometryEffect
transitions
GeometryReader
TimelineView

Do not animate everything.

Animation should communicate state, hierarchy, or personality.

==================================================
KEYBOARD-FIRST INTERACTION
==================================================

The application should be highly usable from the keyboard.

Important shortcuts should eventually include:

⌘K
Search / invoke AI

⌘N
New note

⌘⇧N
New task

etc.

However, do not make arbitrary shortcuts before understanding macOS conventions.

The chat should be extremely fast to invoke.

==================================================
ACCESSIBILITY
==================================================

Do not completely neglect accessibility.

Use:

- appropriate accessibility labels
- keyboard navigation
- sensible focus handling
- dynamic text considerations
- reduced-motion support where practical

Animations should respect macOS accessibility settings where appropriate.

==================================================
MULTI-MONITOR SUPPORT
==================================================

The floating assistant must support multiple displays.

It should:

- detect the display containing the cursor
- show the notch on that display
- position the assistant correctly
- handle different Retina scaling factors
- handle display changes
- handle display connection/disconnection

Do not assume the main display is the only display.

==================================================
PROJECT ARCHITECTURE
==================================================

Use a clean modular structure.

A reasonable starting point:

App/
    MainApp.swift
    AppState.swift

Assistant/
    FloatingAssistantController.swift
    FloatingAssistantWindow.swift
    EdgeDetector.swift
    BotView.swift
    BotAnimation.swift

Chat/
    Models/
        Message.swift
        Conversation.swift
    Views/
        ChatView.swift
        ChatInput.swift
        MessageBubble.swift
        SlashCommandMenu.swift
    ViewModels/
        ChatViewModel.swift

AI/
    Agent.swift
    AIProvider.swift
    ConversationService.swift
    Context/
    Tools/
        Tool.swift
        ToolRegistry.swift
        CreateTodoTool.swift
        CreateNoteTool.swift
        SearchNotesTool.swift

Notes/
    Models/
    Views/
    ViewModels/
    Services/

Tasks/
    Models/
    Views/
    ViewModels/
    Services/

Calendar/
    Models/
    Views/
    ViewModels/
    Services/

Revision/
    Models/
    Views/
    ViewModels/

Persistence/
    PersistenceController.swift
    Models/

DesignSystem/
    Typography.swift
    Spacing.swift
    Components/
    Animations.swift
    Materials.swift

The exact architecture can differ if you have a demonstrably better approach.

Prioritise maintainability and separation of concerns.

==================================================
IMPORTANT ENGINEERING RULES
==================================================

1. Do not put the entire application in one or two Swift files.

2. Do not put business logic directly inside SwiftUI views.

3. Do not hard-code application data into views.

4. Do not tightly couple the AI provider to the UI.

5. Do not tightly couple tools to individual views.

6. Do not create separate data models for AI and manual functionality.

7. Do not use fake architecture that will need to be completely rewritten later.

8. Avoid unnecessary dependencies.

9. Prefer native macOS functionality.

10. Keep AppKit interoperability isolated.

11. Use proper state management.

12. Keep persistence separate from presentation.

13. Design APIs and protocols for future expansion.

14. Build incrementally.

15. Keep the application compiling after each meaningful change.

16. Do not implement huge amounts of unfinished functionality just to make the project appear complete.

17. Prioritise polish and interaction quality.

==================================================
PHASE 1 — FIRST VERTICAL SLICE
==================================================

Do NOT implement the entire product immediately.

The first goal is to create a genuinely polished prototype of the application's core interaction model.

Implement ONLY:

1. Native macOS SwiftUI application

2. Transparent borderless floating assistant

3. Cursor detection near left/right screen edges

4. Animated edge notch

5. Black circular bot mascot

6. Animated bot eyes/body

7. Click notch → expand into chat

8. Premium floating chat interface

9. Text-message-style conversational bubbles

10. Multiple sequential AI messages

11. Slash-command interface inside the chat

12. Keyboard navigation for slash commands

13. AI provider abstraction

14. Mock AI provider

15. Basic agent architecture

16. Basic tool registry

17. A few local tools:
    - current date
    - current time
    - create task
    - create note
    - search notes

18. Local persistence for conversations/messages

19. Basic traditional workspace window

20. Minimal Notes and Tasks views demonstrating that AI and manual UI share the same data

The application should already feel like a real premium product at the end of Phase 1.

==================================================
MOCK AI
==================================================

Initially provide a MockAIProvider so the application works without API credentials.

The mock should demonstrate:

- conversational responses
- multiple-message responses
- tool calls
- slash commands
- loading/thinking state
- errors

Do not make the architecture dependent on the mock.

The provider should be replaceable with a real model later.

==================================================
IMPLEMENTATION PROCESS
==================================================

Before writing code:

1. Inspect the existing project structure.
2. Determine the current Swift/macOS deployment target.
3. Identify whether the project already has useful infrastructure.
4. Do not unnecessarily replace working code.
5. Decide how the transparent floating NSWindow/NSPanel should be implemented.
6. Decide how cursor edge detection should work.
7. Design the state architecture.
8. Design the AI/tool abstractions.

Then implement the first vertical slice incrementally.

After each major stage:

- build the project
- fix compiler errors
- ensure the application launches
- verify that the architecture remains clean

Do not dump a massive amount of speculative code into the project.

==================================================
DEFINITION OF SUCCESS
==================================================

When Phase 1 is complete, I should be able to:

1. Launch the macOS app.

2. Move my cursor toward the left edge.

3. See a small animated notch emerge.

4. See the black circular bot with white eyes.

5. Move away and see it disappear.

6. Click the bot.

7. See the bot smoothly transition into a floating conversational chat.

8. Type naturally:

"what time is it?"

9. Receive a conversational response.

10. See the response arrive as multiple short messages where appropriate.

11. Type "/" and see the command palette appear inside the chat.

12. Type "/task".

13. See the task command.

14. Create a task through the command.

15. Open the traditional workspace.

16. See that task in the Tasks section.

17. Create a task manually.

18. Return to the AI.

19. Ask the AI about the task.

20. See that the AI and manual workspace are operating on the same persisted data.

The experience should feel cohesive rather than like several unrelated prototypes.

==================================================
MOST IMPORTANT PRODUCT PRINCIPLE
==================================================

The application should feel like:

"my computer has a little intelligent layer that understands my workspace"

rather than:

"here is another AI chatbot."

The bot is the personality and primary interaction layer.

The chat is simultaneously:

- an AI assistant
- a command palette
- a universal search interface
- an agentic control surface

The traditional workspace remains the visual/manual control centre.

AI and manual interaction are two interfaces into the SAME application.

Build the foundation around that principle.
