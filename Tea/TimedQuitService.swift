import AppKit

@MainActor
final class TimedQuitService {
    private var task: Task<Void, Never>?
    var onTick: ((Int) -> Void)?

    func start(seconds: Int) {
        stop()
        guard seconds > 0 else { return }
        onTick?(seconds)

        task = Task { [weak self] in
            var remaining = seconds
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                remaining -= 1
                self.onTick?(remaining)
                if remaining <= 0 {
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
    }
}
