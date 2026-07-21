import SwiftUI

struct DriveChatView: View {
    @StateObject private var viewModel = DriveChatViewModel()
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero
                        projectSelector
                        activeProjectBrief
                        missionActions
                        watchPanel
                        handoffPanel
                        improvementPanel
                        messages
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    textFieldFocused = false
                }
                controls
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.requestPermissions()
            viewModel.refreshProjects()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    textFieldFocused = false
                }
                .font(.body.weight(.bold))
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.04, blue: 0.12),
                Color(red: 0.09, green: 0.12, blue: 0.27),
                Color(red: 0.03, green: 0.07, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.orange.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 34)
                .offset(x: 110, y: -112)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.blue.opacity(0.23))
                .frame(width: 260, height: 260)
                .blur(radius: 32)
                .offset(x: -120, y: 130)
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            Image("SheldonAvatar")
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.orange.opacity(0.72), lineWidth: 2))
                .shadow(color: Color.orange.opacity(0.25), radius: 18, y: 8)

            VStack(alignment: .leading, spacing: 5) {
                Text("SHELDON DRIVE")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.white.opacity(0.48))
                    .tracking(1.8)
                Text("Project-aware Hermes chat")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(viewModel.selectedProjectTitle)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.orange.opacity(0.95))
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var projectSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Project Channel")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.white.opacity(0.52))
                    .tracking(1.2)
                Spacer()
                Button {
                    viewModel.refreshProjects()
                } label: {
                    Label(viewModel.isLoadingProjects ? "Syncing" : "Sync", systemImage: "arrow.clockwise")
                        .labelStyle(.titleAndIcon)
                }
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.orange)
            }

            if viewModel.projects.isEmpty {
                Text("No projects loaded yet. Check the endpoint or tap Sync.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.projects) { project in
                            ProjectChip(
                                project: project,
                                selected: project.projectId == viewModel.selectedProject?.projectId
                            ) {
                                viewModel.selectProject(project)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var activeProjectBrief: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedMissionCard?.title ?? viewModel.selectedProject?.displayTitle ?? "All Hermes projects")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                    Text(viewModel.selectedMissionCard?.status ?? viewModel.selectedProject?.statusLabel ?? "General channel")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Color.white.opacity(0.52))
                }
                Spacer()
                if let percent = viewModel.selectedMissionCard?.progressPercent ?? viewModel.selectedProject?.progressPercent {
                    Text("\(percent)%")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Color.orange)
                }
            }

            if let objective = viewModel.selectedMissionCard?.objective, !objective.isEmpty {
                BriefLine(label: "Mission", value: objective)
            }
            if let now = viewModel.selectedMissionCard?.now ?? viewModel.selectedProject?.tracking?.now, !now.isEmpty {
                BriefLine(label: "Now", value: now)
            }
            if let next = viewModel.selectedMissionCard?.next ?? viewModel.selectedProject?.tracking?.next, !next.isEmpty {
                BriefLine(label: "Next", value: next)
            }
            if let blocker = viewModel.selectedMissionCard?.blockedSummary, !blocker.isEmpty {
                BriefLine(label: "Blocked", value: blocker)
            }

            if let receipts = viewModel.selectedMissionCard?.receipts, !receipts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RECEIPTS")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.orange.opacity(0.80))
                    ForEach(receipts.prefix(3)) { receipt in
                        Text(receipt.path)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .foregroundStyle(Color.white.opacity(0.68))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.22), in: Capsule())
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Hermes endpoint")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Color.white.opacity(0.45))
                TextField("Hermes URL", text: $viewModel.endpointText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .focused($textFieldFocused)
                    .font(.footnote.monospaced())
                    .padding(10)
                    .foregroundStyle(.white)
                    .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.09))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.12)))
        )
    }

    private var missionActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Mission Mode", systemImage: "sparkles")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(1.1)
                Spacer()
                Toggle("Car", isOn: $viewModel.isCarMode)
                    .labelsHidden()
                    .tint(.orange)
                Text("Car")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(viewModel.isCarMode ? Color.orange : Color.white.opacity(0.52))
            }

            HStack(spacing: 10) {
                MissionButton(title: "Brief Me", icon: "text.bubble.fill", prominent: true) {
                    textFieldFocused = false
                    viewModel.requestBriefing(depth: viewModel.isCarMode ? "short" : "medium")
                }
                MissionButton(title: "Blocks", icon: "exclamationmark.triangle.fill", prominent: false) {
                    textFieldFocused = false
                    viewModel.requestBriefing(depth: "deep")
                }
                MissionButton(title: "Watch", icon: "dot.radiowaves.left.and.right", prominent: false) {
                    textFieldFocused = false
                    viewModel.requestWatchDigest()
                }
            }

            HStack(spacing: 8) {
                HandoffButton(name: "Penny") { viewModel.createHandoff(target: "penny") }
                HandoffButton(name: "Raj") { viewModel.createHandoff(target: "raj") }
                HandoffButton(name: "Leonard") { viewModel.createHandoff(target: "leonard") }
            }
            .disabled(viewModel.isMissionModeBusy)
            .opacity(viewModel.isMissionModeBusy ? 0.55 : 1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.10)))
        )
    }

    private var watchPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("WATCH")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color.white.opacity(0.46))
                    .tracking(1.4)
                Spacer()
                Text(viewModel.watchSummary)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.orange.opacity(0.85))
                    .lineLimit(1)
            }
            ForEach(viewModel.watchAlerts.prefix(3)) { alert in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(alert.tone == "blocked" ? Color.red : Color.green)
                        .frame(width: 7, height: 7)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(alert.message)
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.64))
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var handoffPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AGENT HANDOFFS")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color.white.opacity(0.46))
                    .tracking(1.4)
                Spacer()
                Text("\(viewModel.handoffs.prefix(4).count) visible")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.54))
            }

            if viewModel.handoffs.isEmpty {
                Text("No open handoffs yet. Ask Penny, Raj, or Leonard and Sheldon will keep the receipt.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
            } else {
                ForEach(viewModel.handoffs.prefix(4)) { handoff in
                    HandoffRow(handoff: handoff)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var improvementPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SELF-IMPROVEMENT")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.white.opacity(0.46))
                        .tracking(1.4)
                    Text(viewModel.selfImprovementSummary)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: max(0.02, min(viewModel.missionBrainScore, 1)))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(viewModel.missionBrainScore * 100))")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                }
                .frame(width: 52, height: 52)
            }

            if let proposal = viewModel.latestImprovementProposal {
                Text(proposal.nextExperiment?.operatorPrompt ?? proposal.hypothesis)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                Text((proposal.status ?? "proposed").uppercased())
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.14), in: Capsule())
            } else {
                Text(viewModel.selfImprovementNextMove)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
            }

            if let weak = viewModel.weakBrainCards.first {
                BriefLine(label: "Weakest Signal", value: "\(weak.title): \(weak.recommendation)")
            }

            HStack(spacing: 10) {
                MissionButton(title: "Improve", icon: "brain.head.profile", prominent: true) {
                    textFieldFocused = false
                    viewModel.proposeSelfImprovement()
                }
                MissionButton(title: "Accept", icon: "checkmark.seal.fill", prominent: false) {
                    textFieldFocused = false
                    viewModel.acceptLatestImprovement()
                }
            }
            .disabled(viewModel.isMissionModeBusy)
            .opacity(viewModel.isMissionModeBusy ? 0.55 : 1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.16), Color.blue.opacity(0.12), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.orange.opacity(0.18)))
        )
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            LazyVStack(spacing: 12) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                        .id(message.id)
                }
                if viewModel.isSending {
                    ThinkingBubble()
                        .id("thinking")
                }
            }
            .onChange(of: viewModel.messages.count + (viewModel.isSending ? 1 : 0)) { _ in
                let target: AnyHashable
                if viewModel.isSending {
                    target = "thinking"
                } else if let last = viewModel.messages.last {
                    target = last.id
                } else {
                    return
                }
                withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                    proxy.scrollTo(target, anchor: .bottom)
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if !viewModel.lastError.isEmpty {
                Text(viewModel.lastError)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.red.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TextEditor(text: $viewModel.transcript)
                .frame(minHeight: 54, maxHeight: 96)
                .scrollContentBackground(.hidden)
                .padding(10)
                .foregroundStyle(.white)
                .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.10)))
                .focused($textFieldFocused)
                .submitLabel(.send)

            HStack(spacing: 12) {
                Button {
                    textFieldFocused = false
                    viewModel.toggleListening()
                } label: {
                    Label(viewModel.isListening ? "Listening" : "Talk", systemImage: viewModel.isListening ? "waveform.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                }
                .buttonStyle(PrimaryDriveButtonStyle(active: viewModel.isListening))

                Button {
                    textFieldFocused = false
                    viewModel.sendTypedMessage()
                } label: {
                    Image(systemName: viewModel.isSending ? "hourglass" : "paperplane.fill")
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 58, height: 58)
                }
                .buttonStyle(SecondaryDriveButtonStyle())
                .disabled(viewModel.isSending)
            }

            HStack {
                Text(viewModel.status)
                    .font(.footnote.weight(.heavy))
                    .foregroundStyle(statusColor)
                Spacer()
                Button("Repeat") { viewModel.repeatLastSheldonReply() }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.orange)
                Button("Quiet") { viewModel.stopSpeaking() }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.64))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }

    private var statusColor: Color {
        if viewModel.status.localizedCaseInsensitiveContains("error") {
            return .red
        }
        if viewModel.isListening || viewModel.isSending || viewModel.isLoadingProjects || viewModel.isMissionModeBusy {
            return .orange
        }
        return .green
    }
}

