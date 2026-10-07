import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings

    @State private var sheet: SheetKind?

    private enum SheetKind: Identifiable {
        case myLang, theirLang, strategy, silence, asr, mt
        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackdrop()
                ScrollView {
                    VStack(spacing: 0) {
                        appearanceSection
                        languageSection
                        audioSection
                        engineSection
                        dataSection
                        aboutSection
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { _ in GlossaryView() }
        }
        .sheet(item: $sheet) { kind in
            sheetContent(kind)
                .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - 外观

    private var appearanceSection: some View {
        VStack(spacing: 0) {
            GroupTitle(text: "外观")
            SettingsGroup {
                VStack(spacing: 0) {
                    HStack {
                        Text("深色模式")
                            .font(.system(size: 14.5))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 13)

                    HStack(spacing: 6) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    settings.appearance = mode
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: icon(for: mode))
                                        .font(.system(size: 13))
                                    Text(mode.title)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .foregroundStyle(settings.appearance == mode ? Color.brand : .secondary)
                            }
                            .buttonStyle(.plain)
                            .background {
                                if settings.appearance == mode {
                                    RoundedRectangle(cornerRadius: 11)
                                        .glassTinted(Color.brand, cornerRadius: 11)
                                }
                            }
                        }
                    }
                    .padding(5)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    private func icon(for mode: AppearanceMode) -> String {
        switch mode {
        case .system: "smartphone"
        case .light:  "sun.max"
        case .dark:   "moon"
        }
    }

    // MARK: - 语言

    private var languageSection: some View {
        VStack(spacing: 0) {
            GroupTitle(text: "语言")
            SettingsGroup {
                SettingsRow(icon: "globe", title: "我的语言", showChevron: true,
                            action: { sheet = .myLang }) {
                    Text(LanguageOption(rawValue: settings.myLanguageCode)?.label ?? "")
                        .settingValue()
                }
                RowDivider()
                SettingsRow(icon: "globe.americas.fill", title: "对方语言", showChevron: true,
                            action: { sheet = .theirLang }) {
                    Text(LanguageOption(rawValue: settings.theirLanguageCode)?.label ?? "")
                        .settingValue()
                }
                RowDivider()
                SettingsRow(icon: "lock.fill", title: "锁定语种，提高识别准确率") {
                    Toggle("", isOn: Bindable(settings).lockLanguage)
                        .labelsHidden().tint(Color.brand)
                }
            }
        }
    }

    // MARK: - 音频

    private var audioSection: some View {
        VStack(spacing: 0) {
            GroupTitle(text: "音频")
            SettingsGroup {
                SettingsRow(icon: "headphones", title: "面对面对话音频路由", showChevron: true,
                            action: { sheet = .strategy }) {
                    Text(settings.routeStrategy.title).settingValue()
                }
                RowDivider()
                SettingsRow(icon: "timer", title: "句末静音时长", showChevron: true,
                            action: { sheet = .silence }) {
                    Text(String(format: "%.1f 秒", settings.endpointSilence)).settingValue()
                }
                RowDivider()
                VStack(spacing: 4) {
                    HStack {
                        Text("译文音量").font(.system(size: 14.5))
                        Spacer()
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Bindable(settings).translatedVolume, in: 0.2...1.0)
                        .tint(Color.brand)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                RowDivider()
                SettingsRow(icon: "speaker.wave.2.fill", title: "朗读译文") {
                    Toggle("", isOn: Bindable(settings).ttsEnabled)
                        .labelsHidden().tint(Color.brand)
                }
                if settings.ttsEnabled {
                    RowDivider()
                    VStack(spacing: 4) {
                        HStack {
                            Text("朗读语速").font(.system(size: 14.5))
                            Spacer()
                            Text("\(Int(settings.ttsRate / 0.5 * 100))%")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Bindable(settings).ttsRate, in: 0.35...0.65)
                            .tint(Color.brand)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                }
            }
        }
    }

    // MARK: - 引擎

    private var engineSection: some View {
        VStack(spacing: 0) {
            GroupTitle(text: "离线引擎")
            SettingsGroup {
                SettingsRow(icon: "waveform", title: "语音识别", showChevron: true,
                            action: { sheet = .asr }) {
                    Text(settings.asrEngine == .whisperKit ? "WhisperKit" : "系统识别器")
                        .settingValue()
                }
                RowDivider()
                SettingsRow(icon: "character.bubble", title: "机器翻译", showChevron: true,
                            action: { sheet = .mt }) {
                    Text(settings.mtEngine == .apple ? "Apple 翻译" : "Argos")
                        .settingValue()
                }
            }
            SettingsNote(text: "全部模型在设备端运行，无需联网、无订阅。首次使用会下载对应离线模型。")
        }
    }

    // MARK: - 数据

    private var dataSection: some View {
        VStack(spacing: 0) {
            GroupTitle(text: "数据")
            SettingsGroup {
                NavigationLink(value: "glossary") {
                    SettingsRow(icon: "book.fill", title: "术语库", showChevron: true) {
                        EmptyView()
                    }
                }
                .buttonStyle(.plain)
                RowDivider()
                SettingsRow(icon: "internaldrive", title: "自动保存对话记录") {
                    Toggle("", isOn: Bindable(settings).autoSaveHistory)
                        .labelsHidden().tint(Color.brand)
                }
            }
            SettingsNote(text: "记录与术语仅保存在本机，卸载 App 会一并清除。")
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        VStack(spacing: 0) {
            GroupTitle(text: "关于")
            SettingsGroup {
                SettingsRow(icon: "info.circle", title: "AirPods 离线实时翻译") {
                    Text("v1.0").settingValue()
                }
            }
            SettingsNote(text: "适配 AirPods Pro 2 及以上 / AirPods 4 / AirPods 3，需 iOS 26 及以上。全程离线，零联网零订阅。")
        }
    }

    // MARK: - 选择 sheets

    @ViewBuilder
    private func sheetContent(_ kind: SheetKind) -> some View {
        switch kind {
        case .myLang:
            GlassOptionSheet(title: "我的语言",
                             options: LanguageOption.allCases.map { GlassOption(value: $0.rawValue, label: $0.label) },
                             selection: Bindable(settings).myLanguageCode)
        case .theirLang:
            GlassOptionSheet(title: "对方语言",
                             options: LanguageOption.allCases.map { GlassOption(value: $0.rawValue, label: $0.label) },
                             selection: Bindable(settings).theirLanguageCode)
        case .strategy:
            GlassOptionSheet(title: "音频路由",
                             options: AudioRouteStrategy.allCases.map { GlassOption(value: $0, label: $0.title) },
                             selection: Bindable(settings).routeStrategy)
        case .silence:
            GlassOptionSheet(title: "句末静音时长",
                             options: [0.4, 0.6, 0.8, 1.0].map { GlassOption(value: $0, label: String(format: "%.1f 秒", $0)) },
                             selection: Bindable(settings).endpointSilence)
        case .asr:
            GlassOptionSheet(title: "语音识别引擎",
                             options: ASREngineChoice.allCases.map { GlassOption(value: $0, label: $0.title) },
                             selection: Bindable(settings).asrEngine)
        case .mt:
            GlassOptionSheet(title: "机器翻译引擎",
                             options: MTEngineChoice.allCases.map { GlassOption(value: $0, label: $0.title) },
                             selection: Bindable(settings).mtEngine)
        }
    }
}

private extension Text {
    func settingValue() -> some View {
        self.font(.system(size: 13))
            .foregroundStyle(.secondary)
    }
}
