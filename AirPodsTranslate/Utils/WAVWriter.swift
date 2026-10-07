import Foundation

enum WAVWriter {
    /// 将 16kHz Float32 单声道样本写成 16bit PCM WAV 临时文件
    static func writeTempWAV(samples: [Float], sampleRate: Int = 16_000) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("utter_\(UUID().uuidString).wav")

        let int16Samples = samples.map { s -> Int16 in
            let clamped = max(-1, min(1, s))
            return Int16(clamped * 32767)
        }

        var data = Data()
        let audioDataSize = int16Samples.count * 2
        let byteRate = sampleRate * 2
        let blockAlign = 2
        let bitsPerSample = 16

        func appendString(_ s: String) { data.append(s.data(using: .ascii)!) }
        func appendUInt32(_ v: UInt32) { var x = v.littleEndian; withUnsafeBytes(of: &x) { data.append(contentsOf: $0) } }
        func appendUInt16(_ v: UInt16) { var x = v.littleEndian; withUnsafeBytes(of: &x) { data.append(contentsOf: $0) } }

        appendString("RIFF")
        appendUInt32(UInt32(36 + audioDataSize))
        appendString("WAVE")
        appendString("fmt ")
        appendUInt32(16)
        appendUInt16(1)                    // PCM
        appendUInt16(1)                    // 单声道
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(byteRate))
        appendUInt16(UInt16(blockAlign))
        appendUInt16(UInt16(bitsPerSample))
        appendString("data")
        appendUInt32(UInt32(audioDataSize))

        for s in int16Samples {
            var v = s.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }

        try data.write(to: url)
        return url
    }

    static func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
