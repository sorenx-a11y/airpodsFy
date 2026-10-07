import SwiftUI
import SwiftData

struct HistoryListView: View {
    var wrapped: Bool = true

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

    var body: some View {
        if wrapped {
            NavigationStack { content }
        } else {
            content
        }
    }

    private var content: some View {
        Group {
            if conversations.isEmpty {
                ContentUnavailableView(
                    "暂无对话记录",
                    systemImage: "tray",
                    description: Text("完成的离线对话会保存在这里")
                )
            } else {
                List {
                    ForEach(conversations) { conv in
                        NavigationLink {
                            ConversationDetailView(conversation: conv)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conv.title).font(.headline)
                                HStack {
                                    Text("\(conv.messages.count) 句")
                                    Spacer()
                                    Text(conv.updatedAt, format: .dateTime.month().day().hour().minute())
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("记录")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(conversations[index])  // cascade 连带消息
        }
        try? modelContext.save()
    }
}
