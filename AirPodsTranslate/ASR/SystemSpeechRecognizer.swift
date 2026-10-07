import Foundation
import Speech

/// 系统 SFSpeechRecognizer 设备端离线识别（零包体、省电备选引擎）
final class SystemSpeechRecognizer: SpeechRecognizing {
    private(set) var isReady = false

    func prepare() async {
        isReady = true
    }

    func transcribe(samples: [Float], hintLanguageCode: String?) async throws -> ASRResult {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus != .authorized {
            let granted = await withCheckedContinuation { cont in
                SFSpeechRecognizer.requestAuthorization { status in
                    cont.resume(returning: status == .authorized)
                }
            }
            guard granted else { throw ASRError.notAuthorized }
        }

        let locale = hintLanguageCode.map { Locale(identifier: $0) } ?? Locale.current
        guard let recognizer = SFSpeechRecognizer(locale: locale),
              recognizer.isAvailable,
              recognizer.supportsOnDeviceRecognition else {
            throw ASRError.engineUnavailable("当前语言不支持设备端离线识别")
        }

        let wavURL = try WAVWriter.writeTempWAV(samples: samples)
        defer { WAVWriter.cleanup(wavURL) }

        let request = SFSpeechURLRecognitionRequest(url: wavURL)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        if #available(iOS 18.0, *) {
            request.addsPunctuation = true
        }

        return try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    if !didResume {
                        didResume = true
                        continuation.resume(throwing: error)
                    }
                    return
                }
                if let result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !didResume {
                        didResume = true
                        continuation.resume(returning: ASRResult(text: text,
                                                                detectedLanguageCode: locale.identifier))
                    }
                }
            }
            // 兜底：任务异常结束但没有 final
            Task {
                try? await Task.sleep(for: .seconds(15))
                task.cancel()
                if !didResume {
                    didResume = true
                    continuation.resume(throwing: ASRError.emptyResult)
                }
            }
        }
    }
}
