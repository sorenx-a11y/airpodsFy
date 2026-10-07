import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                languageSection
                audioSection
                ttsSection
                engineSection
                dataSection
                aboutSection
            }
            .navigationTitle("设置")
        }
    }

    private var appearanceSection: some View {
        Section("外观") {
            Picker("显示模式", selection: Bindable(settings).appearance) {
                ForEach(AppearanceMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var languageSection: some View {
        Section("语言") {
            Picker("我的语言", selection: Bindable(settings).myLanguageCode) {
                ForEach(LanguageOption.allCases) { Text($0.label).tag($0.rawValue) }
            }
            Picker("对方语言", selection: Bindable(settings).theirLanguageCode) {
                ForEach(LanguageOption.allCases) { Text($0.label).tag($0.rawValue) }
            }
            Toggle("锁定语种", isOn: Bindable(settings).lockLanguage)
        }
    }

    private var audioSection: some View {
        Section("音频") {
            Picker("对话模式路由", selection: Bindable(settings).routeStrategy) {
                ForEach(AudioRouteStrategy.allCases) { Text($0.title).tag($0) }
            }
            Toggle("环境降噪（V1.5）", isOn: Bindable(settings).denoiseEnabled)
            Picker("句末静音时长", selection: Bindable(settings).endpointSilence) {
                Text("0.4 秒").tag(0.4)
                Text("0.6 秒").tag(0.6)
                Text("0.8 秒").tag(0.8)
                Text("1.0 秒").tag(1.0)
            }
        }

    }

    private var ttsSection: some View {
        Section("朗读") {
            Toggle("自动朗读译文", isOn: Bindable(settings).ttsEnabled)
            VStack {
                Text("语速 \(Int(settings.ttsRate / AVSpeechDefaultRate * 100))%")
                Slider(value: Bindable(settings).ttsRate,
                       in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
            }
            VStack {
                Text("译文耳机音量 \(Int(settings.translatedVolume * 100))%")
                Slider(value: Bindable(settings).translatedVolume, in: 0.3...1)
            }
        }
    }

    private var engineSection: some View {
        Section("离线引擎") {
            Picker("语音识别 ASR", selection: Bindable(settings).asrEngine) {
                ForEach(ASREngineChoice.allCases) { Text($0.title).tag($0) }
            }
            Picker("翻译 MT", selection: Bindable(settings).mtEngine) {
                ForEach(MTEngineChoice.allCases) { Text($0.title).tag($0) }
            }
            NavigationLink {
                GlossaryView()
            } label: {
                Label("术语库", systemImage: "character.book.closed")
            }
            Text("Apple 翻译语言包由系统在首次翻译时引导下载，下载后永久离线；WhisperKit base 模型走 App 内一次性下载。")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var dataSection: some View {
        Section("数据") {
            Toggle("自动保存对话记录", isOn: Bindable(settings).autoSaveHistory)
            NavigationLink("已保存的记录") {
                HistoryListView(wrapped: false)
            }
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            VStack(alignment: .leading, spacing: 6) {
                Text("适配耳机").font(.subheadline.bold())
                Text(HeadphoneDetector.shared.supportedModelNames)
                    .font(.caption).foregroundStyle(.secondary)
                Text("系统要求：iOS 26 及以上")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text("全部识别与翻译在本机完成，零联网、零订阅、无服务器。")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}
