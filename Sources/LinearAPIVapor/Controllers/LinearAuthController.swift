import Foundation
import Vapor
import LinearAPI

/// Controller for handling Linear OAuth authentication routes
@available(macOS 12.0, iOS 15.0, *)
public struct LinearAuthController: RouteCollection {
    /// The Linear service
    private let linearService: LinearService
    
    /// The scopes to request from Linear
    private let scopes: [String]
    
    /// Initializes a new LinearAuthController
    /// - Parameters:
    ///   - linearService: The Linear service
    ///   - scopes: The scopes to request from Linear
    public init(linearService: LinearService, scopes: [String] = ["read", "write"]) {
        self.linearService = linearService
        self.scopes = scopes
    }
    
    /// Registers routes with the given route builder
    /// - Parameter routes: The route builder to register routes with
    public func boot(routes: RoutesBuilder) throws {
        let authRoutes = routes.grouped("linear", "auth")
        
        // Route for initiating the OAuth flow
        authRoutes.get("login") { req -> Response in
            // Get the user ID from the request (you should implement user authentication)
            guard let userId = try? req.auth.require(AuthUserModel.self).id else {
                throw Abort(.unauthorized, reason: "User must be authenticated")
            }
            
            // Generate a random state for CSRF protection
            let state = UUID().uuidString
            
            // Store the state in the session
            req.session.data["linear_oauth_state"] = state
            
            // Store the user ID in the session
            req.session.data["linear_oauth_user_id"] = userId
            
            // Get the authorization URL
            let authURL = linearService.getAuthorizationURL(scopes: scopes, state: state)
            
            // Redirect to the authorization URL
            return req.redirect(to: authURL.absoluteString)
        }
        
        // Route for handling the OAuth callback
        authRoutes.get("callback") { req -> Response in
            // Extract query parameters
            guard let code = req.query[String.self, at: "code"] else {
                throw Abort(.badRequest, reason: "Missing authorization code")
            }
            
            guard let state = req.query[String.self, at: "state"] else {
                throw Abort(.badRequest, reason: "Missing state parameter")
            }
            
            // Verify the state parameter
            guard let storedState = req.session.data["linear_oauth_state"], storedState == state else {
                throw Abort(.badRequest, reason: "Invalid state parameter")
            }
            
            // Get the user ID from the session
            guard let userId = req.session.data["linear_oauth_user_id"] else {
                throw Abort(.unauthorized, reason: "No user ID in session")
            }
            
            // Clear the session data
            req.session.data["linear_oauth_state"] = nil
            req.session.data["linear_oauth_user_id"] = nil
            
            // Exchange the code for a token and store it
            _ = try await linearService.exchangeAndStoreToken(userId: userId, code: code)
            
            // Return a success response or redirect to a success page
            return req.redirect(to: "/linear/auth/success")
        }
        
        // Route for handling successful authentication
        authRoutes.get("success") { req -> View in
            // Return a success view
            return try await req.view.render("linear_auth_success")
        }
        
        // Route for revoking a token
        authRoutes.post("revoke") { req -> HTTPStatus in
            // Get the user ID from the request (you should implement user authentication)
            guard let userId = try? req.auth.require(AuthUserModel.self).id else {
                throw Abort(.unauthorized, reason: "User must be authenticated")
            }
            
            // Revoke the token
            _ = try await linearService.revokeTokenForUser(userId)
            
            // Return a success status
            return .ok
        }
    }
}

/// Protocol for authenticated user models
public struct AuthUserModel: Authenticatable {
    /// The user's identifier
    public let id: String
    
    public init(id: String) {
        self.id = id
    }
} 