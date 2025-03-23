# LinearKit Usage Guide

This guide provides instructions for integrating and using the LinearKit package in your Swift applications, covering both direct OAuth and server-side implementations.

## Table of Contents

1. [Installation](#installation)
2. [Direct OAuth Implementation](#direct-oauth-implementation)
3. [Server-Side OAuth Implementation](#server-side-oauth-implementation)
4. [GraphQL API Usage](#graphql-api-usage)
5. [Advanced Features](#advanced-features)

## Installation

### Swift Package Manager

Add the LinearAPI package to your Swift project:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/LinearAPI.git", from: "1.0.0")
]
```

For iOS/macOS applications:

```swift
.target(
    name: "YourApp",
    dependencies: ["LinearAPI"]
)
```

For server-side applications:

```swift
.target(
    name: "YourServer",
    dependencies: ["LinearAPIVapor"]
)
```

## Direct OAuth Implementation

### 1. Set Up Linear OAuth Application

1. Create a Linear OAuth application in your workspace (Settings > API > OAuth applications)
2. Set up your redirect URL (e.g., `myapp://oauth-callback`)
3. Note your Client ID and Client Secret

### 2. Configure URL Scheme

Add to your Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

In your AppDelegate or SceneDelegate:

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    // Handle the callback URL
    NotificationCenter.default.post(name: .linearAuthCallback, object: url)
}
```

### 3. Implement the Authentication Flow

```swift
import SwiftUI
import LinearAPI
import AuthenticationServices

class LinearAuthViewModel: ObservableObject {
    private let authService: AuthService
    private let authManager: AuthManager
    private var webAuthSession: ASWebAuthenticationSession?
    
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var error: Error?
    
    init() {
        self.authService = AuthService(
            clientId: "your_client_id", 
            clientSecret: "your_client_secret",
            redirectUri: "myapp://oauth-callback"
        )
        
        self.authManager = AuthManager(
            clientId: "your_client_id", 
            clientSecret: "your_client_secret",
            redirectUri: "myapp://oauth-callback"
        )
        
        // Check if we're already authenticated
        self.isAuthenticated = authManager.isAuthenticated
        
        // Set up notification observer for callback URL
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthCallback),
            name: .linearAuthCallback,
            object: nil
        )
    }
    
    func startAuth(from window: ASPresentationAnchor, asApplication: Bool = false) {
        isAuthenticating = true
        error = nil
        
        // Generate random state
        let state = UUID().uuidString
        
        // Create authorization URL
        let authURL = authService.getAuthorizationURL(
            scopes: ["read", "write", "issues:create"],
            state: state,
            actor: asApplication ? "application" : "user"
        )
        
        // Create web authentication session
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: URL(string: "myapp://oauth-callback")?.scheme,
            completionHandler: { [weak self] callbackURL, error in
                guard let self = self else { return }
                self.isAuthenticating = false
                
                if let error = error {
                    self.error = error
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    self.error = NSError(domain: "LinearAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "No callback URL received"])
                    return
                }
                
                self.processCallback(url: callbackURL, expectedState: state)
            }
        )
        
        webAuthSession?.presentationContextProvider = self
        webAuthSession?.prefersEphemeralWebBrowserSession = true
        webAuthSession?.start()
    }
    
    @objc private func handleAuthCallback(notification: Notification) {
        guard let url = notification.object as? URL else { return }
        processCallback(url: url)
    }
    
    private func processCallback(url: URL, expectedState: String? = nil) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            self.error = NSError(domain: "LinearAuth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid callback URL"])
            return
        }
        
        // Check for error
        if let errorMessage = queryItems.first(where: { $0.name == "error" })?.value {
            self.error = NSError(domain: "LinearAuth", code: 3, userInfo: [NSLocalizedDescriptionKey: "Authentication error: \(errorMessage)"])
            return
        }
        
        // Verify state if provided
        if let expectedState = expectedState,
           let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
           returnedState != expectedState {
            self.error = NSError(domain: "LinearAuth", code: 4, userInfo: [NSLocalizedDescriptionKey: "State verification failed"])
            return
        }
        
        // Extract code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            self.error = NSError(domain: "LinearAuth", code: 5, userInfo: [NSLocalizedDescriptionKey: "No authorization code in callback"])
            return
        }
        
        // Exchange code for token
        isAuthenticating = true
        authService.exchangeCodeForToken(code: code) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isAuthenticating = false
                
                switch result {
                case .success(let tokenResponse):
                    // Save tokens
                    self.authManager.saveTokens(tokenResponse)
                    self.isAuthenticated = true
                    
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }
    
    func signOut() {
        // Get the current access token
        if let accessToken = authManager.getAccessToken() {
            // Revoke the token
            authService.revokeToken(accessToken: accessToken) { [weak self] success, error in
                // Clear tokens regardless of revocation success
                self?.authManager.clearTokens()
                
                DispatchQueue.main.async {
                    self?.isAuthenticated = false
                }
            }
        } else {
            authManager.clearTokens()
            isAuthenticated = false
        }
    }
    
    // Get a valid token to use with the API
    func getValidToken(completion: @escaping (Result<String, Error>) -> Void) {
        authManager.refreshTokenIfNeeded(completion: completion)
    }
}

