import AVFoundation

/// 一路 16kHz 单声道音频帧
struct AudioFrame {
    let samples: [Float]      // Float32, [-1, 1]
    let time: TimeInterval
}

/// 麦克风采集引擎（音频线程内部自洽，不跨 actor）：
/// - installTap 持续采集，重采样为 16k 单声道
/// - 内置能量 VAD，回调语音开始/整句结束
/// - 实时 RMS 电平（20fps 节流，供 UI 波形）
final class AudioCaptureEngine {
    private let engine = AVAudioEngine()
    private let resampler = Resampler16k()
    fileprivate let vad = EnergyVAD()

    private var startTime: TimeInterval = 0
    private var lastLevelEmit: TimeInterval = 0

    /// 检测到人声开始（在音频线程回调，调用方自行切线程）
    var onSpeechStart: (() -> Void)?
    /// 一句结束：16k Float32 整句样本（音频线程回调）
    var onUtterance: (([Float]) -> Void)?
    /// 0...1 实时电平，约 20fps
    var onLevel: ((Float) -> Void)?

    var isRunning: Bool { engine.isRunning }

    func configureVAD(endpointSilence: TimeInterval) {
        vad.endpointSilence = endpointSilence
    }

    /// 手动立即截句
    func flush() {
        vad.flush()
    }

    // MARK: - 生命周期

    func start() throws {
        guard !engine.isRunning else { return }

        let input = engine.inputNode
        let hwFormat = input.inputFormat(forBus: 0)

        vad.onEvent = { [weak self] event in
            switch event {
            case .speechStart:
                self?.onSpeechStart?()
            case .speechEnd(let samples, _), .maxDuration(let samples):
                self?.onUtterance?(samples)
            }
        }
        installTap(on: input, format: hwFormat)
        engine.prepare()
        try engine.start()
        startTime = CACurrentMediaTime()
    }

    func stop() {
        guard engine.isRunning else {
            vad.reset()
            return
        }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        vad.reset()
    }

    // MARK: - Tap

    private func installTap(on input: AVAudioInputNode, format: AVAudioFormat) {
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.handleBuffer(buffer)
        }
    }

    private func handleBuffer(_ buffer: AVAudioPCMBuffer) {
        let rms = computeRMS(buffer)
        let normalizedLevel = min(1, rms * 4)

        let now = CACurrentMediaTime()
        if now - lastLevelEmit > 0.05 {
            lastLevelEmit = now
            onLevel?(normalizedLevel)
        }

        guard let samples = resampler.samples(from: buffer) else { return }
        let frame = AudioFrame(samples: samples, time: now - startTime)
        vad.append(frame)
    }

    private func computeRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channels = Int(buffer.format.channelCount)
        let length = Int(buffer.frameLength)
        guard length > 0 else { return 0 }

        var sum: Float = 0
        for ch in 0..<channels {
            let ptr = channelData[ch]
            for i in 0..<length {
                sum += ptr[i] * ptr[i]
            }
        }
        return sqrtf(sum / Float(length * channels))
    }
}
