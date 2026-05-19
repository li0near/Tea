import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var appState = appState

        Toggle("Enabled", isOn: $appState.isActive)
            .keyboardShortcut("k", modifiers: [.command])

        Divider()

        Button("Settings...") {
            openWindow(id: WindowID.settings)
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        if appState.timedQuitActive {
            Text("Quit in \(appState.formattedRemaining)")
                .foregroundStyle(.secondary)
        }

        Button("Quit Tea...") {
            openWindow(id: WindowID.quit)
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}
