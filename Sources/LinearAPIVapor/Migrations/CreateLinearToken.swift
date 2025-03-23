import Fluent

/// Migration to create the LinearToken table
@available(macOS 12.0, iOS 15.0, *)
public struct CreateLinearToken: AsyncMigration {
    /// Creates the LinearToken table
    public func prepare(on database: Database) async throws {
        try await database.schema("linear_tokens")
            .id()
            .field("user_id", .string, .required)
            .field("access_token", .string, .required)
            .field("refresh_token", .string, .required)
            .field("token_type", .string, .required)
            .field("scope", .string, .required)
            .field("expires_at", .datetime, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }
    
    /// Deletes the LinearToken table
    public func revert(on database: Database) async throws {
        try await database.schema("linear_tokens").delete()
    }
    
    /// Creates a new migration
    public init() {}
} 