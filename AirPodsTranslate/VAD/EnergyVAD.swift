import Foundation

/// VAD 输出事件
enum VADEvent {
    case speechStart
    /// 一句结束，samples 为 16k Float32 整句音频（含约 200ms 前置缓存）
    case speechEnd(samples: [Float], duration: TimeInterval)
    /// 超长句强制截断
    case maxDuration(samples: [Float])
}

/// 语音活动检测器协议（当前为能量实现，后续可平替 WebRTC VAD）
protocol VoiceActivityDetecting {
    var onEvent: ((VADEvent) -> Void)? { get set }
    func append(_ frame: AudioFrame)
    func reset()
}

/// 自适应能量 VAD 状态机：
/// 待机 → 检测到人声(超过自适应噪声底) → 说话中
///      → 连续静音 endpointSilence 秒 → 截句输出
///      → 超过 maxDuration 强制截断
final class EnergyVAD: VoiceActivityDetecting {
    var onEvent: ((VADEvent) -> Void)?

    /// 句末静音时长（秒）
    var endpointSilence: TimeInterval = 0.6
    /// 最短有效语音（秒），过滤咳嗽/碰撞声
    var minSpeechDuration: TimeInterval = 0.25
    /// 单句最长时长（秒）
    var maxDuration: TimeInterval = 20
    /// 触发判定相对噪声底的增益（dB 感），越大越不敏感
    var triggerMargin: Float = 2.5

    private let preRoll: TimeInterval = 0.2
    private var preRollBuffer: [Float] = []

    private var utterance: [Float] = []
    private var speechDuration: TimeInterval = 0
    private var silenceDuration: TimeInterval = 0
    private var isSpeaking = false

    /// 自适应噪声底（RMS）
    private var noiseFloor: Float = 0.01
    private let sampleRate: Double = 16_000

    func append(_ frame: AudioFrame) {
        let level = rms(frame.samples)
        let threshold = noiseFloor * triggerMargin + 0.008
        let voiced = level > threshold
        let frameDuration = Double(frame.samples.count) / sampleRate

        if !isSpeaking {
            // 更新噪声底（缓慢逼近环境）
            if level < noiseFloor * 1.5 {
                noiseFloor = noiseFloor * 0.95 + level * 0.05
            }
            appendPreRoll(frame.samples)

            if voiced {
                beginSpeech()
                appendSamples(frame.samples)
                speechDuration += frameDuration
            }
            return
        }

        // 说话中
        appendSamples(frame.samples)
        speechDuration += frameDuration

        if voiced {
            silenceDuration = 0
        } else {
            silenceDuration += frameDuration
        }

        if speechDuration >= maxDuration {
            finish(forced: true)
            return
        }

        if silenceDuration >= endpointSilence {
            finish(forced: false)
        }
    }

    /// 手动截句（AirPods 捏合 / 界面按钮）：立即结束当前句
    func flush() {
        guard isSpeaking else { return }
        finish(forced: false)
    }

    func reset() {
        utterance.removeAll(keepingCapacity: true)
        preRollBuffer.removeAll(keepingCapacity: true)
        speechDuration = 0
        silenceDuration = 0
        isSpeaking = false
    }

    // MARK: - Private

    private func beginSpeech() {
        isSpeaking = true
        silenceDuration = 0
        speechDuration = 0
        utterance.removeAll(keepingCapacity: true)
        utterance.append(contentsOf: preRollBuffer)
        onEvent?(.speechStart)
    }

    private func finish(forced: Bool) {
        guard isSpeaking else { return }
        let audio = utterance
        let duration = speechDuration
        reset()

        guard duration >= minSpeechDuration, !audio.isEmpty else { return }

        if forced {
            onEvent?(.maxDuration(samples: audio))
        } else {
            onEvent?(.speechEnd(samples: audio, duration: duration))
        }
    }

    private func appendSamples(_ samples: [Float]) {
        utterance.append(contentsOf: samples)
    }

    private func appendPreRoll(_ samples: [Float]) {
        preRollBuffer.append(contentsOf: samples)
        let maxSamples = Int(preRoll * sampleRate)
        if preRollBuffer.count > maxSamples {
            preRollBuffer.removeFirst(preRollBuffer.count - maxSamples)
        }
    }

    private func rms(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        var sum: Float = 0
        for s in samples { sum += s * s }
        return sqrtf(sum / Float(samples.count))
    }
}
