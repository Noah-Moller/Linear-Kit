import Fluent
import FluentSQLiteDriver
import Vapor
import LinearAPIVapor

// configures your application
@available(macOS 12.0, iOS 15.0, *)
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Configure SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    // Configure migrations
    app.migrations.add(CreateUser())
    
    // Configure Linear OAuth integration
    let linearConfig = LinearConfiguration(
        clientId: Environment.get("LINEAR_CLIENT_ID") ?? "your_client_id",
        clientSecret: Environment.get("LINEAR_CLIENT_SECRET") ?? "your_client_secret",
        redirectUri: Environment.get("LINEAR_REDIRECT_URI") ?? "http://localhost:8080/linear/auth/callback",
        scopes: ["read", "write"]
    )
    
    // Set up Linear integration
    app.useLinear(with: linearConfig)
    
    // register routes
    try routes(app)
} 