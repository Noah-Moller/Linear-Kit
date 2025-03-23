import SwiftUI
import AuthenticationServices

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// Example SwiftUI app that demonstrates the Linear OAuth flow
@available(iOS 15.0, macOS 12.0, *)
public struct LinearOAuthExample: View {
    @StateObject private var viewModel = LinearOAuthViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isAuthenticated {
                    // Show user info
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            if let url = viewModel.user?.avatarUrl {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 60, height: 60)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(viewModel.user?.name ?? "")
                                    .font(.headline)
                                Text(viewModel.user?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        if let teams = viewModel.teams?.nodes, !teams.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Teams")
                                    .font(.headline)
                                
                                ForEach(teams) { team in
                                    HStack {
                                        Text(team.key)
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)
                                        
                                        Text(team.name)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        if let issues = viewModel.issues?.nodes, !issues.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Issues")
                                    .font(.headline)
                                
                                ForEach(issues) { issue in
                                    HStack {
                                        Text(issue.identifier)
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(4)
                                        
                                        Text(issue.title)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button("Sign Out") {
                            viewModel.signOut()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                } else {
                    // Show connect button
                    VStack {
                        Image(systemName: "checklist")
                            .font(.system(size: 70))
                            .padding()
                        
                        Text("Connect to Linear")
                            .font(.title)
                            .padding()
                        
                        Text("Sign in with your Linear account to view and manage your issues, teams, and projects.")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Connect Linear Account") {
                            viewModel.startOAuthFlow()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding()
                    }
                    .padding()
                }
            }
            .navigationTitle("Linear Integration")
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
class LinearOAuthViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    private var authService: AuthService!
    private var linearClient: LinearClient?
    private var webAuthSession: ASWebAuthenticationSession?
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var user: User?
    @Published var teams: Connection<Team>?
    @Published var issues: Connection<Issue>?
    
    override init() {
        super.init()
        
        // Initialize with your app's OAuth credentials
        authService = AuthService(
            clientId: "YOUR_CLIENT_ID",
            clientSecret: "YOUR_CLIENT_SECRET",
            redirectUri: "YOUR_APP_SCHEME://oauth-callback"
        )
        
        // Check for saved token
        if let savedTokenData = UserDefaults.standard.data(forKey: "linearAccessToken"),
           let savedToken = try? JSONDecoder().decode(TokenResponse.self, from: savedTokenData) {
            configureClientWithToken(savedToken.accessToken)
            loadUserData()
        }
    }
    
    func startOAuthFlow() {
        isLoading = true
        
        // Generate random state for security
        let state = UUID().uuidString
        
        // Create authorization URL with requested scopes
        let authURL = authService.getAuthorizationURL(
            scopes: ["read", "write", "issues:create"],
            state: state
        )
        
        // Launch web authentication session
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: URL(string: authService.redirectUri)?.scheme,
            completionHandler: { [weak self] callbackURL, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.showError(message: "Authentication failed: \(error.localizedDescription)")
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let queryItems = components.queryItems else {
                    self.showError(message: "Invalid response from Linear")
                    return
                }
                
                // Verify state parameter
                guard let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
                      returnedState == state else {
                    self.showError(message: "State verification failed")
                    return
                }
                
                // Check for error
                if let error = queryItems.first(where: { $0.name == "error" })?.value {
                    self.showError(message: "Authorization error: \(error)")
                    return
                }
                
                // Extract authorization code
                guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    self.showError(message: "No authorization code received")
                    return
                }
                
                // Exchange code for token
                self.exchangeCodeForToken(code)
            }
        )
        
        webAuthSession?.presentationContextProvider = self
        webAuthSession?.prefersEphemeralWebBrowserSession = false
        webAuthSession?.start()
    }
    
    func exchangeCodeForToken(_ code: String) {
        isLoading = true
        
        authService.exchangeCodeForToken(code: code) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let tokenResponse):
                    // Save token response
                    if let tokenData = try? JSONEncoder().encode(tokenResponse) {
                        UserDefaults.standard.set(tokenData, forKey: "linearAccessToken")
                    }
                    
                    // Configure client with token
                    self.configureClientWithToken(tokenResponse.accessToken)
                    self.loadUserData()
                    
                case .failure(let error):
                    self.showError(message: "Token exchange failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func configureClientWithToken(_ token: String) {
        linearClient = LinearClient(accessToken: token)
        isAuthenticated = true
    }
    
    func loadUserData() {
        guard let client = linearClient else { return }
        isLoading = true
        
        // Get current user
        client.users.getCurrentUser { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self.user = user
                    
                    // Load teams
                    self.loadTeams()
                    
                case .failure(let error):
                    self.isLoading = false
                    self.showError(message: "Failed to load user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadTeams() {
        guard let client = linearClient else { return }
        
        client.teams.getTeams { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let teams):
                    self.teams = teams
                    
                    // Load issues after teams
                    self.loadIssues()
                    
                case .failure(let error):
                    self.isLoading = false
                    self.showError(message: "Failed to load teams: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadIssues() {
        guard let client = linearClient else { return }
        
        client.issues.getIssues(pagination: PaginationInput(first: 10)) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let issues):
                    self.issues = issues
                    
                case .failure(let error):
                    self.showError(message: "Failed to load issues: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "linearAccessToken")
        linearClient = nil
        isAuthenticated = false
        user = nil
        teams = nil
        issues = nil
    }
    
    func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // ASWebAuthenticationPresentationContextProviding
    #if os(iOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first ?? ASPresentationAnchor()
    }
    #elseif os(macOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
    #endif
} 