# LinearKit

A Swift package for interacting with the [Linear](https://linear.app) API.

LinearKit is a Swift wrapper around Linear's GraphQL API that provides a convenient interface for Swift and SwiftUI applications to integrate with Linear's project management tools.

## Features

- Direct client-side OAuth 2.0 authentication flow
- Server-side OAuth integration with Vapor
- GraphQL query and mutation support
- Type-safe response handling
- Async/await support
- Comprehensive SwiftUI integration

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.5+
- Vapor 4.76.0+ (for server-side integration)

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/LinearAPI.git", from: "1.0.0")
]
```

Or add it directly via Xcode:
1. Go to File > Swift Packages > Add Package Dependency
2. Enter the repository URL: `https://github.com/yourusername/LinearAPI.git`
3. Follow the prompts to complete the installation

## Getting Started

LinearAPI supports multiple authentication methods and deployment scenarios:

### 1. API Token Authentication (For Personal Use)

```swift
import LinearAPI

// Initialize the client with your API key
let client = LinearClient(apiToken: "your_api_key_here")
```

To get an API key from Linear:
1. Log in to your Linear account
2. Go to Settings > API > Personal API keys
3. Create a new API key with appropriate permissions

### 2. OAuth Authentication (For Multi-User Applications)

OAuth authentication allows users to authorize your application to access their Linear data without sharing their credentials.

#### Step 1: Create an OAuth application in Linear

1. Create or sign in to a Linear workspace
2. Go to Settings > API > OAuth applications
3. Create a new OAuth application
4. Add your redirect URL
5. **Important:** Make sure to enable "Public" if you want users from other workspaces to authenticate with your app

#### Step 2: Implement OAuth flow in your app

```swift
import LinearAPI
import AuthenticationServices

class LinearAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let authService: AuthService
    private var webAuthSession: ASWebAuthenticationSession?
    
    init(clientId: String, clientSecret: String, redirectUri: String) {
        self.authService = AuthService(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectUri: redirectUri
        )
        super.init()
    }
    
    func startOAuthFlow(completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        // Generate random state for security
        let state = UUID().uuidString
        
        // Create authorization URL with requested scopes
        let authURL = authService.getAuthorizationURL(
            scopes: ["read", "write", "issues:create"],
            state: state,
            actor: "user" // Can also be "application" for app-level auth
        )
        
        // Launch web authentication session
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: URL(string: redirectUri)?.scheme,
            completionHandler: { [weak self] callbackURL, error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let queryItems = components.queryItems else {
                    completion(.failure(LinearAPIError.invalidResponse))
                    return
                }
                
                // Verify state parameter
                guard let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
                      returnedState == state else {
                    completion(.failure(LinearAPIError.invalidResponse))
                    return
                }
                
                // Extract authorization code
                guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    completion(.failure(LinearAPIError.invalidResponse))
                    return
                }
                
                // Exchange code for token
                self.authService.exchangeCodeForToken(code: code) { result in
                    switch result {
                    case .success(let tokenResponse):
                        completion(.success(tokenResponse))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        )
        
        webAuthSession?.presentationContextProvider = self
        webAuthSession?.prefersEphemeralWebBrowserSession = true
        webAuthSession?.start()
    }
    
    // ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// Example usage in a view controller
func connectLinear() {
    let authManager = LinearAuthManager(
        clientId: "your_client_id",
        clientSecret: "your_client_secret",
        redirectUri: "your-app://oauth-callback"
    )
    
    authManager.startOAuthFlow { result in
        switch result {
        case .success(let tokenResponse):
            // Create a Linear client with the access token
            let linearClient = LinearClient(accessToken: tokenResponse.accessToken)
            
            // You should securely store the tokenResponse for later use
            // The refresh token can be used to get a new access token when it expires
            
            // Now you can use the client to interact with the Linear API
            linearClient.users.getCurrentUser { result in
                switch result {
                case .success(let user):
                    print("Connected as: \(user.name)")
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
            
        case .failure(let error):
            print("Authentication failed: \(error)")
        }
    }
}
```

#### Step 3: Refresh tokens when needed

