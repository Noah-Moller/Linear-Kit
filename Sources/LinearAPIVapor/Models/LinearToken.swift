import Foundation
import Vapor
import Fluent
import LinearAPI

/// Model for storing Linear OAuth tokens in the database
@available(macOS 12.0, iOS 15.0, *)
public final class LinearToken: Model, Content, @unchecked Sendable {
    public static let schema = "linear_tokens"
    
    @ID(key: .id)
    public var id: UUID?
    
    /// The user identifier that this token belongs to
    @Field(key: "user_id")
    public var userId: String
    
    /// The access token for authenticating requests
    @Field(key: "access_token")
    public var accessToken: String
    
    /// The refresh token for obtaining a new access token
    @Field(key: "refresh_token")
    public var refreshToken: String
    
    /// The type of token (usually "Bearer")
    @Field(key: "token_type")
    public var tokenType: String
    
    /// The scopes that this token has access to
    @Field(key: "scope")
    public var scope: String
    
    /// When the access token expires
    @Field(key: "expires_at")
    public var expiresAt: Date
    
    /// The date when this token was created
    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?
    
    /// The date when this token was last updated
    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?
    
    /// Default initializer for Fluent
    public init() {}
    
    /// Initializes a new token
    /// - Parameters:
    ///   - id: The UUID for the token (auto-generated if nil)
    ///   - userId: The user identifier that this token belongs to
    ///   - accessToken: The access token for authenticating requests
    ///   - refreshToken: The refresh token for obtaining a new access token
    ///   - tokenType: The type of token (usually "Bearer")
    ///   - scope: The scopes that this token has access to
    ///   - expiresAt: When the access token expires
    public init(
        id: UUID? = nil,
        userId: String,
        accessToken: String,
        refreshToken: String,
        tokenType: String = "Bearer",
        scope: String = "read write",
        expiresAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.scope = scope
        self.expiresAt = expiresAt
    }
    
    /// Creates a new LinearToken from a token response
    /// - Parameters:
    ///   - userId: The user ID to associate with the token
    ///   - tokenResponse: The token response from Linear
    /// - Returns: A new LinearToken
    public static func from(userId: String, tokenResponse: TokenResponse) -> LinearToken {
        return LinearToken(
            userId: userId,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            tokenType: tokenResponse.tokenType,
            scope: tokenResponse.scope,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        )
    }
    
    /// Checks if the token has expired
    /// - Returns: Whether the token has expired
    public func hasExpired() -> Bool {
        return Date() > expiresAt
    }
    
    /// Checks if the token is close to expiring (within 5 minutes)
    /// - Returns: Whether the token is close to expiring
    public func isExpiringSoon() -> Bool {
        return Date().addingTimeInterval(300) > expiresAt
    }
    
    /// Updates this token with values from a token response
    /// - Parameter tokenResponse: The token response from Linear
    public func update(with tokenResponse: TokenResponse) {
        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
        self.tokenType = tokenResponse.tokenType
        self.scope = tokenResponse.scope
        self.expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
    }
} 