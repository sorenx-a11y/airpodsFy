import SwiftUI
import SwiftData

struct HistoryListView: View {
    var wrapped: Bool = true

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

    @State private var pendingDelete: Conversation?

    var body: some View {
        Group {
            if wrapped {
                NavigationStack { content }
            } else {
                content
            }
        }
    }

    private var content: some View {
        ZStack {
            GlassBackdrop()
            if conversations.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(conversations) { conv in
                            NavigationLink {
                                ConversationDetailView(conversation: conv)
                            } label: {
                                historyRow(conv)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    pendingDelete = conv
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle("记录")
        .navigationBarTitleDisplayMode(.inline)
        .alert("删除这条记录？", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("取消", role: .cancel) { pendingDelete = nil }
            Button("删除", role: .destructive) {
                if let conv = pendingDelete { delete(conv) }
                pendingDelete = nil
            }
        } message: {
            Text("该对话的全部译文将被删除，且无法恢复。")
        }
    }

    private func historyRow(_ conv: Conversation) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.brand)
                .frame(width: 38, height: 38)
                .glassTinted(Color.brand, cornerRadius: 11)

            VStack(alignment: .leading, spacing: 4) {
                Text(conv.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 12) {
                    Text("\(conv.messages.count) 句")
                    Text(Self.timeFormatter.string(from: conv.updatedAt))
                }
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)

            Button {
                pendingDelete = conv
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.red)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .glassCard(cornerRadius: 18)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("暂无对话记录")
                .font(.system(size: 15, weight: .semibold))
            Text("完成并退出的会话会保存在这里（本机存储）")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 40)
    }

    private func delete(_ conv: Conversation) {
        modelContext.delete(conv)  // cascade 连带消息
        try? modelContext.save()
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f
    }()
}
