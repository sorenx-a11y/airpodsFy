import SwiftUI

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
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
    }

    // MARK: - 自定义底部栏（紧凑液态玻璃胶囊；长按后左右滑动切换）

    private var customTabBar: some View {
        let slotW = barWidth / CGFloat(Tab.allCases.count)
        let thumbSize: CGFloat = 30

        return GeometryReader { geo in
            HStack(spacing: 0) {
                tabItem(.home, title: "对话", icon: "bubble.left.and.bubble.right.fill")
                tabItem(.history, title: "记录", icon: "clock.arrow.circlepath")
                tabItem(.settings, title: "设置", icon: "gearshape.fill")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                if previewSlot != nil {
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                        .glassEffect(.regular.tint(Color.primary.opacity(0.10)).interactive(),
                                     in: Circle())
                        .frame(width: thumbSize, height: thumbSize)
                        .offset(x: thumbCenterX(slotWidth: slotW) - thumbSize / 2, y: 4)
                        .allowsHitTesting(false)
                }
            }
            .onAppear { barWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, w in barWidth = w }
            .contentShape(Rectangle())
            .gesture(barGesture(slotWidth: slotW))
        }
        .frame(height: 52)
        .glassEffect(.regular.tint(Color.primary.opacity(0.05)).interactive(),
                     in: .rect(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
        .scaleEffect(isPressing ? 0.97 : 1)
        .animation(.smooth(duration: 0.2), value: isPressing)
    }

    private func thumbCenterX(slotWidth: CGFloat) -> CGFloat {
        let half: CGFloat = 15
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
                        max(Int(round((dragStartX + dragTranslation) / slotWidth - 0.5)), 0),
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

    // MARK: - 单个 Tab

    private func tabItem(_ tab: Tab, title: String, icon: String) -> some View {
        let index = Tab.allCases.firstIndex(of: tab) ?? 0
        let isActive = (previewSlot ?? Tab.allCases.firstIndex(of: selection)) == index
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16.5, weight: .semibold))
                    .foregroundStyle(isActive ? Color.teal : Color.primary.opacity(0.85))
                    .frame(width: 30, height: 30)
                    .background {
                        if isActive && previewSlot == nil {
                            Circle()
                                .fill(Color.primary.opacity(0.06))
                                .glassEffect(.regular.tint(Color.primary.opacity(0.08)).interactive(),
                                             in: Circle())
                        }
                    }
                Text(title)
                    .font(.system(size: 9.5, weight: isActive ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isActive ? Color.teal : Color.primary.opacity(0.85))
            .opacity(isPressing && previewSlot != index ? 0.55 : 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView()
        .environment(SettingsStore())
}