extension LinearAuthViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return your window here
        return ASPresentationAnchor()
    }
}

extension Notification.Name {
    static let linearAuthCallback = Notification.Name("LinearAuthCallback")
}
```

### 4. Create Auth UI

```swift
import SwiftUI

struct LinearAuthView: View {
    @StateObject private var viewModel = LinearAuthViewModel()
    @Environment(\.window) private var window
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Connect to Linear")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Authorize this app to access your Linear account.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if viewModel.isAuthenticating {
                ProgressView()
                    .padding()
            } else if viewModel.isAuthenticated {
                VStack(spacing: 16) {
                    Text("Successfully connected to Linear!")
                        .foregroundColor(.green)
                    
                    Button(action: {
                        viewModel.signOut()
                    }) {
                        Text("Disconnect")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            } else {
                Button(action: {
                    viewModel.startAuth(from: window ?? ASPresentationAnchor())
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Connect Linear Account")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    viewModel.startAuth(from: window ?? ASPresentationAnchor(), asApplication: true)
                }) {
                    HStack {
                        Image(systemName: "app.fill")
                        Text("Connect as Application")
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
    }
}
```

### 5. Using the Linear API after Authentication

```swift
func fetchCurrentUser() {
    viewModel.getValidToken { result in
        switch result {
        case .success(let accessToken):
            let client = LinearClient(accessToken: accessToken)
            
            client.users.getCurrentUser { result in
                switch result {
                case .success(let user):
                    print("User: \(user.name)")
                case .failure(let error):
                    print("Error fetching user: \(error)")
                }
            }
            
        case .failure(let error):
            print("Token error: \(error)")
        }
    }
}
```

## Server-Side OAuth Implementation

### 1. Configure Server Application

```swift
import Vapor
import Fluent
import FluentSQLiteDriver
import LinearAPIVapor

// Configure your Vapor application
public func configure(_ app: Application) throws {
    // Configure database
    app.databases.use(.sqlite(.file("linear.sqlite")), as: .sqlite)
    
    // Configure sessions (required for LinearAPIVapor)
    app.middleware.use(app.sessions.middleware)
    
    // Configure Linear OAuth
    try app.configureLinearAPI(
        clientId: Environment.get("LINEAR_CLIENT_ID") ?? "your_client_id",
        clientSecret: Environment.get("LINEAR_CLIENT_SECRET") ?? "your_client_secret",
        redirectUri: Environment.get("LINEAR_REDIRECT_URI") ?? "https://yourapp.com/linear/auth/callback",
        scopes: ["read", "write", "issues:create"]
    )
    
    // Run migrations (includes LinearToken model)
    try app.autoMigrate().wait()
    
    // Configure routes (LinearAPIVapor registers its own routes)
    try routes(app)
}
```

### 2. Create Custom API Routes

```swift
func routes(_ app: Application) throws {
    // Custom API routes
    app.get("api", "user", "issues") { req -> EventLoopFuture<[Issue]> in
        guard let userId = try? req.session.get("linearUser") as? String else {
            throw Abort(.unauthorized)
        }
        
        return req.application.linear.getClientForUser(userId, on: req.eventLoop).flatMap { client in
            return client.issues.getIssues().map { connection in
                return connection.nodes
            }
        }
    }
    
    // Create a new issue
    app.post("api", "issues") { req -> EventLoopFuture<HTTPStatus> in
        guard let userId = try? req.session.get("linearUser") as? String else {
            throw Abort(.unauthorized)
        }
        
        let data = try req.content.decode(CreateIssueInput.self)
        
        return req.application.linear.getClientForUser(userId, on: req.eventLoop).flatMap { client in
            return client.issues.createIssue(input: data).map { _ in
                return .created
            }
        }
    }
}
```

### 3. Client-Side Implementation

```swift
import SwiftUI
import LinearAPI

struct ContentView: View {
    @StateObject private var linearClient = LinearServerClient(
        serverURL: URL(string: "https://yourapp.com")!
    )
    
    private let contextProvider = PresentationContextProvider()
    
    var body: some View {
        NavigationView {
            if linearClient.isAuthenticated {
                LinearDashboardView(client: linearClient)
            } else {
                LinearServerLoginView(
                    client: linearClient,
                    contextProvider: contextProvider
                )
            }
        }
    }
}

struct LinearDashboardView: View {
    @ObservedObject var client: LinearServerClient
    @State private var issues: [Issue] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else {
                ForEach(issues, id: \.id) { issue in
                    VStack(alignment: .leading) {
                        Text(issue.title)
                            .font(.headline)
                        Text(issue.state.name)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("My Issues")
        .toolbar {
            Button("Sign Out") {
                client.signOut()
            }
        }
        .onAppear {
            loadIssues()
        }
    }
    
    private func loadIssues() {
        client.getIssues { result in
            isLoading = false
            
            switch result {
            case .success(let issues):
                self.issues = issues
            case .failure(let error):
                self.error = error
            }
        }
    }
}
```

## GraphQL API Usage

### Fetching Data

```swift
// Get all teams
linearClient.teams.getTeams { result in
    switch result {
    case .success(let connection):
        for team in connection.nodes {
            print("Team: \(team.name) (\(team.key))")
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}

// Get issues for a team
linearClient.issues.getIssues(teamId: "TEAM_ID") { result in
    switch result {
    case .success(let connection):
        for issue in connection.nodes {
            print("Issue: \(issue.title) (\(issue.state.name))")
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Creating and Updating Data

```swift
// Create a new issue
let newIssue = CreateIssueInput(
    title: "Fix login bug",
    teamId: "TEAM_ID",
    description: "Users are unable to log in when using Safari",
    priority: 2
)

linearClient.issues.createIssue(input: newIssue) { result in
    switch result {
    case .success(let issue):
        print("Created issue: \(issue.id)")
    case .failure(let error):
        print("Error: \(error)")
    }
}

// Update an issue
let updateInput = UpdateIssueInput(
    id: "ISSUE_ID",
    title: "Fixed login bug",
    stateId: "STATE_ID"
)

linearClient.issues.updateIssue(input: updateInput) { result in
    switch result {
    case .success(let issue):
        print("Updated issue: \(issue.title)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Using Pagination

```swift
func fetchAllIssues(teamId: String) {
    var allIssues: [Issue] = []
    fetchIssuesPage(teamId: teamId, after: nil, allIssues: &allIssues)
}

func fetchIssuesPage(teamId: String, after: String?, allIssues: inout [Issue]) {
    let pagination = PaginationInput(first: 50, after: after)
    
    linearClient.issues.getIssues(teamId: teamId, pagination: pagination) { result in
        switch result {
        case .success(let connection):
            allIssues.append(contentsOf: connection.nodes)
            
            if connection.pageInfo.hasNextPage, let endCursor = connection.pageInfo.endCursor {
                fetchIssuesPage(teamId: teamId, after: endCursor, allIssues: &allIssues)
            } else {
                // All issues fetched
                print("Fetched \(allIssues.count) issues")
            }
            
        case .failure(let error):
            print("Error: \(error)")
        }
    }
}
```

## Advanced Features

### Actor Authorization

Linear supports authenticating as either a user or an application:

```swift
// User authentication (default)
let authURL = authService.getAuthorizationURL(
    scopes: ["read", "write"],
    state: "random-state-string",
    actor: "user"
)

// Application authentication
let authURL = authService.getAuthorizationURL(
    scopes: ["read", "write"],
    state: "random-state-string",
    actor: "application"
)
```

### Custom GraphQL Queries

You can execute custom GraphQL queries for more advanced use cases:

```swift
let query = """
query {
  issues(
    filter: {
      team: { id: { eq: "TEAM_ID" } }
      state: { name: { eq: "In Progress" } }
      assignee: { id: { eq: "USER_ID" } }
    }
    orderBy: updatedAt
    first: 10
  ) {
    nodes {
      id
      title
      description
      createdAt
      state {
        name
        color
      }
      priority
      assignee {
        id
        name
        displayName
      }
    }
  }
}
"""

linearClient.execute(query: query) { (result: Result<GraphQLResponse<IssuesResponse>, Error>) in
    switch result {
    case .success(let response):
        if let issues = response.data?.issues.nodes {
            for issue in issues {
                print("Issue: \(issue.title)")
            }
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}

struct IssuesResponse: Decodable {
    struct IssuesConnection: Decodable {
        let nodes: [Issue]
    }
    
    let issues: IssuesConnection
}
```

### Async/Await Support (iOS 15+, macOS 12+)

```swift
// Using async/await
func fetchUser() async {
    do {
        let accessToken = try await authManager.refreshTokenIfNeeded()
        let client = LinearClient(accessToken: accessToken)
        
        let user = try await client.users.getCurrentUser()
        print("User: \(user.name)")
        
        let issues = try await client.issues.getIssues()
        for issue in issues.nodes {
            print("Issue: \(issue.title)")
        }
    } catch {
        print("Error: \(error)")
    }
}
``` 
