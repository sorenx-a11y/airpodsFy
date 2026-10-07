import SwiftUI

/// Tab 选中青色：深色模式亮青（仿 iOS 27 翻译 App），浅色模式加深保证白底对比
extension Color {
    static let tabCyan = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.00, green: 0.84, blue: 0.92, alpha: 1)
            : UIColor(red: 0.00, green: 0.56, blue: 0.66, alpha: 1)
    })
}

struct RootTabView: View {
    enum Tab: Hashable, CaseIterable {
        case home, history, settings
    }

    @State private var selection: Tab = .home

    // 长按拖动切换
    @State private var isPressing = false
    @State private var dragTranslation: CGFloat = 0
    @State private var dragStartX: CGFloat = 0
    @State private var previewSlot: Int?
    @State private var barWidth: CGFloat = 0
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    private let barHeight: CGFloat = 58
    private let thumbHeight: CGFloat = 48
    private let thumbCorner: CGFloat = 18

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
                .padding(.horizontal, 14)
                .padding(.top, 4)
        }
    }

    // MARK: - 自定义底部栏（仿 iOS 27 翻译 App：灰色玻璃胶囊 + 整块深色圆角选中块，长按可左右滑动）

    private var customTabBar: some View {
        let slotW = barWidth / CGFloat(Tab.allCases.count)
        let thumbW = max(slotW - 12, 0)

        return HStack(spacing: 0) {
            tabItem(.home, title: "对话", icon: "bubble.left.and.bubble.right.fill")
            tabItem(.history, title: "记录", icon: "clock.arrow.circlepath")
            tabItem(.settings, title: "设置", icon: "gearshape.fill")
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .background(alignment: .topLeading) {
            // 长按拖动时跟手移动的选中块（在标签之下、玻璃胶囊之上）
            if previewSlot != nil {
                RoundedRectangle(cornerRadius: thumbCorner, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: thumbW, height: thumbHeight)
                    .offset(x: thumbCenterX(slotWidth: slotW) - thumbW / 2,
                            y: (barHeight - thumbHeight) / 2)
                    .allowsHitTesting(false)
            }
        }
        .background {
            // 宽度测量
            GeometryReader { geo in
                Color.clear
                    .onAppear { barWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in barWidth = w }
            }
        }
        .background {
            // 整块灰色玻璃胶囊
            Capsule(style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular.tint(Color.primary.opacity(0.16)).interactive(),
                             in: Capsule())
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
        }
        .scaleEffect(isPressing ? 0.98 : 1)
        .animation(.smooth(duration: 0.2), value: isPressing)
        .contentShape(Capsule())
        .gesture(barGesture(slotWidth: slotW))
    }

    private func thumbCenterX(slotWidth: CGFloat) -> CGFloat {
        let half = max(slotWidth / 2, 1)
        let raw = dragStartX + dragTranslation
        return min(max(raw, half), max(barWidth - half, half))
    }

    // MARK: - 长按 + 左右滑动手势

    private func barGesture(slotWidth: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.22)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    isPressing = true
                    impact.impactOccurred(intensity: 0.7)
                case .second(true, let drag?):
                    if previewSlot == nil {
                        dragStartX = drag.startLocation.x
                    }
                    dragTranslation = drag.translation.width
                    let target = min(
                        max(Int((dragStartX + dragTranslation) / slotWidth), 0),
                        Tab.allCases.count - 1
                    )
                    if previewSlot != target {
                        previewSlot = target
                        selectionFeedback.selectionChanged()
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                if case .second(true, _) = value, let slot = previewSlot {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = Tab.allCases[slot]
                    }
                }
                isPressing = false
                previewSlot = nil
                dragTranslation = 0
            }
    }

    // MARK: - 单个 Tab（图标 + 文字，选中时整块包在深色圆角块中）

    private func tabItem(_ tab: Tab, title: String, icon: String) -> some View {
        let index = Tab.allCases.firstIndex(of: tab) ?? 0
        let isActive = (previewSlot ?? Tab.allCases.firstIndex(of: selection)) == index
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: isActive ? .semibold : .medium))
            }
            .foregroundStyle(isActive ? Color.tabCyan : Color.appInk)
            .frame(maxWidth: .infinity)
            .frame(height: thumbHeight)
            .padding(.horizontal, 6)
            .background {
                if isActive && previewSlot == nil {
                    RoundedRectangle(cornerRadius: thumbCorner, style: .continuous)
                        .fill(Color(uiColor: .systemBackground))
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
