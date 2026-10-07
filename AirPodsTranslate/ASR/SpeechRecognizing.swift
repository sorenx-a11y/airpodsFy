import Foundation

struct ASRResult {
    var text: String
    var detectedLanguageCode: String?   // 例如 zh-Hans / en
}

/// 离线语音识别引擎协议
protocol SpeechRecognizing {
    /// 引擎是否已就绪（模型加载完成）
    var isReady: Bool { get }
    func prepare() async
    /// - Parameter hintLanguageCode: 锁定语种提示，nil 表示自动检测
    func transcribe(samples: [Float], hintLanguageCode: String?) async throws -> ASRResult
}

enum ASRError: LocalizedError {
    case notAuthorized
    case emptyResult
    case engineUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:        "语音识别未授权"
        case .emptyResult:          "没有识别到内容"
        case .engineUnavailable(let m): m
        }
    }
}

enum ASRFactory {
    static func make(_ choice: ASREngineChoice) -> SpeechRecognizing {
        switch choice {
        case .whisperKit: return WhisperRecognizer()
        case .system:     return SystemSpeechRecognizer()
        }
    }
}
