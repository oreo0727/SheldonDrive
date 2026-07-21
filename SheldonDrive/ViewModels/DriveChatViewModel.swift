import Foundation

@MainActor
final class DriveChatViewModel: ObservableObject {
    @Published var endpointText: String {
        didSet { UserDefaults.standard.set(endpointText, forKey: "hermesEndpoint") }
    }
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Sheldon Drive is online. Tap the mic, ask for a project status, and keep your eyes on the road.")
    ]
    @Published var transcript = ""
    @Published var status = "Ready"
    @Published var isListening = false
    @Published var isSending = false
    @Published var isLoadingProjects = false
    @Published var isMissionModeBusy = false
    @Published var isCarMode = false
    @Published var lastError = ""
    @Published var projects: [HermesProject] = []
    @Published var missionCards: [MissionCard] = []
    @Published var watchAlerts: [WatchAlert] = []
    @Published var watchSummary = "Watch mode is idle."
    @Published var selectedProjectId: String {
        didSet { UserDefaults.standard.set(selectedProjectId, forKey: "selectedHermesProjectId") }
    }

    private let chatClient = HermesChatClient()
    private let speech = SpeechController()
    private let voice = VoicePlayback()
    private var sessionId = ""

    init() {
        endpointText = UserDefaults.standard.string(forKey: "hermesEndpoint") ?? "http://100.71.8.121:8799"
        selectedProjectId = UserDefaults.standard.string(forKey: "selectedHermesProjectId") ?? ""
    }

    var endpointURL: URL? {
        URL(string: endpointText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var selectedProject: HermesProject? {
        projects.first { $0.projectId == selectedProjectId } ?? projects.first(where: \.isActive) ?? projects.first
    }

    var selectedProjectTitle: String {
        selectedMissionCard?.title ?? selectedProject?.displayTitle ?? "All Hermes projects"
    }

    var selectedMissionCard: MissionCard? {
        missionCards.first { $0.projectId == selectedProjectId }
            ?? missionCards.first(where: \.active)
            ?? missionCards.first
    }

    func requestPermissions() {
        Task {
            let allowed = await speech.requestPermissions()
            if allowed {
                status = "Ready"
            } else {
                status = "Permission needed"
                lastError = "Enable microphone and speech recognition in Settings."
            }
        }
    }

    func refreshProjects() {
        guard let endpointURL else {
            lastError = "Enter a valid Hermes URL."
            return
        }
        isLoadingProjects = true
        Task {
            do {
                let fetched = try await chatClient.fetchProjects(endpoint: endpointURL)
                projects = fetched
                if selectedProjectId.isEmpty || !fetched.contains(where: { $0.projectId == selectedProjectId }) {
                    selectedProjectId = fetched.first(where: \.isActive)?.projectId ?? fetched.first?.projectId ?? ""
                }
                await refreshMissionCards(endpoint: endpointURL)
                await refreshWatch(endpoint: endpointURL)
                status = "Projects synced"
                lastError = ""
            } catch {
                lastError = "Could not load projects: \(error.localizedDescription)"
                status = "Project sync error"
            }
            isLoadingProjects = false
        }
    }

    private func refreshMissionCards(endpoint: URL) async {
        do {
            missionCards = try await chatClient.fetchMissionCards(endpoint: endpoint)
        } catch {
            // Older Hermes servers may not expose mission cards yet; project mode still works.
        }
    }

    private func refreshWatch(endpoint: URL) async {
        do {
            let response = try await chatClient.fetchWatch(endpoint: endpoint)
            watchSummary = response.summary
            watchAlerts = response.alerts
        } catch {
            watchSummary = "Watch digest unavailable."
            watchAlerts = []
        }
    }

    func selectProject(_ project: HermesProject) {
        selectedProjectId = project.projectId
        sessionId = ""
        messages = [
            ChatMessage(
                role: .assistant,
                content: "Project channel set to \(project.displayTitle). Ask me what is blocked, what changed, or what the next proof step should be."
            )
        ]
        status = "Project selected"
    }

    func requestBriefing(depth: String = "short") {
        guard let endpointURL else {
            lastError = "Enter a valid Hermes URL."
            return
        }
        let projectId = selectedMissionCard?.projectId ?? selectedProject?.projectId ?? selectedProjectId
        guard !projectId.isEmpty else {
            lastError = "Select a project first."
            return
        }
        isMissionModeBusy = true
        status = isCarMode ? "Car briefing" : "Briefing"
        Task {
            do {
                let response = try await chatClient.requestBriefing(
                    endpoint: endpointURL,
                    projectId: projectId,
                    depth: depth,
                    mode: isCarMode ? "car" : "normal"
                )
                if let card = response.card {
                    upsertMissionCard(card)
                }
                append(.assistant, response.briefing)
                voice.speak(response.briefing)
                status = "Briefed"
                lastError = ""
            } catch {
                lastError = "Briefing failed: \(error.localizedDescription)"
                status = "Briefing error"
            }
            isMissionModeBusy = false
        }
    }

    func requestWatchDigest() {
        guard let endpointURL else {
            lastError = "Enter a valid Hermes URL."
            return
        }
        isMissionModeBusy = true
        status = "Checking watch"
        Task {
            do {
                let response = try await chatClient.fetchWatch(endpoint: endpointURL)
                watchSummary = response.summary
                watchAlerts = response.alerts
                let lines = [response.summary] + response.alerts.prefix(3).map { "\($0.title): \($0.message)" }
                let digest = lines.joined(separator: "\n")
                append(.assistant, digest)
                voice.speak(response.summary)
                status = "Watch updated"
                lastError = ""
            } catch {
                lastError = "Watch failed: \(error.localizedDescription)"
                status = "Watch error"
            }
            isMissionModeBusy = false
        }
    }

    func createHandoff(target: String) {
        guard let endpointURL else {
            lastError = "Enter a valid Hermes URL."
            return
        }
        let projectId = selectedMissionCard?.projectId ?? selectedProject?.projectId ?? selectedProjectId
        guard !projectId.isEmpty else {
            lastError = "Select a project first."
            return
        }
        let title = selectedProjectTitle
        let instruction = "Review \(title) and report the next useful proof step with receipts."
        isMissionModeBusy = true
        status = "Handing off"
        Task {
            do {
                let response = try await chatClient.createHandoff(
                    endpoint: endpointURL,
                    projectId: projectId,
                    target: target,
                    instruction: instruction
                )
                let reply = "Queued handoff to \(response.handoff.target): \(response.handoff.instruction)"
                append(.assistant, reply)
                voice.speak("Queued handoff to \(response.handoff.target).")
                status = "Handoff queued"
                lastError = ""
            } catch {
                lastError = "Handoff failed: \(error.localizedDescription)"
                status = "Handoff error"
            }
            isMissionModeBusy = false
        }
    }

    private func upsertMissionCard(_ card: MissionCard) {
        if let index = missionCards.firstIndex(where: { $0.projectId == card.projectId }) {
            missionCards[index] = card
        } else {
            missionCards.insert(card, at: 0)
        }
    }

    func toggleListening() {
        if isListening {
            speech.stop()
            isListening = false
            status = "Ready"
            return
        }

        lastError = ""
        transcript = ""
        status = "Listening"
        isListening = true
        speech.start(
            onPartial: { [weak self] partial in
                Task { @MainActor in
                    self?.transcript = partial
                }
            },
            onFinal: { [weak self] final in
                Task { @MainActor in
                    self?.isListening = false
                    self?.status = "Sending"
                    await self?.send(final, speakReply: true)
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.isListening = false
                    self?.status = "Voice error"
                    self?.lastError = error.localizedDescription
                }
            }
        )
    }

    func sendTypedMessage() {
        let outgoing = transcript
        transcript = ""
        Task {
            await send(outgoing, speakReply: true)
        }
    }

    func repeatLastSheldonReply() {
        guard let reply = messages.last(where: { $0.role == .assistant }) else { return }
        voice.speak(reply.content)
    }

    func stopSpeaking() {
        voice.stop()
    }

    private func append(_ role: ChatMessage.Role, _ content: String) {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        messages.append(ChatMessage(role: role, content: cleaned))
    }

    func send(_ text: String, speakReply: Bool) async {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            status = "Ready"
            return
        }
        guard let endpointURL else {
            status = "Endpoint error"
            lastError = "Enter a valid Hermes URL."
            return
        }

        append(.user, cleaned)
        isSending = true
        status = "Sheldon is thinking"
        lastError = ""

        do {
            let projectId = selectedProject?.projectId ?? selectedProjectId
            let response = try await chatClient.send(endpoint: endpointURL, sessionId: sessionId, projectId: projectId, messages: messages)
            if let newSession = response.sessionId, !newSession.isEmpty {
                sessionId = newSession
            }
            let reply = response.content?.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalReply = reply?.isEmpty == false ? reply! : "I received the message, but no response text came back."
            append(.assistant, finalReply)
            if speakReply {
                voice.speak(finalReply)
            }
            status = response.fastPath == true ? "Fast route" : "Ready"
        } catch {
            let message = "I could not reach Hermes yet: \(error.localizedDescription)"
            append(.assistant, message)
            voice.speak(message)
            status = "Connection error"
            lastError = error.localizedDescription
        }

        isSending = false
    }
}
