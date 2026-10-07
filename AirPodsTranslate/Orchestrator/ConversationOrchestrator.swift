import Foundation
import SwiftUI
import SwiftData
import Observation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var speaker: Speaker
    var source: String
    var translation: String
    var sourceLang: String
    var targetLang: String
    var date: Date
    var isProcessing: Bool

    init(speaker: Speaker,
         source: String,
         translation: String = "",
         sourceLang: String,
         targetLang: String,
         isProcessing: Bool = false) {
        self.id = UUID()
        self.speaker = speaker
        self.source = source
        self.translation = translation
        self.sourceLang = sourceLang
        self.targetLang = targetLang
        self.date = Date()
        self.isProcessing = isProcessing
    }
}

enum SessionStatus: Equatable {
    case idle
    case preparing
    case listening
    case processing
    case speaking
    case interrupted
    case error(String)
}

/// 会话总状态机：串联 采集 → VAD → ASR → 清洗/术语 → MT → TTS / 字幕 / 落库。
@MainActor
@Observable
final class ConversationOrchestrator {
    var mode: TranslateMode = .conversation
    var status: SessionStatus = .idle
    var messages: [ChatMessage] = []
    var level: Float = 0
    var headphone: HeadphoneStatus = .builtIn
    var lastError: String?

    /// 当前正在朗读的消息 id（气泡旁播放按钮高亮用）
    var speakingMessageId: UUID?

    private let audioSession = AudioSessionManager.shared
    private let capture = AudioCaptureEngine()
    private var asr: SpeechRecognizing?
    private var translator: TranslationServicing?
    private let speaker = SpeechSpeaker.shared

    private weak var modelContext: ModelContext?
    private var conversation: Conversation?
    private var settings: SettingsStore?

    private var speakTask: Task<Void, Never>?
    private var isHandlingUtterance = false

