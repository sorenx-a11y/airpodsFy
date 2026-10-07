import SwiftUI
import Observation
import AVFoundation

/// 对话模式
enum TranslateMode: String, CaseIterable, Identifiable {
    case conversation   // 面对面对话
    case listening      // 同声聆听

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conversation: "面对面对话"
        case .listening:    "同声聆听"
        }
    }

    var subtitle: String {
        switch self {
        case .conversation: "手机外放 / 耳机双栏字幕"
        case .listening:    "只听不说，译文进耳机"
        }
    }

    var iconName: String {
        switch self {
        case .conversation: "bubble.left.and.bubble.right.fill"
        case .listening:    "ear.fill"
        }
    }
}

/// 外观模式
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "跟随系统"
        case .light:  "浅色"
        case .dark:   "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

/// 普通对话模式下的音频路由策略
enum AudioRouteStrategy: String, CaseIterable, Identifiable {
    case headsetMic     // 耳机麦模式（HFP，耳机收音+耳机出声）
    case highQuality    // 高音质模式（A2DP 出声 + 手机麦收声）
    case speaker        // 外放行模式（手机麦 + 扬声器，系统回声消除）

    var id: String { rawValue }
    var title: String {
        switch self {
        case .headsetMic:  "耳机麦模式"
        case .highQuality: "高音质模式"
        case .speaker:     "外放模式"
        }
    }
}

enum ASREngineChoice: String, CaseIterable, Identifiable {
    case whisperKit
    case system

    var id: String { rawValue }
    var title: String {
        switch self {
        case .whisperKit: "WhisperKit（推荐）"
        case .system:     "系统识别器（省电）"
        }
    }
}

enum MTEngineChoice: String, CaseIterable, Identifiable {
    case apple
    case argos

    var id: String { rawValue }
    var title: String {
        switch self {
        case .apple: "Apple 离线翻译（推荐）"
        case .argos: "Argos CoreML（实验）"
        }
    }
}

@Observable
final class SettingsStore {
    // 外观
    var appearance: AppearanceMode = .system

    // 语言
    var myLanguageCode: String = "zh-Hans"
    var theirLanguageCode: String = "en"
    var lockLanguage: Bool = true

    // 音频
    var routeStrategy: AudioRouteStrategy = .headsetMic
    var denoiseEnabled: Bool = true
    var endpointSilence: Double = 0.6          // 秒：400/600/800/1000
    var translatedVolume: Double = 1.0

    // TTS
    var ttsEnabled: Bool = true
    var ttsRate: Float = AVSpeechUtteranceDefaultSpeechRate * 1.05

    // 引擎
    var asrEngine: ASREngineChoice = .whisperKit
    var mtEngine: MTEngineChoice = .apple

    // 数据
    var autoSaveHistory: Bool = true
}
