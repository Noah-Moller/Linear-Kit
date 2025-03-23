import Foundation
import Vapor
import Fluent
import FluentSQLiteDriver
import LinearAPIVapor

// Configure your application
public func configure(_ app: Application) throws {
    // Configure environment variables
    let clientId = Environment.get("LINEAR_CLIENT_ID") ?? "your_client_id"
    let clientSecret = Environment.get("LINEAR_CLIENT_SECRET") ?? "your_client_secret"
    let redirectUri = Environment.get("LINEAR_REDIRECT_URI") ?? "http://localhost:8080/linear/auth/callback"
    
    // Configure middlewares
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    // Configure database
    app.databases.use(.sqlite(.file("linear.sqlite")), as: .sqlite)
    
    // Configure LinearAPI
    try app.configureLinearAPI(
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUri: redirectUri,
        scopes: ["read", "write", "issues:create"]
    )
    
    // Run migrations
    try app.autoMigrate().wait()
    
    // Register routes
    try routes(app)
} 