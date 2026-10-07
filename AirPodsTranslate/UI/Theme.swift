import SwiftUI

extension Color {
    static let brand = Color(red: 0.118, green: 0.451, blue: 0.937)
    /// 我方链路色（耳机/蓝牙）
    static let mine = Color(red: 0.118, green: 0.451, blue: 0.937)
    /// 对方链路色（手机/扬声器）
    static let theirs = Color(red: 0.204, green: 0.659, blue: 0.322)
}

enum LanguageOption: String, CaseIterable, Identifiable {
    case zh = "zh-Hans"
    case en = "en"
    case ja
    case ko
    case fr
    case de
    case es

    var id: String { rawValue }
    var label: String {
        switch self {
        case .zh: "中文"
        case .en: "English"
        case .ja: "日本語"
        case .ko: "한국어"
        case .fr: "Français"
        case .de: "Deutsch"
        case .es: "Español"
        }
    }
}
