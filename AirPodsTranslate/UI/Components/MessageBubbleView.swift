import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    var isPlaying: Bool = false
    var onPlay: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            if message.speaker == .me {
                Spacer(minLength: 28)
                replayButton
            }

            VStack(alignment: message.speaker == .me ? .trailing : .leading, spacing: 4) {
                Text(message.source)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(message.translation.isEmpty ? "…" : message.translation)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.speaker == .me
                    ? Color.mine.opacity(0.14)
                    : Color.theirs.opacity(0.14)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if message.speaker == .them {
                replayButton
                Spacer(minLength: 28)
            }
        }
    }

    /// 气泡旁的单条重播按钮（液态玻璃圆形）
    private var replayButton: some View {
        Button {
            onPlay?()
        } label: {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .glassCircle(isPlaying
                     ? (message.speaker == .me ? Color.mine : Color.theirs)
                     : Color.primary.opacity(0.75))
        .accessibilityLabel(isPlaying ? "正在播放" : "重新播放")
        .disabled(message.translation.isEmpty)
    }
}
