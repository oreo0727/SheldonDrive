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
    @Published var lastError = ""
    @Published var projects: [HermesProject] = []
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
        selectedProject?.displayTitle ?? "All Hermes projects"
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
                status = "Projects synced"
                lastError = ""
            } catch {
                lastError = "Could not load projects: \(error.localizedDescription)"
                status = "Project sync error"
            }
            isLoadingProjects = false
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
        status = "Contacting Sheldon"
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
            let message = "I could not reach Hermes: \(error.localizedDescription)"
            append(.assistant, message)
            voice.speak(message)
            status = "Connection error"
            lastError = error.localizedDescription
        }

        isSending = false
    }
}
