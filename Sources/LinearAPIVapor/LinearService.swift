// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Vapor
import Fluent
import LinearAPI

/// Service for managing Linear OAuth tokens on the server side
@available(macOS 12.0, iOS 15.0, *)
public final class LinearService: @unchecked Sendable {
    /// The authentication service for communicating with Linear's OAuth API
    private let authService: AuthService
    
    /// The Vapor application
    private let app: Application
    
    /// The client ID for Linear OAuth
    private let clientId: String
    
    /// The client secret for Linear OAuth
    private let clientSecret: String
    
    /// The redirect URI for Linear OAuth
    private let redirectUri: String
    
    /// Initialize the Linear service
    /// - Parameters:
    ///   - app: The Vapor application
    ///   - clientId: The OAuth client ID
    ///   - clientSecret: The OAuth client secret
    ///   - redirectUri: The redirect URI
    internal init(app: Application, clientId: String, clientSecret: String, redirectUri: String) {
        self.app = app
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
        
        self.authService = AuthService(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
    }
    
    /// Exchange an authorization code for a token and store it
    /// - Parameters:
    ///   - userId: The user ID to associate with the token
    ///   - code: The authorization code received from the redirect
    /// - Returns: The LinearToken that was stored
    public func exchangeAndStoreToken(userId: String, code: String) async throws -> LinearToken {
        // Exchange the code for a token
        let tokenResponse = try await authService.exchangeCodeForToken(code: code)
        
        // Create a new token model
        let token = LinearToken(
            userId: userId,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            tokenType: tokenResponse.tokenType,
            scope: tokenResponse.scope,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        )
        
        // Save the token to the database
        try await token.save(on: app.db)
        
        return token
    }
    
    /// Get a valid token for a user
    /// - Parameter userId: The user ID
    /// - Returns: The valid token
    /// - Throws: An error if no token is found or if token refresh fails
    public func getTokenForUser(_ userId: String) async throws -> LinearToken {
        // Check if the user has a token in the database
        guard let token = try await LinearToken.query(on: app.db)
            .filter(\.$userId == userId)
            .first() else {
            throw Abort(.unauthorized, reason: "No token found for user")
        }
        
        // Check if the token needs to be refreshed
        if token.expiresAt.timeIntervalSinceNow < 300 { // 5 minutes buffer
            try await refreshToken(token)
        }
        
        return token
    }
    
    /// Refresh an access token
    /// - Parameter token: The token to refresh
    /// - Throws: An error if token refresh failed
    private func refreshToken(_ token: LinearToken) async throws {
        // Refresh the token
        let tokenResponse = try await authService.refreshAccessToken(refreshToken: token.refreshToken)
        
        // Update the token model
        token.accessToken = tokenResponse.accessToken
        token.refreshToken = tokenResponse.refreshToken
        token.tokenType = tokenResponse.tokenType
        token.scope = tokenResponse.scope
        token.expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        
        // Save the updated token to the database
        try await token.save(on: app.db)
    }
    
    /// Revoke a user's token
    /// - Parameter userId: The user ID
    /// - Returns: Whether the revocation was successful
    /// - Throws: An error if no token was found or if token revocation failed
    public func revokeTokenForUser(_ userId: String) async throws -> Bool {
        // Get the user's token from the database
        guard let token = try await LinearToken.query(on: app.db)
            .filter(\.$userId == userId)
            .first() else {
            throw Abort(.unauthorized, reason: "No token found for user")
        }
        
        // Revoke the token
        let success = try await authService.revokeToken(accessToken: token.accessToken)
        
        // Delete the token from the database
        try await token.delete(on: app.db)
        
        return success
    }
    
    /// Get the authorization URL for the Linear OAuth flow
    /// - Parameters:
    ///   - scopes: The scopes to request
    ///   - state: A state string for CSRF protection
    /// - Returns: The authorization URL
    public func getAuthorizationURL(scopes: [String], state: String) -> URL {
        return authService.getAuthorizationURL(scopes: scopes, state: state)
    }
    
    /// Create a LinearClient for the given user
    /// - Parameter userId: The user ID
    /// - Returns: A configured LinearClient
    /// - Throws: An error if no token is found for the user
    public func getClientForUser(_ userId: String) async throws -> LinearClient {
        let token = try await getTokenForUser(userId)
        return LinearClient(accessToken: token.accessToken)
    }
} 