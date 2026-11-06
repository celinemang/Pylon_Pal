import AVFoundation

/// Plays the per-language message and keeps the Bluetooth speaker awake
/// with a continuous silent loop.
final class AudioManager {
    private var keepAlive: AVAudioPlayerNode?
    private let engine = AVAudioEngine()
    private var player: AVAudioPlayer?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP, .mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        startKeepAlive()
    }

    /// Very-low-level noise (inaudible) so speakers don't auto-sleep. Pure digital silence may be ignored by some speakers.
    private func startKeepAlive() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let frames = AVAudioFrameCount(44100)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frames) { data[i] = Float.random(in: -0.0005...0.0005) }
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        try? engine.start()
        node.scheduleBuffer(buffer, at: nil, options: .loops)
        node.play()
        keepAlive = node
    }

    /// Looks for Resources/Audio/message_<lang>.mp3|m4a|wav; falls back to speech synthesis.
    func playMessage(_ lang: Language) {
        for ext in ["mp3", "m4a", "wav"] {
            if let url = Bundle.main.url(forResource: "message_\(lang.rawValue)", withExtension: ext) {
                player = try? AVAudioPlayer(contentsOf: url)
                player?.play()
                return
            }
        }
        let text = ["en": "Please let passengers exit first.",
                    "es": "Por favor, deje salir a los pasajeros primero.",
                    "zh": "请先让乘客下车。",
                    "fr": "Laissez d'abord descendre les passagers."][lang.rawValue]!
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: ["en": "en-US", "es": "es-ES", "zh": "zh-CN", "fr": "fr-FR"][lang.rawValue])
        synth.speak(u)
    }
    private let synth = AVSpeechSynthesizer()
}