    var isRunning: Bool { status != .idle }

    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
        audioSession.onRouteChange = { [weak self] reason in
            Task { @MainActor in self?.handleRouteChange(reason) }
        }
        audioSession.onInterruption = { [weak self] began in
            Task { @MainActor in began ? self?.pauseForInterruption() : self?.resumeAfterInterruption() }
        }
    }

    // MARK: - 启停

    func start(mode: TranslateMode, settings: SettingsStore) {
        self.mode = mode
        self.settings = settings
        status = .preparing
        messages.removeAll()
        speakingMessageId = nil
        lastError = nil
        if settings.autoSaveHistory, let modelContext {
            let conv = Conversation(
                myLanguageCode: settings.myLanguageCode,
                theirLanguageCode: settings.theirLanguageCode
            )
            modelContext.insert(conv)
            conversation = conv
        }

        Task { @MainActor in
            let granted = await audioSession.requestPermission()
            guard granted else {
                status = .error("需要麦克风权限才能进行离线翻译")
                return
            }

            // 引擎准备
            let asrEngine = ASRFactory.make(settings.asrEngine)
            self.asr = asrEngine
            await asrEngine.prepare()
            let mt = TranslationFactory.make(settings.mtEngine)
            self.translator = mt
            await mt.prepare()

            speaker.rate = settings.ttsRate
            speaker.volume = Float(settings.translatedVolume)
            capture.configureVAD(endpointSilence: settings.endpointSilence)

            // 会话与回调
            configureAudio(mode: mode, settings: settings)
            installAudioCallbacks()
            headphone = HeadphoneDetector.shared.current()

            do {
                try capture.start()
                status = .listening
            } catch {
                status = .error("音频启动失败：\(error.localizedDescription)")
            }
        }
    }

    func stop() {
        speakTask?.cancel()
        speaker.stopSpeaking()
        speakingMessageId = nil
        capture.stop()
        audioSession.deactivate()
        status = .idle
        // 没有产生任何消息则删掉占位会话
        if messages.isEmpty, let conversation, let modelContext {
            modelContext.delete(conversation)
            self.conversation = nil
        }
        try? modelContext?.save()
    }

    // MARK: - 手动控制（按钮 / AirPods 捏合）

    /// 立即截句
    func manualFlush() {
        capture.flush()
    }

    /// 重播指定消息的译文（点气泡旁播放按钮）
    func replay(_ message: ChatMessage, settings: SettingsStore) {
        guard !message.translation.isEmpty else { return }
        speakTranslation(for: message, settings: settings)
    }

    // MARK: - 配置音频

    private func configureAudio(mode: TranslateMode, settings: SettingsStore) {
        switch mode {
        case .conversation:
            try? audioSession.configure(strategy: settings.routeStrategy)
        case .listening:
            try? audioSession.configure(strategy: .headsetMic)
        }
    }

    // MARK: - 采集回调

    private func installAudioCallbacks() {
        capture.onLevel = { [weak self] value in
            Task { @MainActor in self?.level = value }
        }
        capture.onSpeechStart = { [weak self] in
            Task { @MainActor in self?.handleSpeechStart() }
        }
        capture.onUtterance = { [weak self] samples in
            Task { @MainActor in self?.handleUtteranceReady(samples) }
        }
    }

    private func handleSpeechStart() {
        guard isRunning else { return }
        // 人声优先：立即打断 TTS
        if speaker.isSpeaking {
            speaker.stopSpeaking()
            speakTask?.cancel()
            speakingMessageId = nil
            status = .interrupted
        }
    }

    private func handleUtteranceReady(_ samples: [Float]) {
        guard isRunning, !isHandlingUtterance else { return }
        Task { await handleUtterance(samples: samples) }
    }

    // MARK: - 一句完整处理

    private func handleUtterance(samples: [Float]) async {
        guard let settings, let asr, let translator else { return }
        isHandlingUtterance = true
        defer { isHandlingUtterance = false }

        status = .processing

        // 1. ASR（聆听模式锁定对方语种提示，提高识别准确率）
        let hint: String? = settings.lockLanguage && mode == .listening ? settings.theirLanguageCode : nil

        let asrResult: ASRResult
        do {
            asrResult = try await asr.transcribe(samples: samples, hintLanguageCode: hint)
        } catch {
            lastError = error.localizedDescription
            status = .listening
            return
        }

        let sourceText = TextCleaner.clean(asrResult.text)
        guard !sourceText.isEmpty else {
            status = .listening
            return
        }

        // 2. 判语种、归属说话人
        let detected = asrResult.detectedLanguageCode ?? LanguageDetector.detect(sourceText)
        let speakerSide = decideSpeaker(detected: detected, settings: settings)
        let sourceLang = speakerSide == .me ? settings.myLanguageCode : settings.theirLanguageCode
        let targetLang = speakerSide == .me ? settings.theirLanguageCode : settings.myLanguageCode

        // 3. 翻译
        let translated: String
        do {
            let raw = try await translator.translate(sourceText, from: sourceLang, to: targetLang)
            let entries = fetchGlossary(source: sourceLang, target: targetLang)
            translated = GlossaryApplier.apply(translated: raw, entries: entries)
        } catch {
            lastError = error.localizedDescription
            // 翻译失败也先显示原文
            appendMessage(speakerSide, sourceText, sourceLang, targetLang, translated: sourceText)
            status = .listening
            return
        }

        // 4. 上屏 + 落库 + 朗读
        let message = appendMessage(speakerSide, sourceText, sourceLang, targetLang, translated: translated)
        speakTranslation(for: message, settings: settings)
    }

    private func decideSpeaker(detected: String?, settings: SettingsStore) -> Speaker {
        switch mode {
        case .listening:
            return .them
        case .conversation:
            if let detected, LanguageDetector.isSameLanguage(detected, settings.myLanguageCode) {
                return .me
            }
            return .them
        }
    }

    // MARK: - TTS

    private func speakTranslation(for message: ChatMessage, settings: SettingsStore) {
        guard settings.ttsEnabled, !message.translation.isEmpty else {
            status = .listening
            return
        }

        speakTask?.cancel()
        speakTask = Task { @MainActor in
            status = .speaking
            speakingMessageId = message.id

            _ = await speaker.speak(
                message.translation,
                languageCode: message.targetLang,
                volume: Float(settings.translatedVolume),
                rate: settings.ttsRate
            )

            if !Task.isCancelled {
                speakingMessageId = nil
                status = .listening
            }
        }
    }

    // MARK: - 持久化

    @discardableResult
    private func appendMessage(_ speakerSide: Speaker,
                               _ source: String,
                               _ sourceLang: String,
                               _ targetLang: String,
                               translated: String) -> ChatMessage {
        let message = ChatMessage(
            speaker: speakerSide,
            source: source,
            translation: translated,
            sourceLang: sourceLang,
            targetLang: targetLang
        )
        messages.append(message)
        persist(message)
        return message
    }

    private func persist(_ message: ChatMessage) {
        guard let modelContext, settings?.autoSaveHistory == true else { return }
        guard let conversation else { return }
        let entity = MessageEntity(
            speaker: message.speaker,
            sourceText: message.source,
            translatedText: message.translation,
            sourceLanguageCode: message.sourceLang,
            targetLanguageCode: message.targetLang
        )
        entity.conversation = conversation
        modelContext.insert(entity)
        conversation.updatedAt = Date()
        try? modelContext.save()
    }

    private func fetchGlossary(source: String, target: String) -> [GlossaryEntry] {
        guard let modelContext else { return [] }
        let key = "\(source) -> \(target)"
        let descriptor = FetchDescriptor<GlossaryEntry>(
            predicate: #Predicate { $0.languagePairKey == key }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - 中断 / 路由变化

    private func handleRouteChange(_ reason: AVAudioSession.RouteChangeReason) {
        headphone = HeadphoneDetector.shared.current()
        // AirPods 摘下：对话模式自动降级为外放策略，避免会话中断
        if reason == .oldDeviceUnavailable, mode == .conversation {
            capture.stop()
            try? audioSession.configure(strategy: .speaker)
            try? capture.start()
        }
    }

    private func pauseForInterruption() {
        guard isRunning else { return }
        speaker.stopSpeaking()
        speakingMessageId = nil
        capture.stop()
        status = .interrupted
    }

    private func resumeAfterInterruption() {
        guard isRunning else { return }
        try? audioSession.setActive(true)
        try? capture.start()
        status = .listening
    }
}
