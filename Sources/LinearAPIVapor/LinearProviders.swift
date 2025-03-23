import Foundation
import Vapor
import Fluent

/// Configuration options for Linear OAuth integration
public struct LinearConfiguration {
    /// The client ID from your Linear OAuth application
    public let clientId: String
    
    /// The client secret from your Linear OAuth application
    public let clientSecret: String
    
    /// The redirect URI registered with your Linear OAuth application
    public let redirectUri: String
    
    /// The scopes to request from Linear
    public let scopes: [String]
    
    /// Initializes a new LinearConfiguration
    /// - Parameters:
    ///   - clientId: The client ID from your Linear OAuth application
    ///   - clientSecret: The client secret from your Linear OAuth application
    ///   - redirectUri: The redirect URI registered with your Linear OAuth application
    ///   - scopes: The scopes to request from Linear
    public init(clientId: String, clientSecret: String, redirectUri: String, scopes: [String] = ["read", "write"]) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
        self.scopes = scopes
    }
}

/// Extension to add Linear OAuth support to Vapor applications
public extension Application {
    /// The Linear service
    private struct LinearServiceKey: StorageKey {
        typealias Value = LinearService
    }
    
    /// Access the Linear service
    var linear: LinearService {
        get {
            guard let service = storage[LinearServiceKey.self] else {
                fatalError("Linear service not configured. Use app.useLinear(with:)")
            }
            return service
        }
        set {
            storage[LinearServiceKey.self] = newValue
        }
    }
    
    /// Configure Linear OAuth support
    /// - Parameter configuration: The Linear OAuth configuration
    /// - Returns: The application for chaining
    @available(macOS 12.0, iOS 15.0, *)
    @discardableResult
    func useLinear(with configuration: LinearConfiguration) -> Application {
        // Create the Linear service
        let linearService = LinearService(
            app: self,
            clientId: configuration.clientId,
            clientSecret: configuration.clientSecret,
            redirectUri: configuration.redirectUri
        )
        
        // Store the service
        linear = linearService
        
        // Register the migration
        migrations.add(CreateLinearToken())
        
        // Register the controllers
        let routes = self.routes
        let linearAuthController = LinearAuthController(linearService: linearService, scopes: configuration.scopes)
        try! linearAuthController.boot(routes: routes)
        
        let linearAPIController = LinearAPIController(linearService: linearService)
        try! linearAPIController.boot(routes: routes)
        
        return self
    }
} 