```swift
func refreshAccessToken(refreshToken: String) {
    let authService = AuthService(
        clientId: "your_client_id",
        clientSecret: "your_client_secret",
        redirectUri: "your-app://oauth-callback"
    )
    
    authService.refreshAccessToken(refreshToken: refreshToken) { result in
        switch result {
        case .success(let newTokenResponse):
            // Update stored tokens
            print("Token refreshed successfully")
        case .failure(let error):
            print("Failed to refresh token: \(error)")
            // Handle token refresh failure
        }
    }
}
```

#### Step 4: Revoke tokens when needed

```swift
func revokeToken(accessToken: String) {
    let authService = AuthService(
        clientId: "your_client_id",
        clientSecret: "your_client_secret",
        redirectUri: "your-app://oauth-callback"
    )
    
    authService.revokeToken(accessToken: accessToken) { success, error in
        if success {
            print("Token revoked successfully")
        } else if let error = error {
            print("Failed to revoke token: \(error)")
        }
    }
}
```

### 3. Server-Side OAuth with Vapor (Multi-User, Server-Client Architecture)

LinearAPI includes a Vapor integration for server-side OAuth handling, which is ideal for:
- Multi-platform applications (iOS, macOS, web)
- Secure token storage on the server
- Centralized authentication management
- Cross-device user experience

#### Step 1: Configure your Vapor server

```swift
import Vapor
import Fluent
import FluentSQLiteDriver
import LinearAPIVapor

// Configure your application
public func configure(_ app: Application) throws {
    // Configure database
    app.databases.use(.sqlite(.file("linear.sqlite")), as: .sqlite)
    
    // Configure sessions
    app.middleware.use(app.sessions.middleware)
    
    // Configure Linear OAuth
    app.useLinear(with: LinearConfiguration(
        clientId: "your_client_id",
        clientSecret: "your_client_secret",
        redirectUri: "your-website.com/linear/auth/callback",
        scopes: ["read", "write", "issues:create"]
    ))
    
    // Configure routes
    try routes(app)
}
```

#### Step 2: Use the LinearService in your routes

```swift
func routes(_ app: Application) throws {
    // Example route for getting a user's issues
    app.get("user", ":userId", "issues") { req -> EventLoopFuture<[Issue]> in
        let userId = req.parameters.get("userId")!
        
        // Get a Linear client for the user
        let client = try await app.linear.getClientForUser(userId)
        
        // Get the user's issues
        let issues = try await client.issues.getIssues()
        
        return req.eventLoop.future(issues.nodes)
    }
}
```

#### Step 3: Set up the client-side SwiftUI app

```swift
import SwiftUI
import LinearAPI

struct ContentView: View {
    @StateObject private var linearClient = LinearServerClient(
        serverURL: URL(string: "https://your-website.com")!
    )
    
    // Create a presentation context provider
    private let contextProvider = PresentationContextProvider()
    
    var body: some View {
        VStack {
            if linearClient.isAuthenticated {
                // Show user's Linear data
                LinearDataView(client: linearClient)
            } else {
                // Show login view
                LinearServerLoginView(
                    client: linearClient,
                    contextProvider: contextProvider
                )
            }
        }
    }
}

struct LinearDataView: View {
    @ObservedObject var client: LinearServerClient
    @State private var user: User?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let user = user {
                // Show user info
                Text("Welcome, \(user.name)")
                
                // Sign out button
                Button("Sign Out") {
                    client.signOut()
                }
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        isLoading = true
        
        client.getCurrentUser { result in
            isLoading = false
            
            switch result {
            case .success(let user):
                self.user = user
            case .failure(let error):
                self.error = error
            }
        }
    }
}
```

## Usage Examples

### Working with Issues

```swift
// Create an issue service
let issueService = client.issues

// Fetch an issue by ID
issueService.getIssue(id: "issue_id") { result in
    switch result {
    case .success(let issue):
        print("Fetched issue: \(issue.title)")
    case .failure(let error):
        print("Error fetching issue: \(error)")
    }
}

// Fetch issues for a team
issueService.getIssues(teamId: "team_id") { result in
    switch result {
    case .success(let connection):
        for issue in connection.nodes {
            print("Issue: \(issue.title)")
        }
        
        if connection.pageInfo.hasNextPage {
            // Fetch next page
            let pagination = PaginationInput(first: 50, after: connection.pageInfo.endCursor)
            // ...
        }
    case .failure(let error):
        print("Error fetching issues: \(error)")
    }
}

// Create a new issue
let newIssue = CreateIssueInput(
    title: "Fix login bug",
    teamId: "team_id",
    description: "Users are unable to log in when using Safari",
    priority: 2
)

issueService.createIssue(input: newIssue) { result in
    switch result {
    case .success(let issue):
        print("Created issue: \(issue.id)")
    case .failure(let error):
        print("Error creating issue: \(error)")
    }
}

// Update an issue
let updateInput = UpdateIssueInput(
    id: "issue_id",
    title: "Fixed login bug",
    stateId: "completed_state_id"
)

issueService.updateIssue(input: updateInput) { result in
    switch result {
    case .success(let issue):
        print("Updated issue: \(issue.title)")
    case .failure(let error):
        print("Error updating issue: \(error)")
    }
}
```

