import SwiftUI

struct ModeHomeView: View {
    @Environment(SettingsStore.self) private var settings

    @State private var showMyLang = false
    @State private var showTheirLang = false

    private let languageOptions = LanguageOption.allCases.map {
        GlassOption(value: $0.rawValue, label: $0.label)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackdrop()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("离线实时翻译")
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 6)
                            .padding(.bottom, 4)
                        languagePairCard
                        modeCards
                        headphoneHint
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: TranslateMode.self) { mode in
                ConversationView(mode: mode)
            }
            .sheet(isPresented: $showMyLang) {
                GlassOptionSheet(title: "我的语言",
                                 options: languageOptions,
                                 selection: Bindable(settings).myLanguageCode)
            }
            .sheet(isPresented: $showTheirLang) {
                GlassOptionSheet(title: "对方语言",
                                 options: languageOptions,
                                 selection: Bindable(settings).theirLanguageCode)
            }
        }
    }

    // MARK: - 语言对卡片

    private var languagePairCard: some View {
        VStack(spacing: 13) {
            HStack(alignment: .bottom, spacing: 8) {
                languageBox(title: "我说", code: settings.myLanguageCode) { showMyLang = true }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swap(&settings.myLanguageCode, &settings.theirLanguageCode)
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassCircle(Color.brand)

                languageBox(title: "对方说", code: settings.theirLanguageCode) { showTheirLang = true }
            }

            HStack {
                Text("锁定语种（提高识别准确率）")
                    .font(.system(size: 13))
                Spacer()
                Toggle("", isOn: Bindable(settings).lockLanguage)
                    .labelsHidden()
                    .tint(Color.brand)
            }
        }
        .padding(16)
        .glassCard()
    }

    private func languageBox(title: String, code: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                HStack {
                    Text(label(for: code))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.brand)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func label(for code: String) -> String {
        LanguageOption(rawValue: code)?.label ?? code
    }

    // MARK: - 模式卡片

    private var modeCards: some View {
        VStack(spacing: 14) {
            ForEach(TranslateMode.allCases) { mode in
                NavigationLink(value: mode) {
                    HStack(spacing: 14) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.brand)
                            .frame(width: 52, height: 52)
                            .glassTinted(Color.brand, cornerRadius: 15)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(mode.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                            Text(mode.subtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .glassCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 耳机提示

    private var headphoneHint: some View {
        let status = HeadphoneDetector.shared.current()
        return VStack(alignment: .leading, spacing: 6) {
            Label("适配耳机", systemImage: "headphones")
                .font(.system(size: 13.5, weight: .bold))
            Text("AirPods Pro 2 及以上、AirPods 4、AirPods 3 · 系统 iOS 26 及以上")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            HStack(spacing: 7) {
                Circle()
                    .fill(status.model == .builtIn ? Color.orange : (status.supported ? Color.theirs : Color.orange))
                    .frame(width: 8, height: 8)
                Text(status.model == .builtIn
                     ? "当前未连接耳机（可使用外放模式）"
                     : "当前：\(status.routeName)\(status.supported ? "" : "（非适配型号，可尝试使用）")")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
}
