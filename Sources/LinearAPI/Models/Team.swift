import Foundation

/// Represents a team in Linear
@available(iOS 13.0, macOS 10.15, *)
public struct Team: Codable, Identifiable, Sendable {
    /// The unique identifier of the team
    public let id: String
    
    /// The name of the team
    public let name: String
    
    /// The key of the team (used in issue identifiers, e.g., ENG-123)
    public let key: String
    
    /// The description of the team
    public let description: String?
    
    /// The color of the team
    public let color: String?
    
    /// The icon of the team
    public let icon: String?
    
    /// The ID of the organization this team belongs to
    public let organizationId: String
    
    /// The date when this team was created
    public let createdAt: Date
    
    /// The date when this team was last updated
    public let updatedAt: Date
    
    /// The IDs of the members of this team
    public let memberIds: [String]?
    
    /// The IDs of the lead users of this team
    public let leadUserIds: [String]?
    
    /// The URL to access this team in the Linear web app
    public let url: URL
}

/// Input data for creating a new team
@available(iOS 13.0, macOS 10.15, *)
public struct CreateTeamInput: Encodable, Sendable {
    /// The name of the team
    public let name: String
    
    /// The key of the team (used in issue identifiers, e.g., "ENG")
    public let key: String
    
    /// The description of the team
    public let description: String?
    
    /// The color of the team (hex code)
    public let color: String?
    
    /// The icon of the team
    public let icon: String?
    
    public init(
        name: String,
        key: String,
        description: String? = nil,
        color: String? = nil,
        icon: String? = nil
    ) {
        self.name = name
        self.key = key
        self.description = description
        self.color = color
        self.icon = icon
    }
    
    /// Convert the input to a dictionary for GraphQL variables
    /// - Returns: Dictionary representation of the input
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        dict["name"] = name
        
        dict["key"] = key
        
        if let description = description {
            dict["description"] = description
        }
        
        if let icon = icon {
            dict["icon"] = icon
        }
        
        if let color = color {
            dict["color"] = color
        }
        
        return dict
    }
}

/// Input data for updating a team
@available(iOS 13.0, macOS 10.15, *)
public struct UpdateTeamInput: Encodable, Sendable {
    /// The ID of the team to update
    public let id: String
    
    /// The new name of the team
    public let name: String?
    
    /// The new key of the team
    public let key: String?
    
    /// The new description of the team
    public let description: String?
    
    /// The new color of the team
    public let color: String?
    
    /// The new icon of the team
    public let icon: String?
    
    public init(
        id: String,
        name: String? = nil,
        key: String? = nil,
        description: String? = nil,
        color: String? = nil,
        icon: String? = nil
    ) {
        self.id = id
        self.name = name
        self.key = key
        self.description = description
        self.color = color
        self.icon = icon
    }
    
    /// Convert the input to a dictionary for GraphQL variables
    /// - Returns: Dictionary representation of the input
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["id": id]
        
        if let name = name {
            dict["name"] = name
        }
        
        if let key = key {
            dict["key"] = key
        }
        
        if let description = description {
            dict["description"] = description
        }
        
        if let icon = icon {
            dict["icon"] = icon
        }
        
        if let color = color {
            dict["color"] = color
        }
        
        return dict
    }
} 