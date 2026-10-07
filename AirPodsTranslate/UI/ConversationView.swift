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
                Text(mode.title).font(.system(size: 16.5, weight: .bold))
                HStack(spacing: 4) {
                    Image(systemName: "headphones")
                        .font(.system(size: 10))
                    Text(subtitleRoute)
                        .font(.system(size: 10.5))
                }
                .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var subtitleRoute: String {
        let route = orchestrator?.headphone.routeName ?? "音频路由"
        let strategy = mode == .listening ? "耳机麦 HFP" : settings.routeStrategy.title
        return "\(route) · \(strategy)"
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
        case .processing:  "识别翻译中"
        case .speaking:    "朗读中"
        case .interrupted: "已打断"
        case .error(let m): m
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: mode == .listening ? "ear.fill" : "bubble.left.and.bubble.right.fill")
                .font(.system(size: 46))
                .foregroundStyle(.tertiary)
            Text(mode == .listening ? "把手机放兜里，戴着耳机听即可" : "戴上 AirPods，开始说话即可")
                .font(.system(size: 16, weight: .semibold))
            Text(mode == .listening
                 ? "对方说完后译文自动在耳机朗读"
                 : "系统自动分栏，译文朗读并显示双语字幕")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - 字幕区

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if orchestrator?.messages.isEmpty ?? true {
                        emptyState
                            .padding(.top, 80)
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
