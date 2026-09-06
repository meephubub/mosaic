import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    var body: some View {
        Form {
            Section("Assistant") {
                Picker("Preferred edge", selection: Bindable(environment).floatingAssistant.preferredEdge) {
                    ForEach(AssistantEdge.allCases) { edge in
                        Text(edge.label).tag(edge)
                    }
                }
                Toggle("Assistant enabled", isOn: Bindable(environment).floatingAssistant.enabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 160)
    }
}
