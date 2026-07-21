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
