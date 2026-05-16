import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Shortcut")
                Spacer(minLength: 8)
                KeyboardShortcuts.Recorder(for: .toggleTea)
            }

            Divider()

            Toggle("Pause when screen is locked", isOn: Binding(
                get: { appState.pauseWhenLocked },
                set: { appState.pauseWhenLocked = $0 }
            ))
            .toggleStyle(.checkbox)

            Toggle("Launch at Login", isOn: Binding(
                get: { appState.launchAtLogin },
                set: { appState.launchAtLogin = $0 }
            ))
            .toggleStyle(.checkbox)
        }
        .padding(16)
        .frame(width: 260)
        .fixedSize()
    }
}
