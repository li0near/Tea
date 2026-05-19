import SwiftUI

struct QuitView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var quitAfterEnabled = false
    @State private var quitAfterValue: Int = 2
    @State private var quitAfterUnit: TimeUnit = .hours

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cup.and.heat.waves")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            if appState.timedQuitActive {
                // Timer is already running — show countdown
                Text("Quitting in")
                    .font(.headline)

                Text(appState.formattedRemaining)
                    .font(.system(.title, design: .monospaced))
                    .contentTransition(.numericText())

                HStack(spacing: 12) {
                    Button("Cancel Timer") {
                        appState.cancelTimedQuit()
                        dismissWindow(id: WindowID.quit)
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Quit Now") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut(.defaultAction)
                }
            } else {
                // No timer — show quit options
                Text("Quit Tea?")
                    .font(.headline)

                VStack(spacing: 8) {
                    Toggle("Quit after a delay", isOn: $quitAfterEnabled)

                    if quitAfterEnabled {
                        HStack {
                            TextField("", value: Binding(
                                get: { quitAfterValue },
                                set: { quitAfterValue = max(1, $0) }
                            ), format: .number)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)

                            Picker("", selection: $quitAfterUnit) {
                                ForEach(TimeUnit.allCases) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                        }
                    }
                }
                .padding(.vertical, 4)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismissWindow(id: WindowID.quit)
                    }
                    .keyboardShortcut(.cancelAction)

                    if quitAfterEnabled {
                        Button("Start Timer") {
                            let totalSeconds = quitAfterUnit.toSeconds(max(1, quitAfterValue))
                            appState.startTimedQuit(seconds: totalSeconds)
                            dismissWindow(id: WindowID.quit)
                        }
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button("Quit") {
                            NSApplication.shared.terminate(nil)
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 280)
        .fixedSize()
    }
}
