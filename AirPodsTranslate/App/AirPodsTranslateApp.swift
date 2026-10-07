import SwiftUI
import SwiftData

@main
struct AirPodsTranslateApp: App {
    @State private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(settings)
                .tint(.brand)
                .preferredColorScheme(settings.appearance.colorScheme)
                .attachTranslationSession()
        }
        .modelContainer(DataStack.shared.container)
    }
}

struct DataStack {
    static let shared = DataStack()

    let container: ModelContainer = {
        let schema = Schema([
            Conversation.self,
            MessageEntity.self,
            GlossaryEntry.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 初始化失败: \(error)")
        }
    }()
}
