import SwiftUI

/// 实时电平波形：20 根柱子，由 VAD RMS 电平驱动
struct WaveformView: View {
    var level: Float
    var active: Bool
    var color: Color = .brand

    private let barCount = 20
    @State private var bars: [CGFloat] = Array(repeating: 0.05, count: 20)

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: 8 + CGFloat(bars[index]) * 36)
                    .animation(.easeOut(duration: 0.12), value: bars[index])
            }
        }
        .frame(height: 48)
        .onChange(of: level) { _, newValue in
            guard active else {
                bars = bars.map { max(0.05, $0 * 0.7) }
                return
            }
            // 中部高、两边低的包络 + 随机抖动，模拟真实语音波形
            let count = bars.count
            bars = bars.indices.map { i in
                let distance = abs(Double(i) - Double(count) / 2) / Double(count / 2)
                let envelope = 1.0 - distance * 0.6
                let jitter = Double.random(in: 0.55...1.0)
                let target = Double(newValue) * envelope * jitter
                return max(0.05, target)
            }
        }
    }
}

#Preview {
    WaveformView(level: 0.5, active: true)
}
