import AVFoundation

/// 已适配的耳机型号
enum HeadphoneModel: Equatable {
    case airPodsPro2OrLater   // AirPods Pro 2 / Pro 3（H2/H3）
    case airPods4             // AirPods 4 / 4 主动降噪版（H2）
    case airPods3             // AirPods 3（H1）
    case otherAirPods         // 其他 AirPods（可尝试，不保证）
    case otherBluetooth       // 第三方蓝牙耳机
    case builtIn              // 未连耳机，使用手机内置
}

struct HeadphoneStatus: Equatable {
    var model: HeadphoneModel
    var routeName: String
    var inputInHeadset: Bool   // 当前输入是否走耳机麦（HFP）
    var supported: Bool        // 是否属于官方适配范围

    static let builtIn = HeadphoneStatus(model: .builtIn, routeName: "iPhone", inputInHeadset: false, supported: true)
}

/// 耳机检测。
/// 注意：iOS 不向第三方 App 暴露精确的设备型号 ID，用户还可自定义耳机名称，
/// 因此这里基于 AVAudioSession 路由端口类型 + 端口名称做启发式判断，仅用于提示，不做强拦截。
final class HeadphoneDetector {
    static let shared = HeadphoneDetector()

    func current() -> HeadphoneStatus {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs

        guard let output = outputs.first else {
            return .builtIn
        }

        let name = output.portName
        let isBluetooth = output.portType == .bluetoothHFP || output.portType == .bluetoothA2DP

        if !isBluetooth {
            return HeadphoneStatus(model: .builtIn, routeName: name, inputInHeadset: false, supported: true)
        }

        // 输入是否也在耳机上（HFP 已建立）
        let inputInHeadset = session.currentRoute.inputs.contains {
            $0.portType == .bluetoothHFP
        }

        let model = inferModel(name: name)
        let supported: Bool
        switch model {
        case .airPodsPro2OrLater, .airPods4, .airPods3:
            supported = true
        default:
            supported = false
        }
        return HeadphoneStatus(model: model, routeName: name, inputInHeadset: inputInHeadset, supported: supported)
    }

    private func inferModel(name: String) -> HeadphoneModel {
        let n = name.lowercased()
        if n.contains("airpods pro") {
            // 用户可改名，无法精确区分 Pro 1/2/3；Pro 2 及以上为适配目标
            // 名称中显式带数字时采用，否则归为 Pro 2 及以上（主流在售型号）
            if n.contains("pro") {
                return .airPodsPro2OrLater
            }
            return .otherAirPods
        }
        if n.contains("airpods 4") || n.contains("airpods4") {
            return .airPods4
        }
        if n.contains("airpods 3") || n.contains("airpods3") {
            return .airPods3
        }
        if n.contains("airpods") {
            return .otherAirPods
        }
        return .otherBluetooth
    }

    var supportedModelNames: String {
        "AirPods Pro 2 及以上、AirPods 4、AirPods 3"
    }
}
