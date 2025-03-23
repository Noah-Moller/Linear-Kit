import Foundation

/// Represents a user in Linear
@available(iOS 13.0, macOS 10.15, *)
public struct User: Codable, Identifiable, Sendable {
    /// The unique identifier of the user
    public let id: String
    
    /// The name of the user
    public let name: String
    
    /// The email of the user
    public let email: String
    
    /// The display name of the user
    public let displayName: String
    
    /// The avatar URL of the user
    public let avatarUrl: URL?
    
    /// The status of the user
    public let status: UserStatus?
    
    /// The last time the user was seen
    public let lastSeen: Date?
    
    /// Whether the user is active
    public let active: Bool
    
    /// Whether the user is an admin
    public let admin: Bool
    
    /// The ID of the organization this user belongs to
    public let organizationId: String
    
    /// The IDs of the teams this user belongs to
    public let teamIds: [String]?
    
    /// The date when this user was created
    public let createdAt: Date
    
    /// The date when this user was last updated
    public let updatedAt: Date
    
    /// The URL to access this user's profile in the Linear web app
    public let url: URL
}

/// Represents a user's status in Linear
@available(iOS 13.0, macOS 10.15, *)
public struct UserStatus: Codable, Sendable {
    /// The emoji representing the status
    public let emoji: String?
    
    /// The text of the status
    public let text: String?
    
    /// The date when this status clears automatically
    public let clearsAt: Date?
}

/// Input type for updating a user
@available(iOS 13.0, macOS 10.15, *)
public struct UpdateUserInput: Codable, Sendable {
    /// The ID of the user to update
    public let id: String
    
    /// The new name of the user
    public var name: String?
    
    /// The new display name of the user
    public var displayName: String?
    
    /// The new avatar URL of the user
    public var avatarUrl: URL?
    
    /// The new status of the user
    public var status: UserStatusInput?
    
    /// Initialize a new update user input
    /// - Parameters:
    ///   - id: The ID of the user to update
    ///   - name: The new name of the user
    ///   - displayName: The new display name of the user
    ///   - avatarUrl: The new avatar URL of the user
    ///   - status: The new status of the user
    public init(
        id: String,
        name: String? = nil,
        displayName: String? = nil,
        avatarUrl: URL? = nil,
        status: UserStatusInput? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.status = status
    }
    
    /// Convert the input to a dictionary for use in GraphQL variables
    /// - Returns: A dictionary representation of the input
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["id": id]
        
        if let name = name {
            dict["name"] = name
        }
        
        if let displayName = displayName {
            dict["displayName"] = displayName
        }
        
        if let avatarUrl = avatarUrl {
            dict["avatarUrl"] = avatarUrl.absoluteString
        }
        
        if let status = status {
            dict["status"] = status.toDictionary()
        }
        
        return dict
    }
}

/// Input type for updating a user's status
@available(iOS 13.0, macOS 10.15, *)
public struct UserStatusInput: Codable, Sendable {
    /// The emoji representing the status
    public var emoji: String?
    
    /// The text of the status
    public var message: String?
    
    /// The date when this status clears automatically (ISO8601 format)
    public var clearAt: Date?
    
    /// Initialize a new user status input
    /// - Parameters:
    ///   - emoji: The emoji representing the status
    ///   - message: The text of the status
    ///   - clearAt: The date when this status clears automatically (ISO8601 format)
    public init(emoji: String? = nil, message: String? = nil, clearAt: Date? = nil) {
        self.emoji = emoji
        self.message = message
        self.clearAt = clearAt
    }
    
    /// Convert the input to a dictionary for use in GraphQL variables
    /// - Returns: A dictionary representation of the input
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        if let emoji = emoji {
            dict["emoji"] = emoji
        }
        
        if let message = message {
            dict["message"] = message
        }
        
        if let clearAt = clearAt {
            // Use ISO 8601 format
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            dict["clearAt"] = formatter.string(from: clearAt)
        }
        
        return dict
    }
} 