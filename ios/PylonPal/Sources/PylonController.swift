import SwiftUI
import Combine

/// Owns the state machine; pushes every transition to screen, strip and audio.
final class PylonController: ObservableObject {
    @Published var state: PylonState = .idle
    let ble = BLEManager()
    private let audio = AudioManager()
    private var timer: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    init() {
        ble.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &bag)
    }

    var language: Language { Language(rawValue: UserDefaults.standard.string(forKey: Settings.language) ?? "en") ?? .en }
    private var boardingDelay: Double { let v = UserDefaults.standard.double(forKey: Settings.boardingDelay); return v > 0 ? v : 4 }
    private var returnDelay: Double { let v = UserDefaults.standard.double(forKey: Settings.returnDelay); return v > 0 ? v : 3 }

    func set(_ s: PylonState) {
        state = s
        ble.send(s)
        if s == .standAside { audio.playMessage(language) }
    }

    /// Run the full sequence IDLE -> APPROACHING -> STAND_ASIDE -> BOARDING_OK -> IDLE.
    func runSequence() {
        timer?.cancel()
        timer = Task { @MainActor in
            set(.approaching)
            try? await Task.sleep(for: .seconds(1.5)); if Task.isCancelled { return }
            set(.standAside)
            try? await Task.sleep(for: .seconds(boardingDelay)); if Task.isCancelled { return }
            set(.boardingOK)
            try? await Task.sleep(for: .seconds(returnDelay)); if Task.isCancelled { return }
            set(.idle)
        }
    }

    /// Manual step (Wizard-of-Oz): advance one state.
    func stepManually() { timer?.cancel(); set(state.next) }
    func reset() { timer?.cancel(); set(.idle) }
}
