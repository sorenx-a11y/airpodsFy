import Foundation
import NaturalLanguage

/// 用系统 NaturalLanguage 做离种语种判定，用于双栏自动归属。
enum LanguageDetector {
    /// 返回 zh-Hans / en 等语言码
    static func detect(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let lang = recognizer.dominantLanguage else { return nil }
        return map(lang)
    }

    static func map(_ lang: NLLanguage) -> String {
        switch lang {
        case .simplifiedChinese, .traditionalChinese:
            return "zh-Hans"
        case .english:
            return "en"
        case .japanese:
            return "ja"
        case .korean:
            return "ko"
        case .french:
            return "fr"
        case .german:
            return "de"
        case .spanish:
            return "es"
        default:
            return lang.rawValue
        }
    }

    /// 是否与目标语言码同根（zh-Hans / zh-CN 视为同语种）
    static func isSameLanguage(_ code1: String?, _ code2: String?) -> Bool {
        guard let code1, let code2 else { return false }
        return code1.split(separator: "-").first == code2.split(separator: "-").first
    }
}
