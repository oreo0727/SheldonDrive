import Foundation

struct HermesChatClient {
    struct BootstrapResponse: Decodable {
        let projects: [HermesProject]
    }

    struct MissionCardsResponse: Decodable {
        let missionCards: [MissionCard]

        enum CodingKeys: String, CodingKey {
            case missionCards = "mission_cards"
        }
    }

    struct BriefingResponse: Decodable {
        let ok: Bool
        let briefing: String
        let card: MissionCard?
        let receipts: [MissionCard.Receipt]?
    }

    struct WatchResponse: Decodable {
        let ok: Bool
        let summary: String
        let alerts: [WatchAlert]
    }

    struct HandoffResponse: Decodable {
        struct Handoff: Decodable {
            let handoffId: String
            let target: String
            let instruction: String
            let status: String

            enum CodingKeys: String, CodingKey {
                case handoffId = "handoff_id"
                case target
                case instruction
                case status
            }
        }

        let ok: Bool
        let handoff: Handoff
    }

    struct ChatResponse: Decodable {
        let ok: Bool?
        let sessionId: String?
        let content: String?
        let fastPath: Bool?

        enum CodingKeys: String, CodingKey {
            case ok
            case sessionId = "session_id"
            case content
            case fastPath = "fast_path"
        }
    }

    struct OutgoingMessage: Encodable {
        let role: String
        let content: String
    }

    struct ChatRequest: Encodable {
        let profile: String
        let fast: Bool
        let projectId: String
        let sessionId: String
        let messages: [OutgoingMessage]

        enum CodingKeys: String, CodingKey {
            case profile
            case fast
            case projectId = "project_id"
            case sessionId = "session_id"
            case messages
        }
    }

    func send(
        endpoint: URL,
        sessionId: String,
        projectId: String,
        messages: [ChatMessage]
    ) async throws -> ChatResponse {
        let chatURL = endpoint.appending(path: "api/chat")
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 150
        let recentMessages = messages.suffix(12).map {
            OutgoingMessage(role: $0.role.rawValue, content: $0.content)
        }
        request.httpBody = try JSONEncoder().encode(
            ChatRequest(
                profile: "operator",
                fast: true,
                projectId: projectId,
                sessionId: sessionId,
                messages: recentMessages
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: body])
        }
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }

    func fetchProjects(endpoint: URL) async throws -> [HermesProject] {
        let bootstrapURL = endpoint.appending(path: "api/bootstrap")
        var request = URLRequest(url: bootstrapURL)
        request.timeoutInterval = 12

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(BootstrapResponse.self, from: data)
        return decoded.projects.sorted { left, right in
            if left.isActive != right.isActive { return left.isActive && !right.isActive }
            return (left.progressPercent ?? 0) > (right.progressPercent ?? 0)
        }
    }

    func fetchMissionCards(endpoint: URL) async throws -> [MissionCard] {
        let url = endpoint.appending(path: "api/mission-cards")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(MissionCardsResponse.self, from: data).missionCards
    }

    func requestBriefing(endpoint: URL, projectId: String, depth: String, mode: String) async throws -> BriefingResponse {
        var request = URLRequest(url: endpoint.appending(path: "api/briefing"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode([
            "project_id": projectId,
            "depth": depth,
            "mode": mode
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(BriefingResponse.self, from: data)
    }

    func fetchWatch(endpoint: URL) async throws -> WatchResponse {
        let url = endpoint.appending(path: "api/watch")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(WatchResponse.self, from: data)
    }

    func createHandoff(endpoint: URL, projectId: String, target: String, instruction: String) async throws -> HandoffResponse {
        var request = URLRequest(url: endpoint.appending(path: "api/handoff"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode([
            "project_id": projectId,
            "target": target,
            "instruction": instruction
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(HandoffResponse.self, from: data)
    }
}
