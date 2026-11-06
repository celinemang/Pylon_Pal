import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var c: PylonController
    @AppStorage(Settings.language) private var lang = "en"
    @AppStorage(Settings.manualMode) private var manual = true
    @AppStorage(Settings.boardingDelay) private var boardingDelay = 4.0
    @AppStorage(Settings.returnDelay) private var returnDelay = 3.0
    @AppStorage(Settings.lineColorHex) private var lineHex = "0039A6"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Trigger") {
                    Toggle("Manual (Wizard-of-Oz) mode", isOn: $manual)
                    if !manual { Text("Motion mode is not implemented yet (step 3).").font(.footnote).foregroundStyle(.secondary) }
                }
                Section("Language") {
                    Picker("Audio language", selection: $lang) { ForEach(Language.allCases) { Text($0.label).tag($0.rawValue) } }
                }
                Section("Timing (seconds)") {
                    Stepper("STAND_ASIDE → BOARDING_OK: \(boardingDelay, specifier: "%.0f")", value: $boardingDelay, in: 1...15)
                    Stepper("BOARDING_OK → IDLE: \(returnDelay, specifier: "%.0f")", value: $returnDelay, in: 1...15)
                }
                Section("Screen line color (hex)") { TextField("0039A6", text: $lineHex).textInputAutocapitalization(.characters) }
                Section("Strip") {
                    Label(c.ble.connected ? "PylonPal connected" : "Searching for PylonPal…", systemImage: "dot.radiowaves.left.and.right")
                    ForEach(PylonState.allCases, id: \.self) { s in
                        Button("Send state \(s.rawValue)") { c.set(s) }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