struct ThinkingBubble: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sheldon")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.orange)
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.orange.opacity(0.92))
                            .frame(width: 8, height: 8)
                            .scaleEffect(phase == index ? 1.35 : 0.72)
                            .opacity(phase == index ? 1 : 0.45)
                            .animation(.easeInOut(duration: 0.34), value: phase)
                    }
                    Text("thinking")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.64))
                        .padding(.leading, 4)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.orange.opacity(0.18)))
            )
            Spacer(minLength: 42)
        }
        .padding(.horizontal, 2)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(360))
                phase = (phase + 1) % 3
            }
        }
    }
}

struct ProjectChip: View {
    let project: HermesProject
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(project.isActive ? Color.green : Color.orange.opacity(0.70))
                        .frame(width: 8, height: 8)
                    Text(project.statusLabel.uppercased())
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(1)
                }
                Text(project.displayTitle)
                    .font(.footnote.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(width: 176, alignment: .leading)
            }
            .padding(13)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? Color.orange.opacity(0.23) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? Color.orange.opacity(0.74) : Color.white.opacity(0.11), lineWidth: selected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct BriefLine: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.orange.opacity(0.80))
            Text(value)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MissionButton: View {
    let title: String
    let icon: String
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .black))
                Text(title)
                    .font(.caption.weight(.black))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(prominent ? Color.black : Color.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(prominent ? Color.orange : Color.white.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
    }
}

