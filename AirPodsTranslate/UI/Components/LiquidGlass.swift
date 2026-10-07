import SwiftUI

/// 全局主墨色：浅色模式为深灰（不用纯黑），深色模式为纯白。
/// 所有文字与图标统一使用该颜色。
extension Color {
    static let appInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 1)
            : UIColor(white: 0.30, alpha: 1)
    })
}

/// iOS 26 Liquid Glass（液态玻璃）统一封装。
/// 背景为纯白/纯黑，玻璃只带轻微雾面与细边，不做彩色填充。
///
/// 注意：玻璃一律放在 .background 里，文字/图标作为玻璃外的独立内容。
/// 若直接把内容包进 .glassEffect，系统会给内容叠加 vibrancy 自适应灰，
/// 浅色模式下图标和文字会整体发灰。
extension View {
    /// 液态玻璃卡片（轻微模糊 + 细边）
    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.clear)
                    .glassEffect(.regular.tint(Color.primary.opacity(0.035)),
                                 in: .rect(cornerRadius: cornerRadius))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
            }
    }

    /// 液态玻璃圆钮（无色透明，仅轻微雾面）
    @ViewBuilder
    func glassCircle(_ tint: Color? = nil) -> some View {
        self
            .background {
                Circle()
                    .fill(Color.clear)
                    .glassEffect(
                        tint.map { .regular.tint($0).interactive() } ?? .regular.tint(Color.primary.opacity(0.035)).interactive(),
                        in: Circle()
                    )
            }
            .overlay {
                Circle().strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
            }
    }

    /// 对话气泡：无色透明液态玻璃（说话双方靠左右位置区分）
    func glassBubble() -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(Color.clear)
                    .glassEffect(.regular.tint(Color.primary.opacity(0.035)).interactive(),
                                 in: .rect(cornerRadius: 19))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
            }
    }
}

/// App 全局底色：浅色纯白 / 深色纯黑
struct GlassBackdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        (scheme == .dark ? Color.black : Color.white)
            .ignoresSafeArea()
    }
}
