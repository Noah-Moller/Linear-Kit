import Vapor
import Fluent

/// Main entrypoint for the LinearAPIVapor module
public struct LinearAPIVapor {
    /// Configure the Linear API with Vapor
    public static func configure(_ app: Application, with configuration: LinearConfiguration) throws {
        // Register migrations
        app.migrations.add(CreateLinearToken())
        
        // Configure Linear service
        app.useLinear(with: configuration)
        
        // Register controllers
        let linearAuthController = LinearAuthController(linearService: app.linear)
        let linearApiController = LinearAPIController(linearService: app.linear)
        
        try app.register(collection: linearAuthController)
        try app.register(collection: linearApiController)
    }
}

/// Extension to Application for easy setup of Linear API integration
extension Application {
    /// Configure the Linear API with default routes
    public func configureLinearAPI(
        clientId: String,
        clientSecret: String,
        redirectUri: String,
        scopes: [String] = ["read", "write", "issues:create"]
    ) throws {
        let config = LinearConfiguration(
            clientId: clientId, 
            clientSecret: clientSecret, 
            redirectUri: redirectUri,
            scopes: scopes
        )
        
        try LinearAPIVapor.configure(self, with: config)
    }
} 