### Working with Teams

```swift
// Create a team service
let teamService = client.teams

// Fetch all teams
teamService.getTeams() { result in
    switch result {
    case .success(let connection):
        for team in connection.nodes {
            print("Team: \(team.name)")
        }
    case .failure(let error):
        print("Error fetching teams: \(error)")
    }
}

// Create a new team
let newTeam = CreateTeamInput(
    name: "Mobile Team",
    key: "MOB"
)

teamService.createTeam(input: newTeam) { result in
    switch result {
    case .success(let team):
        print("Created team: \(team.id)")
    case .failure(let error):
        print("Error creating team: \(error)")
    }
}
```

### User Information

```swift
// Fetch the currently authenticated user
client.users.getCurrentUser { result in
    switch result {
    case .success(let user):
        print("Authenticated as: \(user.name)")
        print("Email: \(user.email)")
        print("Organization ID: \(user.organizationId)")
        
        if let teams = user.teamIds {
            print("Teams: \(teams.joined(separator: ", "))")
        }
    case .failure(let error):
        print("Error fetching user: \(error)")
    }
}
```

### Async/Await Support (iOS 15+, macOS 12+)

If you're using iOS 15 or macOS 12 and later, you can use the async/await API:

```swift
// Fetch an issue
do {
    let issue = try await client.issues.getIssue(id: "issue_id")
    print("Fetched issue: \(issue.title)")
} catch {
    print("Error: \(error)")
}

// Create an issue
do {
    let newIssue = CreateIssueInput(
        title: "Fix login bug",
        teamId: "team_id"
    )
    let issue = try await client.issues.createIssue(input: newIssue)
    print("Created issue: \(issue.id)")
} catch {
    print("Error: \(error)")
}

// Authenticate with OAuth
do {
    // This part requires the web authentication flow shown earlier
    // ...
    
    // After getting the authorization code:
    let tokenResponse = try await authService.exchangeCodeForToken(code: code)
    let client = LinearClient(accessToken: tokenResponse.accessToken)
    
    // Get user info
    let user = try await client.users.getCurrentUser()
    print("Authenticated as: \(user.name)")
} catch {
    print("Authentication error: \(error)")
}
```

## Advanced Usage

### Pagination

For endpoints that return collections of data, LinearAPI uses a pagination system based on cursors:

```swift
// Fetch first page
let firstPage = PaginationInput(first: 10)
client.issues.getIssues(pagination: firstPage) { result in
    switch result {
    case .success(let connection):
        // Process first page
        
        // If there's a next page
        if connection.pageInfo.hasNextPage, let endCursor = connection.pageInfo.endCursor {
            // Fetch next page
            let nextPage = PaginationInput(first: 10, after: endCursor)
            client.issues.getIssues(pagination: nextPage) { result in
                // Process next page
            }
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Server-Side Authentication Flow

When using the server-side integration, the authentication flow works as follows:

1. User clicks "Connect Linear Account" in your app
2. App opens a web authentication session to your server's login endpoint
3. Server redirects to Linear's authorization page
4. User authorizes your app on Linear
5. Linear redirects back to your server with an authorization code
6. Server exchanges the code for tokens and stores them securely
7. Server redirects back to your app to indicate successful authentication
8. App updates its UI to show the user is authenticated
9. App makes API requests to your server, which includes the necessary authentication

### Actor Authentication

Linear supports two types of authentication actors:

1. **User**: The default. API actions are performed as the authenticated user.
2. **Application**: API actions are performed as the application itself.

To use application actor authentication:

```swift
// For direct OAuth client
let authURL = authService.getAuthorizationURL(
    scopes: ["read", "write"],
    state: "random-state-string",
    actor: "application"
)

