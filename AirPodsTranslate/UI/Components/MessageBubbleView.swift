import SwiftUI

/// 通用译文字泡：原文小字 + 译文大字，液态玻璃材质。
/// 会话页（ChatMessage）与记录详情页（MessageEntity）共用。
struct TranslationBubble: View {
    let speaker: Speaker
    var source: String
    var translation: String
    var isProcessing: Bool = false
    var isPlaying: Bool = false
    var playEnabled: Bool = true
    var onPlay: (() -> Void)?

    private var isMe: Bool { speaker == .me }

    var body: some View {
        HStack(spacing: 7) {
            if isMe {
                Spacer(minLength: 24)
                replayButton
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                Text(source)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                Text(translation.isEmpty ? "翻译中…" : translation)
                    .font(.system(size: 16.5, weight: .bold))
                    .foregroundStyle(isProcessing || translation.isEmpty ? .secondary : .primary)
                    .lineLimit(nil)
            }
            .frame(maxWidth: 280, alignment: isMe ? .trailing : .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassBubble()

            if !isMe {
                replayButton
                Spacer(minLength: 24)
            }
        }
    }

    private var replayButton: some View {
        Button {
            onPlay?()
        } label: {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                .font(.system(size: isPlaying ? 14 : 13, weight: .bold))
                .foregroundStyle(Color.primary)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .glassCircle()
        .accessibilityLabel(isPlaying ? "正在播放" : "重新播放")
        .disabled(!playEnabled)
        .opacity(playEnabled ? 1 : 0.4)
    }
}

/// 会话页气泡：绑定 ChatMessage
struct MessageBubbleView: View {
    let message: ChatMessage
    var isPlaying: Bool = false
    var onPlay: (() -> Void)? = nil

    var body: some View {
        TranslationBubble(
            speaker: message.speaker,
            source: message.source,
            translation: message.translation,
            isProcessing: message.isProcessing,
            isPlaying: isPlaying,
            playEnabled: !message.translation.isEmpty,
            onPlay: onPlay
        )
    }
}
