import Foundation
import AuthenticationServices
import LinearAPI
import Combine

/// Configuration for the Linear OAuth application
struct LinearOAuthConfig {
    let clientId: String
    let clientSecret: String
    let redirectUri: String
    let scopes: [String]
}

/// Manager class for handling Linear OAuth authentication
class LinearAuthManager: NSObject, ObservableObject {
    // MARK: - Published properties
    
    /// Whether the user is authenticated
    @Published var isAuthenticated = false
    
    /// The current user profile
    @Published var currentUser: User?
    
    /// The current authentication session
    private var webAuthSession: ASWebAuthenticationSession?
    
    /// The auth service for handling token exchange
    private var authService: AuthService
    
    /// The Linear client
    private var linearClient: LinearClient?
    
    /// The app's configuration
    private let config: LinearOAuthConfig
    
    /// Token storage keys
    private let accessTokenKey = "com.linearoauthdemo.accessToken"
    private let refreshTokenKey = "com.linearoauthdemo.refreshToken"
    private let tokenExpiryKey = "com.linearoauthdemo.tokenExpiry"
    
    // MARK: - Initialization
    
    init(config: LinearOAuthConfig) {
        self.config = config
        self.authService = AuthService(
            clientId: config.clientId,
            clientSecret: config.clientSecret,
            redirectUri: config.redirectUri
        )
        
        super.init()
        
        // Check if we have a valid token
        if let accessToken = getAccessToken(), !accessToken.isEmpty {
            if isTokenExpired() {
                refreshToken()
            } else {
                setupClient(withToken: accessToken)
                loadCurrentUser()
            }
        }
    }
    
    // MARK: - Authentication methods
    
    /// Start the OAuth authentication flow
    /// - Parameter presentationContextProvider: The context provider for presenting the auth session
    func startAuthFlow(from presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
        // Generate a random state for CSRF protection
        let state = UUID().uuidString
        
        // Get the authorization URL
        let authURL = authService.getAuthorizationURL(
            scopes: config.scopes,
            state: state
        )
        
        // Create and start the authentication session
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: URL(string: config.redirectUri)?.scheme,
            completionHandler: { [weak self] callbackURL, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Authentication error: \(error.localizedDescription)")
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    print("No callback URL received")
                    return
                }
                
                // Parse the callback URL
                guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let queryItems = components.queryItems else {
                    print("Invalid callback URL structure")
                    return
                }
                
                // Verify state
                guard let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
                      returnedState == state else {
                    print("State mismatch - possible CSRF attack")
                    return
                }
                
                // Check for error
                if let error = queryItems.first(where: { $0.name == "error" })?.value {
                    print("Authentication error: \(error)")
                    return
                }
                
                // Get authorization code
                guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    print("No authorization code in response")
                    return
                }
                
                // Exchange code for token
                self.exchangeCodeForToken(code)
            }
        )
        
        webAuthSession?.presentationContextProvider = presentationContextProvider
        webAuthSession?.prefersEphemeralWebBrowserSession = false
        
        // Start the authentication session
        webAuthSession?.start()
    }
    
    /// Sign out the current user
    func signOut() {
        // Clear stored tokens
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        
        // Update state
        linearClient = nil
        isAuthenticated = false
        currentUser = nil
    }
    
    // MARK: - Token management
    
    /// Exchange an authorization code for access and refresh tokens
    /// - Parameter code: The authorization code from the callback
    private func exchangeCodeForToken(_ code: String) {
        authService.exchangeCodeForToken(code: code) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Save tokens
                    self.saveTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        expiresIn: response.expiresIn
                    )
                    
                    // Setup client and load user
                    self.setupClient(withToken: response.accessToken)
                    self.loadCurrentUser()
                    
                case .failure(let error):
                    print("Token exchange error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Refresh the access token using the refresh token
    private func refreshToken() {
        guard let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            // No refresh token, need to authenticate again
            isAuthenticated = false
            return
        }
        
        authService.refreshAccessToken(refreshToken: refreshToken) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Save new tokens
                    self.saveTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        expiresIn: response.expiresIn
                    )
                    
                    // Setup client with new token
                    self.setupClient(withToken: response.accessToken)
                    self.loadCurrentUser()
                    
                case .failure(let error):
                    print("Token refresh error: \(error.localizedDescription)")
                    // Token refresh failed, need to authenticate again
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    /// Save tokens to persistent storage
    /// - Parameters:
    ///   - accessToken: The access token
    ///   - refreshToken: The refresh token
    ///   - expiresIn: Token expiration time in seconds
    private func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        
        // Calculate expiry date
        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        UserDefaults.standard.set(expiryDate.timeIntervalSince1970, forKey: tokenExpiryKey)
    }
    
    /// Get the stored access token
    /// - Returns: The access token, or nil if not found
    private func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }
    
    /// Check if the token is expired
    /// - Returns: True if the token is expired or about to expire
    private func isTokenExpired() -> Bool {
        // Get the expiry timestamp
        let expiryTimestamp = UserDefaults.standard.double(forKey: tokenExpiryKey)
        if expiryTimestamp == 0 {
            return true
        }
        
        // Convert to date
        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        
        // Add a buffer (refresh 5 minutes before expiry)
        let bufferInterval: TimeInterval = 5 * 60
        
        // Check if current date is after (expiry date - buffer)
        return Date() > expiryDate.addingTimeInterval(-bufferInterval)
    }
    
    // MARK: - Client setup and data loading
    
    /// Set up the Linear client with the access token
    /// - Parameter token: The access token
    private func setupClient(withToken token: String) {
        linearClient = LinearClient(accessToken: token)
        isAuthenticated = true
    }
    
    /// Load the current user profile
    private func loadCurrentUser() {
        guard let client = linearClient else { return }
        
        client.users.getCurrentUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.currentUser = user
                case .failure(let error):
                    print("Error loading user: \(error)")
                }
            }
        }
    }
    
    // MARK: - API wrappers
    
    /// Get the user's teams
    /// - Parameter completion: Completion handler with the result
    func getTeams(completion: @escaping (Result<Connection<Team>, Error>) -> Void) {
        guard let client = linearClient else {
            completion(.failure(NSError(domain: "com.linearoauthdemo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])))
            return
        }
        
        client.teams.getTeams { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let teams):
                    completion(.success(teams))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Get the user's issues
    /// - Parameters:
    ///   - teamId: Optional team ID to filter issues
    ///   - completion: Completion handler with the result
    func getIssues(teamId: String? = nil, completion: @escaping (Result<Connection<Issue>, Error>) -> Void) {
        guard let client = linearClient else {
            completion(.failure(NSError(domain: "com.linearoauthdemo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])))
            return
        }
        
        client.issues.getIssues(teamId: teamId, pagination: PaginationInput(first: 10)) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let issues):
                    completion(.success(issues))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding on iOS
#if os(iOS)
import UIKit

/// Extension to make LinearAuthManager a presentation context provider on iOS
extension LinearAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}
#endif 