import Foundation

/// Response from Linear's token endpoint
@available(iOS 13.0, macOS 10.15, *)
public struct TokenResponse: Codable, Sendable {
    /// The access token
    public let accessToken: String
    
    /// The refresh token
    public let refreshToken: String
    
    /// The number of seconds until the token expires
    public let expiresIn: Int
    
    /// The token type (usually "Bearer")
    public let tokenType: String
    
    /// The scopes that the token has access to
    public let scope: String
    
    /// The date when the token was created
    public let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
    
    /// Initialize a new token response
    /// - Parameters:
    ///   - accessToken: The access token
    ///   - refreshToken: The refresh token
    ///   - expiresIn: The number of seconds until the token expires
    ///   - tokenType: The token type (usually "Bearer")
    ///   - scope: The scopes that the token has access to
    ///   - createdAt: The date when the token was created
    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        tokenType: String,
        scope: String,
        createdAt: Date? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.scope = scope
        self.createdAt = createdAt
    }
} 