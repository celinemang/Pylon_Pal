import SwiftUI

struct ContentView: View {
    @EnvironmentObject var c: PylonController
    @AppStorage(Settings.manualMode) private var manual = true
    @AppStorage(Settings.lineColorHex) private var lineHex = "0039A6"
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            StateArt(state: c.state, lineColor: Color(hex: lineHex))
            // Hidden triggers: triple-tap bottom-right = next state, triple-tap bottom-left = run full sequence,
            // long-press top-left = settings.
            VStack {
                HStack { hotspot().onLongPressGesture(minimumDuration: 1.5) { showSettings = true }; Spacer() }
                Spacer()
                HStack {
                    hotspot().onTapGesture(count: 3) { if manual { c.runSequence() } }
                    Spacer()
                    hotspot().onTapGesture(count: 3) { if manual { c.stepManually() } }
                }
            }.ignoresSafeArea()
        }
        .sheet(isPresented: $showSettings) { SettingsView().environmentObject(c) }
    }

    private func hotspot() -> some View { Color.clear.frame(width: 120, height: 120).contentShape(Rectangle()) }
}

/// Placeholder art — replace with supplied assets.
struct StateArt: View {
    let state: PylonState
    let lineColor: Color
    var body: some View {
        VStack(spacing: 24) {
            switch state {
            case .idle:
                Circle().fill(lineColor.opacity(0.35)).frame(width: 160)
            case .approaching:
                Circle().fill(lineColor).frame(width: 200)
            case .standAside:
                HStack(spacing: 80) {
                    Image(systemName: "figure.walk").font(.system(size: 160)).foregroundStyle(.white)
                        .offset(x: -40)
                    Rectangle().fill(lineColor).frame(width: 20, height: 240)
                }
            case .boardingOK:
                Image(systemName: "checkmark.circle.fill").font(.system(size: 200)).foregroundStyle(.green)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: state)
    }
}
