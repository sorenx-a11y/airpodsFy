import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    @Environment(SettingsStore.self) private var settings

    let conversation: Conversation

    @State private var playingId: UUID?

    var body: some View {
        ZStack {
            GlassBackdrop()
            ScrollView {
                VStack(spacing: 12) {
                    metaCard
                    ForEach(conversation.messages) { msg in
                        TranslationBubble(
                            speaker: msg.speaker,
                            source: msg.sourceText,
                            translation: msg.translatedText,
                            isPlaying: playingId == msg.id,
                            playEnabled: !msg.translatedText.isEmpty,
                            onPlay: { replay(msg) }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let url = exportURL {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private var metaCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Self.dateFormatter.string(from: conversation.updatedAt))
                .font(.system(size: 13, weight: .semibold))
            Text("\(conversation.messages.count) 句 · 本机保存")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .glassCard(cornerRadius: 16)
        .padding(.horizontal, 4)
    }

    private func replay(_ msg: MessageEntity) {
        let target = msg.speaker == .me ? settings.theirLanguageCode : settings.myLanguageCode
        playingId = msg.id
        Task {
            _ = await SpeechSpeaker.shared.speak(
                msg.translatedText,
                languageCode: target,
                volume: Float(settings.translatedVolume),
                rate: settings.ttsRate
            )
            await MainActor.run { playingId = nil }
        }
    }

    private var exportURL: URL? {
        var lines = ["# \(conversation.title)", Self.dateFormatter.string(from: conversation.updatedAt), ""]
        for m in conversation.messages {
            lines.append(m.speaker == .me ? "[我说] \(m.sourceText)" : "[对方] \(m.sourceText)")
            lines.append("    \(m.translatedText)")
            lines.append("")
        }
        let text = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("对话记录.txt")
        try? text.data(using: .utf8)?.write(to: url)
        return url
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日 HH:mm"
        return f
    }()
}
