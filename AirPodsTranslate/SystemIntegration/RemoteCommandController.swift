import MediaPlayer

/// AirPods 捏合遥控映射：
/// - 单击（播放/暂停）：立即截句
/// 依赖当前音频会话处于激活状态。
final class RemoteCommandController {
    var onFlush: (() -> Void)?

    private let center = MPRemoteCommandCenter.shared()

    func activate() {
        center.playCommand.addTarget { [weak self] _ in
            self?.onFlush?()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.onFlush?()
            return .success
        }
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true

        // 最小化的 Now Playing 信息，遥控事件才会送达
        let info: [String: Any] = [
            MPMediaItemPropertyTitle: "离线实时翻译",
            MPMediaItemPropertyArtist: "本地识别 · 本地翻译",
            MPNowPlayingInfoPropertyIsLiveStream: true
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func deactivate() {
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
