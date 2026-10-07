import Foundation

struct TranslationPair {
    let source: String
    let target: String
}

/// 离线翻译引擎协议
protocol TranslationServicing {
    func prepare() async
    func translate(_ text: String, from sourceCode: String, to targetCode: String) async throws -> String
}

enum TranslationError: LocalizedError {
    case engineNotReady
    case languageUnavailable
    case argosNotInstalled

    var errorDescription: String? {
        switch self {
        case .engineNotReady:        "翻译引擎未就绪，请先在设置中下载离线语言包"
        case .languageUnavailable:   "该语言的离线包不可用"
        case .argosNotInstalled:     "Argos CoreML 引擎将在 V2.0 提供，请先用 Apple 离线翻译"
        }
    }
}

enum TranslationFactory {
    static func make(_ choice: MTEngineChoice) -> TranslationServicing {
        switch choice {
        case .apple: return AppleTranslationEngine.shared
        case .argos: return ArgosTranslationEngine()
        }
    }
}

/// BCP-47 与 Locale.Language 互转
enum LanguageMapper {
    static func language(from code: String) -> Locale.Language {
        Locale.Language(identifier: code)
    }
}
