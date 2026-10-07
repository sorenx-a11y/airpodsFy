import SwiftUI

struct RootTabView: View {
    enum Tab: Hashable {
        case home, history, settings
    }

    @State private var selection: Tab = .home

    var body: some View {
        Group {
            switch selection {
            case .home:     ModeHomeView()
            case .history:  HistoryListView(wrapped: true)
            case .settings: SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
                .padding(.horizontal, 12)
                .padding(.top, 6)
        }
    }

    // MARK: - 自定义底部栏（仿 iOS 27 翻译 App：灰色玻璃胶囊，选中项为青色圆形）

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(.home, title: "对话", icon: "bubble.left.and.bubble.right.fill")
            tabItem(.history, title: "记录", icon: "clock.arrow.circlepath")
            tabItem(.settings, title: "设置", icon: "gearshape.fill")
        }
        .frame(height: 76)
        .glassEffect(.regular.tint(Color.primary.opacity(0.12)).interactive(),
                     in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
    }

    private func tabItem(_ tab: Tab, title: String, icon: String) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : Color.primary.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background {
                        if isSelected {
                            Circle().fill(Color.teal)
                        }
                    }
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? Color.teal : Color.primary.opacity(0.9))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView()
        .environment(SettingsStore())
}
