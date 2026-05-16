import AppKit

@MainActor
final class TimedQuitService {
    private var task: Task<Void, Never>?
    private(set) var secondsRemaining: Int = 0
    var onTick: ((Int) -> Void)?

    var isActive: Bool { task != nil }

    func start(seconds: Int) {
        stop()
        guard seconds > 0 else { return }
        secondsRemaining = seconds
        onTick?(secondsRemaining)

        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                self.secondsRemaining -= 1
                self.onTick?(self.secondsRemaining)
                if self.secondsRemaining <= 0 {
                    self.task = nil
                    NSApplication.shared.terminate(nil)
                    return
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        secondsRemaining = 0
    }
}
