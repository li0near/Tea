import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Shortcut")
                Spacer(minLength: 8)
                KeyboardShortcuts.Recorder(for: .toggleTea)
            }

            Divider()

            Toggle("Pause when screen is locked", isOn: $appState.pauseWhenLocked)
                .toggleStyle(.checkbox)

            Toggle("Launch at Login", isOn: $appState.launchAtLogin)
                .toggleStyle(.checkbox)
        }
        .padding(16)
        .frame(width: 260)
        .fixedSize()
    }
}
