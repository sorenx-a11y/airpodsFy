import Foundation
import Translation
import Observation
import SwiftUI

/// Apple 系统离线翻译引擎（iOS 18+ Translation 框架，免费、零包体）。
///
/// TranslationSession 不能直接初始化，必须由 SwiftUI 的
/// `.translationTask` modifier 注入。引擎内部维护请求队列，
/// 由 TranslationSessionBridge 视图注入的 session 逐条消费。
@Observable
final class AppleTranslationEngine: TranslationServicing {
    static let shared = AppleTranslationEngine()

    fileprivate final class PendingRequest {
        let text: String
        let continuation: CheckedContinuation<String, Error>
        init(text: String, continuation: CheckedContinuation<String, Error>) {
            self.text = text
            self.continuation = continuation
        }
    }

    /// 语言对配置（修改 source/target 后系统会自动重启 translationTask）
    @ObservationIgnored var configuration = TranslationSession.Configuration()

    /// 仅用于驱动视图观察
    var configVersion = 0

    private weak var session: TranslationSession?
    private var queue: [PendingRequest] = []
    private var signal: AsyncStream<Void>.Continuation?
    private var workerTask: Task<Void, Never>?
    private let lock = NSLock()

    func configure(sourceCode: String, targetCode: String) {
        let newSource = Locale.Language(identifier: sourceCode)
        let newTarget = Locale.Language(identifier: targetCode)
        guard configuration.source != newSource || configuration.target != newTarget else { return }
        configuration.source = newSource
        configuration.target = newTarget
        configVersion += 1
    }

    func prepare() async { /* 语言包在首次翻译时由系统引导下载 */ }

    func translate(_ text: String, from sourceCode: String, to targetCode: String) async throws -> String {
        configure(sourceCode: sourceCode, targetCode: targetCode)

        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            queue.append(PendingRequest(text: text, continuation: continuation))
            let signal = self.signal
            lock.unlock()
            signal?.yield(())
        }
    }

    // MARK: - Session 生命周期（由 Bridge 调用）

    fileprivate func attach(session: TranslationSession) {
        lock.lock()
        self.session = session

        if workerTask == nil {
            let (stream, continuation) = AsyncStream<Void>.makeStream()
            self.signal = continuation

            workerTask = Task.detached { [weak self] in
                for await _ in stream {
                    await self?.drain()
                }
            }
            // 绑定后先消费一次积压
            continuation.yield(())
        } else {
            self.signal?.yield(())
        }
        lock.unlock()
    }

    fileprivate func detach() {
        lock.lock()
        session = nil
        let pending = queue
        queue.removeAll()
        signal?.finish()
        signal = nil
        workerTask?.cancel()
        workerTask = nil
        lock.unlock()

        for request in pending {
            request.continuation.resume(throwing: TranslationError.engineNotReady)
        }
    }

    private func drain() async {
        while true {
            lock.lock()
            guard let session, !queue.isEmpty else {
                lock.unlock()
                return
            }
            let request = queue.removeFirst()
            lock.unlock()

            do {
                let response = try await session.translate(request.text)
                request.continuation.resume(returning: response.targetText)
            } catch {
                request.continuation.resume(throwing: error)
            }
        }
    }
}

/// 挂在根视图上，为 AppleTranslationEngine 注入 TranslationSession。
private struct TranslationSessionBridge: ViewModifier {
    private let engine = AppleTranslationEngine.shared

    func body(content: Content) -> some View {
        content
            // 引用 configVersion 建立观察依赖
            .onAppear { _ = engine.configVersion }
            .translationTask(engine.configuration) { session in
                engine.attach(session: session)
                // task 取消（语言对变化/视图消失）时解绑：
                // 用一个永不产生元素的 AsyncStream 挂起，取消时 finish 结束等待。
                // 切勿用 Task.sleep(.seconds(Int.max))：超大 Duration 在新系统运行时会断言崩溃。
                let (parkStream, parkContinuation) = AsyncStream<Void>.makeStream()
                await withTaskCancellationHandler {
                    for await _ in parkStream { }
                } onCancel: {
                    parkContinuation.finish()
                    engine.detach()
                }
            }
    }
}

extension View {
    func attachTranslationSession() -> some View {
        modifier(TranslationSessionBridge())
    }
}
