import Foundation

/// Represents an issue in Linear
@available(iOS 13.0, macOS 10.15, *)
public struct Issue: Codable, Identifiable, Sendable {
    /// The unique identifier of the issue
    public let id: String
    
    /// The issue identifier with the team prefix (e.g., ENG-123)
    public let identifier: String
    
    /// The title of the issue
    public let title: String
    
    /// The description of the issue (Markdown)
    public let description: String?
    
    /// The priority of the issue (0-4)
    public let priority: Int?
    
    /// The current estimate of the issue
    public let estimate: Float?
    
    /// The ID of the project this issue belongs to
    public let projectId: String?
    
    /// The ID of the team this issue belongs to
    public let teamId: String
    
    /// The ID of the cycle this issue belongs to
    public let cycleId: String?
    
    /// The IDs of labels attached to this issue
    public let labelIds: [String]?
    
    /// The ID of the assignee of this issue
    public let assigneeId: String?
    
    /// The ID of the creator of this issue
    public let creatorId: String
    
    /// The ID of the parent issue
    public let parentId: String?
    
    /// The ID of the workflow state of this issue
    public let stateId: String
    
    /// The state name of this issue (e.g., "In Progress")
    public let stateName: String?
    
    /// The date when this issue was created
    public let createdAt: Date
    
    /// The date when this issue was last updated
    public let updatedAt: Date
    
    /// The date when this issue was moved to started
    public let startedAt: Date?
    
    /// The date when this issue was completed
    public let completedAt: Date?
    
    /// The date when this issue was cancelled
    public let cancelledAt: Date?
    
    /// The date when this issue is due
    public let dueDate: Date?
    
    /// Whether the issue has been trashed
    public let trashed: Bool?
    
    /// Whether the issue is in the customer feedback state
    public let customerTicketCount: Int?
    
    /// The URL to access this issue in the Linear web app
    public let url: URL
}

/// Input data for creating a new issue
@available(iOS 13.0, macOS 10.15, *)
public struct CreateIssueInput: Encodable, Sendable {
    /// The title of the issue
    public let title: String
    
    /// The ID of the team this issue belongs to
    public let teamId: String
    
    /// The description of the issue (Markdown)
    public let description: String?
    
    /// The priority of the issue (0-4)
    public let priority: Int?
    
    /// The current estimate of the issue
    public let estimate: Float?
    
    /// The ID of the project this issue belongs to
    public let projectId: String?
    
    /// The ID of the cycle this issue belongs to
    public let cycleId: String?
    
    /// The IDs of labels attached to this issue
    public let labelIds: [String]?
    
    /// The ID of the assignee of this issue
    public let assigneeId: String?
    
    /// The ID of the parent issue
    public let parentId: String?
    
    /// The ID of the workflow state of this issue
    public let stateId: String?
    
    /// The due date of this issue (ISO8601 format)
    public let dueDate: String?
    
    /// Convert the input to a dictionary for GraphQL variables
    /// - Returns: Dictionary representation of the input
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        dict["teamId"] = teamId
        dict["title"] = title
        
        if let description = description {
            dict["description"] = description
        }
        
        if let assigneeId = assigneeId {
            dict["assigneeId"] = assigneeId
        }
        
        if let priority = priority {
            dict["priority"] = priority
        }
        
        if let stateId = stateId {
            dict["stateId"] = stateId
        }
        
        if let estimate = estimate {
            dict["estimate"] = estimate
        }
        
        if let labelIds = labelIds, !labelIds.isEmpty {
            dict["labelIds"] = labelIds
        }
        
        return dict
    }
    
    public init(
        title: String,
        teamId: String,
        description: String? = nil,
        priority: Int? = nil,
        estimate: Float? = nil,
        projectId: String? = nil,
        cycleId: String? = nil,
        labelIds: [String]? = nil,
        assigneeId: String? = nil,
        parentId: String? = nil,
        stateId: String? = nil,
        dueDate: String? = nil
    ) {
        self.title = title
        self.teamId = teamId
        self.description = description
        self.priority = priority
        self.estimate = estimate
        self.projectId = projectId
        self.cycleId = cycleId
        self.labelIds = labelIds
        self.assigneeId = assigneeId
        self.parentId = parentId
        self.stateId = stateId
        self.dueDate = dueDate
    }
}

/// Input data for updating an issue
@available(iOS 13.0, macOS 10.15, *)
public struct UpdateIssueInput: Encodable, Sendable {
    /// The ID of the issue to update
    public let id: String
    
    /// The new title of the issue
    public let title: String?
    
    /// The new description of the issue (Markdown)
    public let description: String?
    
    /// The new priority of the issue (0-4)
    public let priority: Int?
    
    /// The new estimate of the issue
    public let estimate: Float?
    
    /// The new ID of the project this issue belongs to
    public let projectId: String?
    
    /// The new ID of the cycle this issue belongs to
    public let cycleId: String?
    
    /// The new IDs of labels attached to this issue
    public let labelIds: [String]?
    
    /// The new ID of the assignee of this issue
    public let assigneeId: String?
    
    /// The new ID of the parent issue
    public let parentId: String?
    
    /// The new ID of the workflow state of this issue
    public let stateId: String?
    
    /// The new due date of this issue (ISO8601 format)
    public let dueDate: String?
    
    /// Convert the input to a dictionary for GraphQL variables
    /// - Returns: Dictionary representation of the input
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["id": id]
        
        if let title = title {
            dict["title"] = title
        }
        
        if let description = description {
            dict["description"] = description
        }
        
        if let assigneeId = assigneeId {
            dict["assigneeId"] = assigneeId
        }
        
        if let priority = priority {
            dict["priority"] = priority
        }
        
        if let stateId = stateId {
            dict["stateId"] = stateId
        }
        
        if let estimate = estimate {
            dict["estimate"] = estimate
        }
        
        if let labelIds = labelIds {
            dict["labelIds"] = labelIds
        }
        
        return dict
    }
    
    public init(
        id: String,
        title: String? = nil,
        description: String? = nil,
        priority: Int? = nil,
        estimate: Float? = nil,
        projectId: String? = nil,
        cycleId: String? = nil,
        labelIds: [String]? = nil,
        assigneeId: String? = nil,
        parentId: String? = nil,
        stateId: String? = nil,
        dueDate: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.estimate = estimate
        self.projectId = projectId
        self.cycleId = cycleId
        self.labelIds = labelIds
        self.assigneeId = assigneeId
        self.parentId = parentId
        self.stateId = stateId
        self.dueDate = dueDate
    }
} 