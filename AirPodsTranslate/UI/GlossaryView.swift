import SwiftUI
import SwiftData

struct GlossaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsStore.self) private var settings
    @Query(sort: \GlossaryEntry.createdAt, order: .reverse)
    private var entries: [GlossaryEntry]

    @State private var showAdd = false
    @State private var sourceInput = ""
    @State private var replacementInput = ""

    private var pairKey: String {
        "\(settings.myLanguageCode) -> \(settings.theirLanguageCode)"
    }

    var body: some View {
        List {
            Section {
                Text("当前语言对：\(pairKey)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("术语（源词 → 期望译法）") {
                ForEach(entries) { entry in
                    HStack {
                        Text(entry.source)
                        Spacer()
                        Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                        Text(entry.replacement).foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("术语库")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appInk)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .glassCircle()
            }
        }
        .alert("添加术语", isPresented: $showAdd) {
            TextField("源词（如公司名）", text: $sourceInput)
            TextField("期望译法", text: $replacementInput)
            Button("取消", role: .cancel) { clearInputs() }
            Button("保存") { addEntry() }
        }
    }

    private func addEntry() {
        let s = sourceInput.trimmingCharacters(in: .whitespaces)
        let r = replacementInput.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, !r.isEmpty else { return }
        let entry = GlossaryEntry(source: s, replacement: r, pairKey: pairKey)
        modelContext.insert(entry)
        try? modelContext.save()
        clearInputs()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
    }

    private func clearInputs() {
        sourceInput = ""
        replacementInput = ""
    }
}
