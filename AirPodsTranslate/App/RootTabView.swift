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
                .padding(.horizontal, 10)
                .padding(.top, 6)
        }
    }

    // MARK: - 自定义液态玻璃 Tab Bar（选中项为圆角玻璃胶囊）

    private var customTabBar: some View {
        HStack(spacing: 6) {
            tabItem(.home, title: "对话", icon: "bubble.left.and.bubble.right.fill")
            tabItem(.history, title: "记录", icon: "clock.arrow.circlepath")
            tabItem(.settings, title: "设置", icon: "gearshape.fill")
        }
        .padding(8)
        .frame(height: 72)
        .glassCard(cornerRadius: 28)
    }

    private func tabItem(_ tab: Tab, title: String, icon: String) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                Text(title)
                    .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.brand : .secondary)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .glassCard(cornerRadius: 20)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView()
        .environment(SettingsStore())
}
