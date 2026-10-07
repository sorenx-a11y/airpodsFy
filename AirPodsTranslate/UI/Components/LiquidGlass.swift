import SwiftUI

/// iOS 26 Liquid Glass（液态玻璃）统一封装。
/// 玻璃材质会自动采样其后方内容做实时折射与模糊，
/// 因此需要放在有色彩/内容的背景之上才能看到完整质感。
extension View {
    /// 液态玻璃卡片
    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }

    /// 带色调的液态玻璃（用于强调按钮）
    func glassTinted(_ tint: Color, cornerRadius: CGFloat = 22) -> some View {
        glassEffect(.regular.tint(tint).interactive(),
                    in: .rect(cornerRadius: cornerRadius))
    }

    /// 液态玻璃圆形容器（播放、截句等圆形按钮）
    func glassCircle(_ tint: Color = .primary.opacity(0.85)) -> some View {
        glassEffect(.regular.tint(tint).interactive(), in: .circle)
    }
}

/// App 全局彩色底（液态玻璃的折射采样源，浅色/深色自适应）
struct GlassBackdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.black : Color(red: 0.93, green: 0.95, blue: 0.99))
                .ignoresSafeArea()
            MeshGradient(width: 3, height: 3, points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.1],
                [0.1, 0.5], [0.6, 0.55], [1.0, 0.5],
                [0.0, 1.0], [0.45, 1.0], [1.0, 0.95]
            ], colors: scheme == .dark ? [
                Color(red: 0.06, green: 0.10, blue: 0.22),
                Color(red: 0.08, green: 0.16, blue: 0.30),
                Color(red: 0.04, green: 0.12, blue: 0.16),
                Color(red: 0.10, green: 0.08, blue: 0.20),
                Color(red: 0.05, green: 0.14, blue: 0.24),
                Color(red: 0.04, green: 0.18, blue: 0.16),
                Color(red: 0.05, green: 0.08, blue: 0.16),
                Color(red: 0.08, green: 0.10, blue: 0.22),
                Color(red: 0.04, green: 0.12, blue: 0.14)
            ] : [
                Color(red: 0.80, green: 0.88, blue: 1.00),
                Color(red: 0.88, green: 0.83, blue: 1.00),
                Color(red: 0.80, green: 0.96, blue: 0.90),
                Color(red: 1.00, green: 0.88, blue: 0.82),
                Color(red: 0.84, green: 0.90, blue: 1.00),
                Color(red: 0.82, green: 0.97, blue: 0.93),
                Color(red: 0.92, green: 0.86, blue: 1.00),
                Color(red: 0.86, green: 0.92, blue: 1.00),
                Color(red: 0.88, green: 0.97, blue: 0.90)
            ])
            .ignoresSafeArea()
        }
    }
}