// For server-side integration
app.useLinear(with: LinearConfiguration(
    clientId: "your_client_id",
    clientSecret: "your_client_secret",
    redirectUri: "your-website.com/linear/auth/callback",
    scopes: ["read", "write"],
    actor: "application"
))
```

## License

This project is available under the MIT license.

## Development

### Project Structure

- `Sources/LinearAPI`: Core API client for Linear
- `Sources/LinearAPIVapor`: Server-side integration with Vapor framework
- `Tests/LinearAPITests`: Unit tests for the core API client
- `Tests/LinearAPIVaporTests`: Unit tests for the Vapor integration

### Recent Updates

- Added URLSession dependency injection to LinearClient for better testability
- Fixed mock URLSession in tests to properly simulate API responses
- Made both core LinearAPI and LinearAPIVapor modules compatible with Swift concurrency
- Added proper availability annotations for async/await features (requires macOS 12+ / iOS 15+)
- Added Vapor-compatible GraphQL response types that conform to Encodable
- Implemented both direct authentication and server-side OAuth approaches
- Fixed LinearToken issues for proper refresh token handling

### Vapor Integration

The LinearAPIVapor module provides server-side integration with the Vapor framework, allowing you to:

1. **Authenticate users with Linear OAuth**:
   - Implement server-side OAuth flow
   - Store and refresh tokens automatically
   - Manage user authentication state

2. **Create API endpoints for Linear operations**:
   - Expose GraphQL endpoints
   - Query user data, teams, and issues
   - Handle permissions and authentication

**Usage Example:**

```swift
import Vapor
import LinearAPIVapor

// Configure your application
@main
struct YourApp {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        // Configure Linear OAuth
        let linearConfig = LinearConfiguration(
            clientId: Environment.get("LINEAR_CLIENT_ID")!,
            clientSecret: Environment.get("LINEAR_CLIENT_SECRET")!,
            redirectUri: Environment.get("LINEAR_REDIRECT_URI")!,
            scopes: ["read", "write"]
        )
        
        // Set up Linear integration
        app.useLinear(with: linearConfig)
        
        // Your other routes and configuration
        // ...
        
        try await app.run()
    }
}
```

### Development Workflow

1. Make changes to the codebase
2. Run tests with `swift test`
3. Build the package with `swift build`
4. Use the library in your own projects

### Project Structure

The project consists of two main modules:

1. **LinearAPI**: Core functionality for interacting with the Linear API
   - Authentication services (OAuth)
   - GraphQL query execution
   - Model definitions

2. **LinearAPIVapor**: Server-side integration with Vapor
   - OAuth token storage and management
   - API controllers for proxying requests
   - Session management

### Recent Updates

- Added URLSession dependency injection to LinearClient for better testability
- Fixed issues with mock URLSession in tests
- Added comprehensive documentation
- Added SwiftUI integration for authentication flows
- Implemented both direct OAuth and server-side OAuth approaches

### Known Issues

- The LinearAPIVapor module needs further updates:
  - GraphQLResponse types need to conform to Encodable
  - Address issues with the AuthUserModel and authentication
  - Fix conformance to Sendable for thread safety
  - Add proper version availability annotations

### Development Workflow

1. Run tests for the LinearAPI module: `swift test --filter LinearAPITests`
2. For Vapor integration, ensure you have Vapor and Fluent dependencies installed
3. Build the full package with both modules: `swift build`

## Examples

### Vapor Example App

We've included a complete example Vapor application that demonstrates how to use the `LinearAPIVapor` module for server-side integration with Linear. The example app includes:

- OAuth authentication flow
- Server-side token management
- Example routes for accessing Linear data
- User authentication with Fluent
- Dashboard UI with Leaf templates

To run the example:

1. Navigate to the `Examples/VaporApp` directory
2. Set up your environment variables:
   ```
   export LINEAR_CLIENT_ID="your_client_id"
   export LINEAR_CLIENT_SECRET="your_client_secret" 
   export LINEAR_REDIRECT_URI="http://localhost:8080/linear/auth/callback"
   ```
3. Run the application:
   ```
   swift run
   ```
4. Access the application at http://localhost:8080

For more details, see the [Example App README](Examples/VaporApp/README.md). 
