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
                        messages
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }
                controls
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.requestPermissions()
            viewModel.refreshProjects()
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
                    Text(viewModel.selectedProject?.displayTitle ?? "All Hermes projects")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                    Text(viewModel.selectedProject?.statusLabel ?? "General channel")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Color.white.opacity(0.52))
                }
                Spacer()
                if let percent = viewModel.selectedProject?.progressPercent {
                    Text("\(percent)%")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Color.orange)
                }
            }

            if let now = viewModel.selectedProject?.tracking?.now, !now.isEmpty {
                BriefLine(label: "Now", value: now)
            }
            if let next = viewModel.selectedProject?.tracking?.next, !next.isEmpty {
                BriefLine(label: "Next", value: next)
            }
            if let slice = viewModel.selectedProject?.focusedSlice, !slice.isEmpty {
                BriefLine(label: "Slice", value: slice)
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

    private var messages: some View {
        ScrollViewReader { proxy in
            LazyVStack(spacing: 12) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                        .id(message.id)
                }
            }
            .onChange(of: viewModel.messages.count) { _ in
                guard let last = viewModel.messages.last else { return }
                withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
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

            HStack(spacing: 12) {
                Button {
                    viewModel.toggleListening()
                } label: {
                    Label(viewModel.isListening ? "Listening" : "Talk", systemImage: viewModel.isListening ? "waveform.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                }
                .buttonStyle(PrimaryDriveButtonStyle(active: viewModel.isListening))

                Button {
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
        if viewModel.isListening || viewModel.isSending || viewModel.isLoadingProjects {
            return .orange
        }
        return .green
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
