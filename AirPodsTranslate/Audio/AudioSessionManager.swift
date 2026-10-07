import AVFoundation

/// 音频会话与路由编排（单例，进程内只观察一次系统通知）。
final class AudioSessionManager: NSObject {
    static let shared = AudioSessionManager()

    private let session = AVAudioSession.sharedInstance()

    /// 路由/中断事件（最后设置者生效）
    var onRouteChange: ((AVAudioSession.RouteChangeReason) -> Void)?
    var onInterruption: ((Bool) -> Void)?   // true = 开始中断, false = 结束可恢复

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    // MARK: - 权限

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - 普通模式路由配置

    func configure(strategy: AudioRouteStrategy) throws {
        switch strategy {
        case .headsetMic:
            // HFP：耳机麦输入 + 耳机输出（通话级 16k 宽带语音）
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .interruptSpokenAudioAndMixWithOthers]
            )
            try session.overrideOutputAudioPort(.none)

        case .highQuality:
            // A2DP：高音质耳机输出，输入回退到手机麦
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothA2DP, .interruptSpokenAudioAndMixWithOthers]
            )
            try session.overrideOutputAudioPort(.none)
            try selectBuiltInInput()

        case .speaker:
            // 外放：手机麦 + 扬声器，voiceChat 自带系统回声消除防啸叫
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .interruptSpokenAudioAndMixWithOthers]
            )
            try session.overrideOutputAudioPort(.speaker)
            try selectBuiltInInput()
        }
        try session.setActive(true)
    }

    func deactivate() {
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    /// 中断结束后重新激活（保持当前 category/options）
    func setActive(_ active: Bool) throws {
        try session.setActive(active)
    }

    // MARK: - Private

    private func selectBuiltInInput() throws {
        guard let builtIn = session.availableInputs?.first(where: {
            $0.portType == .builtInMic
        }) else { return }
        try session.setPreferredInput(builtIn)
    }

    @objc private func handleRouteChange(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else {
            return
        }
        onRouteChange?(reason)
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else {
            return
        }
        onInterruption?(type == .began)
    }
}
