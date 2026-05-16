import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Enabled", isOn: Binding(
            get: { appState.isActive },
            set: { _ in appState.toggle() }
        ))
        .keyboardShortcut("k", modifiers: [.command])

        Divider()

        Button("Settings...") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        if appState.timedQuitActive {
            Text("Quit in \(appState.formattedRemaining)")
                .foregroundStyle(.secondary)
        }

        Button("Quit Tea...") {
            openWindow(id: "quit")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}
