import SwiftUI

struct ModeHomeView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackdrop()
                ScrollView {
                    VStack(spacing: 16) {
                        languagePairCard
                        modeCards
                        headphoneHint
                    }
                    .padding()
                }
            }
            .navigationTitle("离线实时翻译")
            .navigationDestination(for: TranslateMode.self) { mode in
                ConversationView(mode: mode)
            }
        }
    }

    private var languagePairCard: some View {
        VStack(spacing: 12) {
            HStack {
                languagePicker(selection: Bindable(settings).myLanguageCode,
                               title: "我说")
                Button {
                    swap(&settings.myLanguageCode, &settings.theirLanguageCode)
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                        .foregroundStyle(Color.brand)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassCircle(Color.brand)

                languagePicker(selection: Bindable(settings).theirLanguageCode,
                               title: "对方说")
            }
            Toggle("锁定语种（提高识别准确率）", isOn: Bindable(settings).lockLanguage)
                .font(.subheadline)
        }
        .padding()
        .glassCard()
    }

    private func languagePicker(selection: Binding<String>, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(LanguageOption.allCases) { opt in
                    Text(opt.label).tag(opt.rawValue)
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity)
    }

    private var modeCards: some View {
        VStack(spacing: 14) {
            ForEach(TranslateMode.allCases) { mode in
                NavigationLink(value: mode) {
                    HStack(spacing: 16) {
                        ZStack {
                            Image(systemName: mode.iconName)
                                .font(.title2)
                                .foregroundStyle(Color.brand)
                                .frame(width: 52, height: 52)
                        }
                        .glassTinted(Color.brand, cornerRadius: 14)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.title).font(.headline).foregroundStyle(.primary)
                            Text(mode.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .glassCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var headphoneHint: some View {
        let status = HeadphoneDetector.shared.current()
        return VStack(alignment: .leading, spacing: 6) {
            Label("适配耳机", systemImage: "headphones")
                .font(.subheadline.bold())
            Text(HeadphoneDetector.shared.supportedModelNames)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Circle()
                    .fill(status.model == .builtIn ? Color.orange : (status.supported ? Color.theirs : Color.orange))
                    .frame(width: 8, height: 8)
                Text(status.model == .builtIn ? "当前未连接耳机（可使用外放模式）" :
                     "当前：\(status.routeName)\(status.supported ? "" : "（非适配型号，可尝试使用）")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
    }
}
