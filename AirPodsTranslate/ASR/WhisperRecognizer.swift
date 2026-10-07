import Foundation
import WhisperKit

/// WhisperKit CoreML 离线识别（主引擎，跑 ANE）
/// tiny 模型建议内置 Bundle；base 模型走 App 内一次性下载。
final class WhisperRecognizer: SpeechRecognizing {
    private var whisper: WhisperKit?
    private(set) var isReady = false
    private var loadTask: Task<Void, Never>?

    func prepare() async {
        guard whisper == nil, loadTask == nil else { return }
        loadTask = Task { @MainActor [weak self] in
            do {
                let config = WhisperKitConfig(
                    model: "openai_whisper-tiny",
                    verbose: false
                )
                let kit = try await WhisperKit(config)
                self?.whisper = kit
                self?.isReady = true
            } catch {
                // 首次启动模型尚未下载时静默失败，UI 设置页提供下载入口
                self?.whisper = nil
                self?.isReady = false
            }
        }
        await loadTask?.value
    }

    func transcribe(samples: [Float], hintLanguageCode: String?) async throws -> ASRResult {
        if whisper == nil { await prepare() }
        guard let whisper else {
            throw ASRError.engineUnavailable("WhisperKit 模型未就绪，请在设置中下载模型")
        }

        let wavURL = try WAVWriter.writeTempWAV(samples: samples)
        defer { WAVWriter.cleanup(wavURL) }

        let language = Self.whisperLanguage(from: hintLanguageCode)
        let options = DecodingOptions(
            language: language,
            detectLanguage: language == nil
        )

        let result: TranscriptionResult? = try await whisper.transcribe(
            audioPath: wavURL.path,
            decodeOptions: options
        )
        guard let text = result?.text
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw ASRError.emptyResult
        }

        return ASRResult(text: text,
                         detectedLanguageCode: result?.language.flatMap { Self.localeCode(fromWhisper: $0) })
    }

    // zh → zh-Hans，en → en
    private static func whisperLanguage(from localeCode: String?) -> String? {
        guard let localeCode else { return nil }
        if localeCode.hasPrefix("zh") { return "zh" }
        if localeCode.hasPrefix("en") { return "en" }
        return localeCode.components(separatedBy: "-").first
    }

    private static func localeCode(fromWhisper code: String) -> String? {
        switch code {
        case "zh": return "zh-Hans"
        case "en": return "en"
        default:   return code
        }
    }
}
