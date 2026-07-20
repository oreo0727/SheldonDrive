import Foundation

struct HermesProject: Identifiable, Decodable, Equatable {
    struct Portfolio: Decodable, Equatable {
        let active: Bool?
        let state: String?
    }

    struct Tracking: Decodable, Equatable {
        let now: String?
        let next: String?
        let owner: String?
        let blocked: [String]?
    }

    let projectId: String
    let title: String
    let status: String?
    let summary: String?
    let progressPercent: Int?
    let focusedSlice: String?
    let portfolio: Portfolio?
    let tracking: Tracking?

    var id: String { projectId }

    var displayTitle: String {
        title.isEmpty ? projectId : title
    }

    var isActive: Bool {
        portfolio?.active == true || status?.localizedCaseInsensitiveContains("active") == true
    }

    var statusLabel: String {
        if portfolio?.active == true { return "Selected in Hermes" }
        return status?.isEmpty == false ? status! : portfolio?.state ?? "Tracked"
    }

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case title
        case status
        case summary
        case progressPercent = "progress_percent"
        case focusedSlice = "focused_slice"
        case portfolio
        case tracking
    }
}
