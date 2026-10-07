import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    @Bindable var conversation: Conversation

    private var sortedMessages: [MessageEntity] {
        conversation.messages.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        List(sortedMessages) { message in
            VStack(alignment: message.speaker == .me ? .trailing : .leading, spacing: 4) {
                Text(message.sourceText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(message.translatedText)
                    .font(.body.bold())
                Text(message.createdAt, format: .dateTime.hour().minute().second())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity,
                   alignment: message.speaker == .me ? .trailing : .leading)
            .listRowBackground(
                (message.speaker == .me ? Color.mine : Color.theirs)
                    .opacity(0.08)
            )
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: exportText)
            }
        }
    }

    private var exportText: String {
        let lines = sortedMessages.map { msg -> String in
            let who = msg.speaker == .me ? "我" : "对方"
            return "[\(who)] \(msg.sourceText)\n  → \(msg.translatedText)"
        }
        return lines.joined(separator: "\n\n")
    }
}
