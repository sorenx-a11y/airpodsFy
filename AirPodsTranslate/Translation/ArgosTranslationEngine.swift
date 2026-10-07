import Foundation

/// Argos CoreML 离线翻译（第二引擎，V2.0 交付）。
///
/// 技术路线（预研）：
/// 1. Argos OpenNMT 双语模型（encoder/decoder）导出 Torch → ONNX → Core ML；
/// 2. SentencePiece 分词以 BPE 词表资源内置；
/// 3. 用 Core ML MLModel 自回归解码，或一次性 encoder + 循环 decoder；
/// 4. 实现 TranslationServicing 后在此接入，设置页开放切换。
///
/// V1.0/V1.5 统一走 Apple Translation 框架。
final class ArgosTranslationEngine: TranslationServicing {
    func prepare() async {
        // TODO V2.0：加载 .mlpackage 双语模型
    }

    func translate(_ text: String, from sourceCode: String, to targetCode: String) async throws -> String {
        throw TranslationError.argosNotInstalled
    }
}
