import Foundation

struct MissionCard: Identifiable, Decodable, Equatable {
    struct Receipt: Identifiable, Decodable, Equatable {
        let label: String
        let path: String
        let updatedAt: String?

        var id: String { "\(label):\(path)" }

        enum CodingKeys: String, CodingKey {
            case label
            case path
            case updatedAt = "updated_at"
        }
    }

    let projectId: String
    let title: String
    let status: String?
    let objective: String
    let now: String
    let next: String
    let blocked: [String]
    let proof: [String]
    let owner: String
    let progressPercent: Int
    let active: Bool
    let loopRisk: String?
    let receipts: [Receipt]

    var id: String { projectId }

    var blockedSummary: String {
        blocked.first ?? "No blocker recorded."
    }

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case title
        case status
        case objective
        case now
        case next
        case blocked
        case proof
        case owner
        case progressPercent = "progress_percent"
        case active
        case loopRisk = "loop_risk"
        case receipts
    }
}

struct WatchAlert: Identifiable, Decodable, Equatable {
    let tone: String
    let projectId: String
    let title: String
    let message: String

    var id: String { "\(tone):\(projectId):\(message)" }

    enum CodingKeys: String, CodingKey {
        case tone
        case projectId = "project_id"
        case title
        case message
    }
}

struct MissionHandoff: Identifiable, Decodable, Equatable {
    struct Event: Identifiable, Decodable, Equatable {
        let at: String
        let status: String
        let note: String?

        var id: String { "\(at):\(status):\(note ?? "")" }
    }

    let handoffId: String
    let projectId: String
    let projectTitle: String?
    let target: String
    let instruction: String
    let status: String
    let createdAt: String?
    let updatedAt: String?
    let lastNote: String?
    let events: [Event]?

    var id: String { handoffId }

    enum CodingKeys: String, CodingKey {
        case handoffId = "handoff_id"
        case projectId = "project_id"
        case projectTitle = "project_title"
        case target
        case instruction
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastNote = "last_note"
        case events
    }
}

struct MissionBrainCardScore: Identifiable, Decodable, Equatable {
    let projectId: String
    let title: String
    let score: Double
    let missing: [String]
    let recommendation: String

    var id: String { projectId }

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case title
        case score
        case missing
        case recommendation
    }
}

struct SelfImprovementProposal: Identifiable, Decodable, Equatable {
    struct NextExperiment: Decodable, Equatable {
        let name: String?
        let operatorPrompt: String?
        let successSignal: String?
        let rollback: String?

        enum CodingKeys: String, CodingKey {
            case name
            case operatorPrompt = "operator_prompt"
            case successSignal = "success_signal"
            case rollback
        }
    }

    let proposalId: String
    let status: String?
    let focus: String
    let hypothesis: String
    let experiments: [String]
    let weakestCards: [MissionBrainCardScore]?
    let nextExperiment: NextExperiment?
    let guardrails: [String]
    let lastNote: String?

    var id: String { proposalId }

    enum CodingKeys: String, CodingKey {
        case proposalId = "proposal_id"
        case status
        case focus
        case hypothesis
        case experiments
        case weakestCards = "weakest_cards"
        case nextExperiment = "next_experiment"
        case guardrails
        case lastNote = "last_note"
    }
}

struct SelfImprovementSnapshot: Decodable, Equatable {
    let ok: Bool
    let summary: String
    let averageScore: Double
    let weakCards: [MissionBrainCardScore]
    let proposals: [SelfImprovementProposal]
    let latest: SelfImprovementProposal?
    let nextMove: String

    enum CodingKeys: String, CodingKey {
        case ok
        case summary
        case averageScore = "average_score"
        case weakCards = "weak_cards"
        case proposals
        case latest
        case nextMove = "next_move"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ok = try container.decode(Bool.self, forKey: .ok)
        summary = try container.decode(String.self, forKey: .summary)
        averageScore = try container.decode(Double.self, forKey: .averageScore)
        weakCards = try container.decode([MissionBrainCardScore].self, forKey: .weakCards)
        proposals = try container.decode([SelfImprovementProposal].self, forKey: .proposals)
        latest = try? container.decode(SelfImprovementProposal.self, forKey: .latest)
        nextMove = try container.decode(String.self, forKey: .nextMove)
    }
}

struct RealityCapture: Identifiable, Decodable, Equatable {
    struct Route: Decodable, Equatable {
        let target: String
        let reason: String?
    }

    struct Evidence: Decodable, Equatable {
        let name: String?
        let mimeType: String?
        let sizeBytes: Int?
        let storedPath: String?
        let analysis: String?

        enum CodingKeys: String, CodingKey {
            case name
            case mimeType = "mime_type"
            case sizeBytes = "size_bytes"
            case storedPath = "stored_path"
            case analysis
        }
    }

    let captureId: String
    let status: String
    let mode: String
    let projectId: String
    let projectTitle: String
    let note: String
    let summary: String
    let route: Route?
    let attachments: [Evidence]
    let createdAt: String?
    let updatedAt: String?

    var id: String { captureId }

    enum CodingKeys: String, CodingKey {
        case captureId = "capture_id"
        case status
        case mode
        case projectId = "project_id"
        case projectTitle = "project_title"
        case note
        case summary
        case route
        case attachments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RealityLayerSnapshot: Decodable, Equatable {
    let ok: Bool
    let summary: String
    let latest: RealityCapture?
    let captures: [RealityCapture]
    let nextMove: String

    enum CodingKeys: String, CodingKey {
        case ok
        case summary
        case latest
        case captures
        case nextMove = "next_move"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ok = try container.decode(Bool.self, forKey: .ok)
        summary = try container.decode(String.self, forKey: .summary)
        latest = try? container.decode(RealityCapture.self, forKey: .latest)
        captures = (try? container.decode([RealityCapture].self, forKey: .captures)) ?? []
        nextMove = try container.decode(String.self, forKey: .nextMove)
    }
}