struct HandoffButton: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Ask \(name)")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.white.opacity(0.86))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct HandoffRow: View {
    let handoff: MissionHandoff

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(handoff.target.prefix(1).uppercased())
                .font(.caption.weight(.black))
                .foregroundStyle(Color.black)
                .frame(width: 24, height: 24)
                .background(statusColor, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(handoff.target.capitalized)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                    Text(handoff.status.uppercased())
                        .font(.caption2.weight(.black))
                        .foregroundStyle(statusColor)
                }
                Text(handoff.projectTitle ?? handoff.projectId)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Color.white.opacity(0.46))
                    .lineLimit(1)
                Text(handoff.lastNote ?? handoff.instruction)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.64))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusColor: Color {
        switch handoff.status.lowercased() {
        case "blocked":
            return .red
        case "done":
            return .green
        case "working":
            return .orange
        default:
            return Color.blue.opacity(0.95)
        }
    }
}

struct PrimaryDriveButtonStyle: ButtonStyle {
    let active: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(active ? Color.black : Color.white)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(active ? Color.orange : Color.blue.opacity(configuration.isPressed ? 0.70 : 0.92))
            )
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.18)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct SecondaryDriveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.18 : 0.10))
            )
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.12)))
    }
}

#Preview {
    DriveChatView()
}
