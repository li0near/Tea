import Foundation
import IOKit.pwr_mgt
import CoreGraphics
import ApplicationServices

@MainActor
final class IdlePreventionService {
    private static let anyInputEventType = CGEventType(rawValue: 0xFFFFFFFF)!

    private var activityToken: NSObjectProtocol?
    private var userActivityAssertionID: IOPMAssertionID = IOPMAssertionID(0)
    private var isRunning = false
    private var lockTask: Task<Void, Never>?
    private var unlockTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?

    var pauseWhenLocked = false {
        didSet {
            guard isRunning, !pauseWhenLocked, activityToken == nil else { return }
            beginActivity()
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        requestAccessibilityIfNeeded()
        beginActivity()
        startHeartbeat()
        observeScreenLock()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        endActivity()
        heartbeatTask?.cancel()
        heartbeatTask = nil
        lockTask?.cancel()
        lockTask = nil
        unlockTask?.cancel()
        unlockTask = nil
    }

    private func beginActivity() {
        guard activityToken == nil else { return }
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleDisplaySleepDisabled, .idleSystemSleepDisabled],
            reason: "Tea heartbeat"
        )
        tickle()
    }

    private func endActivity() {
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
    }

    private func tickle() {
        declareUserActivity()
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: Self.anyInputEventType
        )
        guard idleSeconds >= 30 else { return }
        postSyntheticMouseEvent()
    }

    private func declareUserActivity() {
        IOPMAssertionDeclareUserActivity(
            "Tea User Activity" as CFString,
            kIOPMUserActiveLocal,
            &userActivityAssertionID
        )
    }

    private func postSyntheticMouseEvent() {
        let source = CGEventSource(stateID: .hidSystemState)
        let origin = CGEvent(source: source)?.location ?? .zero
        let deltaX = Self.signedRandom(magnitudeIn: 1...3)
        let deltaY = Self.signedRandom(magnitudeIn: 1...3)
        let nudged = CGPoint(x: origin.x + Double(deltaX), y: origin.y + Double(deltaY))
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: nudged,
            mouseButton: .left
        ) else { return }
        event.post(tap: .cghidEventTap)
    }

    private static func signedRandom(magnitudeIn range: ClosedRange<Int>) -> Int {
        let mag = Int.random(in: range)
        return Bool.random() ? mag : -mag
    }

    private func requestAccessibilityIfNeeded() {
        // String literal mirrors `kAXTrustedCheckOptionPrompt`; the bridged C
        // constant imports as a non-isolated `var` and trips strict concurrency.
        let options = ["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled {
                let interval = Double.random(in: 30...60)
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled, self.isRunning, self.activityToken != nil else { continue }
                self.tickle()
            }
        }
    }

    private func observeScreenLock() {
        let center = DistributedNotificationCenter.default()
        let lockedName = NSNotification.Name("com.apple.screenIsLocked")
        let unlockedName = NSNotification.Name("com.apple.screenIsUnlocked")
        lockTask = Task {
            for await _ in center.notifications(named: lockedName) {
                self.handleScreenLocked()
            }
        }
        unlockTask = Task {
            for await _ in center.notifications(named: unlockedName) {
                self.handleScreenUnlocked()
            }
        }
    }

    private func handleScreenLocked() {
        guard isRunning, pauseWhenLocked else { return }
        endActivity()
    }

    private func handleScreenUnlocked() {
        guard isRunning else { return }
        beginActivity()
    }
}
