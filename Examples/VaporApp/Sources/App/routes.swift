import Fluent
import Vapor

@available(macOS 12.0, iOS 15.0, *)
func routes(_ app: Application) throws {
    app.get { req async in
        return "Linear API Integration Example!"
    }

    app.get("hello") { req async -> String in
        return "Hello, world!"
    }
    
    // Create a protected route group that requires authentication
    let protected = app.grouped(User.authenticator(), User.guardMiddleware())
    
    // Add a route to show the user's Linear data
    protected.get("dashboard") { req async throws -> View in
        // Here we would normally fetch and display user data from Linear
        // This is just a placeholder example
        struct DashboardContext: Encodable {
            let user: User
            let hasLinearAccess: Bool
        }
        
        let user = try req.auth.require(User.self)
        
        // Check if user has a Linear token (this method would need to be implemented)
        // In production, you'd check the database to see if there's a LinearToken for this user
        let hasLinearAccess = false
        
        return try await req.view.render(
            "dashboard", 
            DashboardContext(user: user, hasLinearAccess: hasLinearAccess)
        )
    }
    
    // Add custom routes for Linear API interactions
    protected.get("linear-data") { req async throws -> [String: String] in
        // In a real application, you would:
        // 1. Get the authenticated user
        let user = try req.auth.require(User.self)
        
        // 2. Use the LinearService to get a client for this user
        // let linearService = req.application.linear
        // let client = try await linearService.getClientForUser(user.id!.uuidString)
        
        // 3. Use the client to fetch data
        // let teams = try await client.teams.getTeams()
        
        // For this example, we'll just return a placeholder
        return ["message": "This would show Linear data for user: \(user.email)"]
    }
    
    // Add your other routes here
} 