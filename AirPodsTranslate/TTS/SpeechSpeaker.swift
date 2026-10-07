import AVFoundation
import Observation

/// 离线 TTS（系统 AVSpeechSynthesizer，零体积）。
/// 支持当前路由播放、异步等待播完、新人声立即打断。
@MainActor
@Observable
final class SpeechSpeaker: NSObject {
    static let shared = SpeechSpeaker()

    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Bool, Never>?
    private(set) var isSpeaking = false

    /// 当前播出的文本（UI 高亮用）
    var speakingText: String?

    var rate: Float = AVSpeechUtteranceDefaultSpeechRate
    var volume: Float = 1.0

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// - Parameters:
    ///   - languageCode: zh-Hans → zh-CN 等 TTS 可用语言码
    ///   - volume: 本条独立音量（侍从模式扬声器 0.7 / 耳机 1.0 可区分）
    @discardableResult
    func speak(_ text: String,
               languageCode: String,
               volume: Float? = nil,
               rate: Float? = nil) async -> Bool {
        stopSpeaking()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Self.ttsLanguageCode(from: languageCode))
        utterance.volume = volume ?? self.volume
        utterance.rate = rate ?? self.rate
        utterance.pitchMultiplier = 1.0
        // HFP 通话链路下 pre/post 延迟缩短一点
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0

        isSpeaking = true
        speakingText = text
        synthesizer.speak(utterance)

        return await withCheckedContinuation { cont in
            self.continuation = cont
        }
    }

    /// 新人声触发：立即停止，未播完提供"重播"（由上层缓存最后一条）
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        finish(spokeCompletely: false)
    }

    private func finish(spokeCompletely: Bool) {
        guard let continuation else {
            isSpeaking = false
            speakingText = nil
            return
        }
        self.continuation = nil
        isSpeaking = false
        speakingText = nil
        continuation.resume(returning: spokeCompletely)
    }

    // zh-Hans → zh-CN；en → en-US（可用已下载的增强语音）
    static func ttsLanguageCode(from localeCode: String) -> String {
        if localeCode.hasPrefix("zh") { return "zh-CN" }
        if localeCode.hasPrefix("en") { return "en-US" }
        return localeCode
    }
}

extension SpeechSpeaker: AVSpeechSynthesizerDelegate {
    func synthesizer(_ synthesizer: AVSpeechSynthesizer,
                     didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }

    func synthesizer(_ synthesizer: AVSpeechSynthesizer,
                     didFinish utterance: AVSpeechUtterance,
                     startedSpeaking: Bool,
                     speakerChanged: Bool) {
        finish(spokeCompletely: startedSpeaking)
    }

    func synthesizer(_ synthesizer: AVSpeechSynthesizer,
                     didCancel utterance: AVSpeechUtterance) {
        finish(spokeCompletely: false)
    }
}
