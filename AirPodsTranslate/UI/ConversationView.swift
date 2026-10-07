import SwiftUI

struct ConversationView: View {
    let mode: TranslateMode

    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var orchestrator: ConversationOrchestrator?
    @State private var remoteController: RemoteCommandController?

    var body: some View {
        ZStack {
            GlassBackdrop()
            VStack(spacing: 0) {
                header
                statusBar
                messageList
                controlBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await bootstrap()
        }
        .onDisappear {
            teardown()
        }
    }

    // MARK: - 生命周期

    private func bootstrap() async {
        let orch = ConversationOrchestrator(modelContext: modelContext)
        orchestrator = orch
        orch.start(mode: mode, settings: settings)

        let remote = RemoteCommandController()
        remote.onFlush = { orch.manualFlush() }
        remote.activate()
        remoteController = remote
    }

    private func teardown() {
        orchestrator?.stop()
        remoteController?.deactivate()
    }

    // MARK: - 顶部

    private var header: some View {
        HStack {
            Button {
                teardown()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassCircle()

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title).font(.headline)
                Text(orchestrator?.headphone.routeName ?? "音频路由")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var statusBar: some View {
        VStack(spacing: 8) {
            if let error = orchestrator?.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
                    .padding(.horizontal)
            }
            HStack(spacing: 14) {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .leading)
                WaveformView(
                    level: orchestrator?.level ?? 0,
                    active: orchestrator?.status == .listening || orchestrator?.status == .speaking,
                    color: .brand
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 6)
    }

    private var statusText: String {
        switch orchestrator?.status ?? .idle {
        case .idle:        "待机"
        case .preparing:   "准备中…"
        case .listening:   "聆听中"
        case .processing:  "翻译中…"
        case .speaking:    "朗读中"
        case .interrupted: "已打断"
        case .error(let m): m
        }
    }

    // MARK: - 字幕区

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if orchestrator?.messages.isEmpty ?? true {
                        ContentUnavailableView(
                            "开始说话即可",
                            systemImage: mode.iconName,
                            description: Text(mode.subtitle)
                        )
                        .padding(.top, 60)
                    }
                    ForEach(orchestrator?.messages ?? []) { message in
                        MessageBubbleView(
                            message: message,
                            isPlaying: orchestrator?.speakingMessageId == message.id,
                            onPlay: {
                                orchestrator?.replay(message, settings: settings)
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: orchestrator?.messages.count) { _, _ in
                if let last = orchestrator?.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - 控制条（仅 截句 + 结束；重播已放到每条气泡旁）

    private var controlBar: some View {
        ZStack {
            // 结束按钮：居中、放大
            Button {
                teardown()
                dismiss()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 26, weight: .bold))
                    .frame(width: 68, height: 68)
            }
            .buttonStyle(.plain)
            .glassCircle(Color.red)

            // 截句按钮：靠左
            HStack {
                Button {
                    orchestrator?.manualFlush()
                } label: {
                    Image(systemName: "scissors")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 58, height: 58)
                }
                .buttonStyle(.plain)
                .glassCircle(Color.brand)

                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }
}
