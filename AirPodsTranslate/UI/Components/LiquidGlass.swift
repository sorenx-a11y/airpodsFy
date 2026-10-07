import SwiftUI

/// iOS 26 Liquid Glass（液态玻璃）统一封装。
/// 背景为纯白/纯黑，玻璃只带轻微雾面与细边，不做彩色填充。
extension View {
    /// 液态玻璃卡片（轻微模糊 + 细边）
    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        glassEffect(.regular.tint(Color.primary.opacity(0.035)),
                    in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
            }
    }

    /// 液态玻璃圆钮（无色透明，仅轻微雾面）
    @ViewBuilder
    func glassCircle(_ tint: Color? = nil) -> some View {
        Group {
            if let tint {
                glassEffect(.regular.tint(tint).interactive(), in: Circle())
            } else {
                glassEffect(.regular.tint(Color.primary.opacity(0.035)).interactive(), in: Circle())
            }
        }
        .overlay {
            Circle().strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
        }
    }

    /// 对话气泡：无色透明液态玻璃（说话双方靠左右位置区分）
    func glassBubble() -> some View {
        glassEffect(.regular.tint(Color.primary.opacity(0.035)).interactive(),
                    in: .rect(cornerRadius: 19))
            .overlay {
                RoundedRectangle(cornerRadius: 19)
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
