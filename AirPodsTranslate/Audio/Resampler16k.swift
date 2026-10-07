import AVFoundation

/// 把硬件采集格式（通常 48kHz Float32 非交错）转换为 ASR/VAD 所需的
/// 16kHz、单声道、Float32 PCM。
final class Resampler16k {
    let targetFormat: AVAudioFormat

    init() {
        guard let fmt = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        ) else {
            fatalError("无法创建 16k Float32 音频格式")
        }
        self.targetFormat = fmt
    }

    private var converter: AVAudioConverter?
    private var converterSourceFormat: AVAudioFormat?

    func convert(_ inputBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let inputFormat = inputBuffer.format

        if converter == nil || converterSourceFormat != inputFormat {
            converter = AVAudioConverter(from: inputFormat, to: targetFormat)
            converterSourceFormat = inputFormat
        }
        guard let converter else { return nil }

        let ratio = targetFormat.sampleRate / inputFormat.sampleRate
        let capacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio + 1024)
        guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else {
            return nil
        }

        var fedOnce = false
        var convError: NSError?
        let status = converter.convert(to: output, error: &convError) { _, outStatus in
            if fedOnce {
                outStatus.pointee = .noDataNow
                return nil
            }
            fedOnce = true
            outStatus.pointee = .haveData
            return inputBuffer
        }

        guard status != .error, convError == nil else {
            return nil
        }
        return output
    }

    /// 取 16k 单声道 Float32 样本数组
    func samples(from inputBuffer: AVAudioPCMBuffer) -> [Float]? {
        guard let converted = convert(inputBuffer),
              let channelData = converted.floatChannelData else {
            return nil
        }
        let count = Int(converted.frameLength)
        return Array(UnsafeBufferPointer(start: channelData[0], count: count))
    }
}
