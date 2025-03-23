import Foundation

/// Represents a comment in Linear
public struct Comment: Codable, Identifiable {
    /// The unique identifier of the comment
    public let id: String
    
    /// The body of the comment (Markdown)
    public let body: String
    
    /// The ID of the user who created this comment
    public let userId: String
    
    /// The ID of the issue this comment belongs to
    public let issueId: String
    
    /// The ID of the parent comment (if this is a reply)
    public let parentId: String?
    
    /// The date when this comment was created
    public let createdAt: Date
    
    /// The date when this comment was last updated
    public let updatedAt: Date
    
    /// The URL to access this comment in the Linear web app
    public let url: URL
}

/// Input type for creating a new comment
public struct CreateCommentInput: Encodable {
    /// The body of the comment (Markdown)
    public let body: String
    
    /// The ID of the issue this comment belongs to
    public let issueId: String
    
    /// The ID of the parent comment (if this is a reply)
    public let parentId: String?
    
    public init(
        body: String,
        issueId: String,
        parentId: String? = nil
    ) {
        self.body = body
        self.issueId = issueId
        self.parentId = parentId
    }
}

/// Input type for updating an existing comment
public struct UpdateCommentInput: Encodable {
    /// The ID of the comment to update
    public let id: String
    
    /// The new body of the comment (Markdown)
    public let body: String
    
    public init(id: String, body: String) {
        self.id = id
        self.body = body
    }
} 