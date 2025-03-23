import Foundation
import AuthenticationServices
#if canImport(SwiftUI)
import SwiftUI
#endif

/// A client for interacting with a server that has LinearAPIVapor integrated
@available(iOS 13.0, macOS 10.15, *)
public class LinearServerClient: ObservableObject {
    /// The base URL of the server
    private let serverURL: URL
    
    /// The URL session for making requests
    private let urlSession: URLSession
    
    /// The authentication session for OAuth
    private var webAuthSession: ASWebAuthenticationSession?
    
    /// Whether the client is authenticated
    @Published public private(set) var isAuthenticated = false
    
    /// Whether authentication is in progress
    @Published public private(set) var isAuthenticating = false
    
    /// Any error that occurred during authentication
    @Published public private(set) var authError: Error?
    
    /// Access token for authenticating requests
    private var accessToken: String?
    
    /// Initializes a new LinearServerClient
    /// - Parameter serverURL: The base URL of the server
    public init(serverURL: URL) {
        self.serverURL = serverURL
        
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.urlSession = URLSession(configuration: config)
        
        // Check for saved token
        if let token = UserDefaults.standard.string(forKey: "linearServerAccessToken") {
            self.accessToken = token
            self.isAuthenticated = true
        }
    }
    
    /// Starts the OAuth authentication flow
    /// - Parameter presentationContextProvider: A provider for the presentation context
    public func authenticate(from presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
        // Clear any previous errors
        authError = nil
        isAuthenticating = true
        
        // Create the authorization URL
        let authURL = serverURL.appendingPathComponent("linear/auth/login")
        
        // Create the authentication session
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "linearapp", // This should match your app's registered URL scheme
            completionHandler: { [weak self] callbackURL, error in
                guard let self = self else { return }
                
                // Reset authentication state
                self.isAuthenticating = false
                
                if let error = error {
                    self.authError = error
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let queryItems = components.queryItems else {
                    self.authError = NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid callback URL"])
                    return
                }
                
                // Check for error
                if let error = queryItems.first(where: { $0.name == "error" })?.value {
                    self.authError = NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication error: \(error)"])
                    return
                }
                
                // Extract token (in a real implementation, you would get this from your server)
                if let token = queryItems.first(where: { $0.name == "token" })?.value {
                    // Save the token
                    UserDefaults.standard.set(token, forKey: "linearServerAccessToken")
                    self.accessToken = token
                    self.isAuthenticated = true
                } else {
                    // If no token is provided in the callback URL, the server has stored the token
                    // and we just need to mark the client as authenticated
                    self.isAuthenticated = true
                }
            }
        )
        
        // Set the presentation context provider
        webAuthSession?.presentationContextProvider = presentationContextProvider
        webAuthSession?.prefersEphemeralWebBrowserSession = false
        
        // Start the authentication session
        webAuthSession?.start()
    }
    
    /// Signs out of the Linear account
    public func signOut() {
        // Clear the stored token
        UserDefaults.standard.removeObject(forKey: "linearServerAccessToken")
        accessToken = nil
        isAuthenticated = false
        
        // Revoke the token on the server
        var request = URLRequest(url: serverURL.appendingPathComponent("linear/auth/revoke"))
        request.httpMethod = "POST"
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Make the request
        urlSession.dataTask(with: request) { _, _, _ in
            // We don't care about the response, we're signing out regardless
        }.resume()
    }
    
    /// Executes a GraphQL query on the server
    /// - Parameters:
    ///   - query: The GraphQL query or mutation string
    ///   - variables: Optional variables to include in the request
    ///   - completion: Completion handler with Result containing either the response data or an error
    public func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        completion: @escaping @Sendable (Result<T, Error>) -> Void
    ) {
        var request = URLRequest(url: serverURL.appendingPathComponent("linear/api/graphql"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables ?? [:]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Gets information about the current user
    /// - Parameter completion: Completion handler with Result containing either the user or an error
    public func getCurrentUser(completion: @escaping @Sendable (Result<User, Error>) -> Void) {
        var request = URLRequest(url: serverURL.appendingPathComponent("linear/api/me"))
        request.httpMethod = "GET"
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(GraphQLResponse<ViewerResponse>.self, from: data)
                
                if let user = result.data?.viewer {
                    completion(.success(user))
                } else if let errors = result.errors, !errors.isEmpty {
                    let errorMessage = errors.map { $0.message }.joined(separator: ", ")
                    completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                } else {
                    completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user data returned"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Gets the user's teams
    /// - Parameter completion: Completion handler with Result containing either the teams or an error
    public func getTeams(completion: @escaping @Sendable (Result<Connection<Team>, Error>) -> Void) {
        var request = URLRequest(url: serverURL.appendingPathComponent("linear/api/teams"))
        request.httpMethod = "GET"
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(Connection<Team>.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Gets the user's issues
    /// - Parameters:
    ///   - teamId: Optional team ID to filter issues
    ///   - pagination: Optional pagination parameters
    ///   - completion: Completion handler with Result containing either the issues or an error
    public func getIssues(
        teamId: String? = nil,
        pagination: PaginationInput = PaginationInput(first: 50),
        completion: @escaping @Sendable (Result<Connection<Issue>, Error>) -> Void
    ) {
        var components = URLComponents(url: serverURL.appendingPathComponent("linear/api/issues"), resolvingAgainstBaseURL: true)!
        var queryItems = [URLQueryItem]()
        
        if let teamId = teamId {
            queryItems.append(URLQueryItem(name: "teamId", value: teamId))
        }
        
        if let first = pagination.first {
            queryItems.append(URLQueryItem(name: "first", value: String(first)))
        }
        
        if let after = pagination.after {
            queryItems.append(URLQueryItem(name: "after", value: after))
        }
        
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(Connection<Issue>.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Execute a GraphQL query with async/await
    /// - Parameters:
    ///   - query: The GraphQL query or mutation string
    ///   - variables: Optional variables to include in the request
    /// - Returns: The decoded response
    /// - Throws: An error if the request fails
    @available(iOS 15.0, macOS 12.0, *)
    public func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil
    ) async throws -> T {
        var request = URLRequest(url: serverURL.appendingPathComponent("linear/api/graphql"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables ?? [:]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Gets the current user with async/await
    /// - Returns: The current user
    /// - Throws: An error if the request fails
    @available(iOS 15.0, macOS 12.0, *)
    public func getCurrentUser() async throws -> User {
        var request = URLRequest(url: serverURL.appendingPathComponent("linear/api/me"))
        request.httpMethod = "GET"
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        let result = try JSONDecoder().decode(GraphQLResponse<ViewerResponse>.self, from: data)
        
        if let user = result.data?.viewer {
            return user
        } else if let errors = result.errors, !errors.isEmpty {
            let errorMessage = errors.map { $0.message }.joined(separator: ", ")
            throw NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        } else {
            throw NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user data returned"])
        }
    }
    
    /// Gets the user's teams with async/await
    /// - Returns: The user's teams
    /// - Throws: An error if the request fails
    @available(iOS 15.0, macOS 12.0, *)
    public func getTeams() async throws -> Connection<Team> {
        var request = URLRequest(url: serverURL.appendingPathComponent("linear/api/teams"))
        request.httpMethod = "GET"
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(Connection<Team>.self, from: data)
    }
    
    /// Gets the user's issues with async/await
    /// - Parameters:
    ///   - teamId: Optional team ID to filter issues
    ///   - pagination: Optional pagination parameters
    /// - Returns: The user's issues
    /// - Throws: An error if the request fails
    @available(iOS 15.0, macOS 12.0, *)
    public func getIssues(
        teamId: String? = nil,
        pagination: PaginationInput = PaginationInput(first: 50)
    ) async throws -> Connection<Issue> {
        var components = URLComponents(url: serverURL.appendingPathComponent("linear/api/issues"), resolvingAgainstBaseURL: true)!
        var queryItems = [URLQueryItem]()
        
        if let teamId = teamId {
            queryItems.append(URLQueryItem(name: "teamId", value: teamId))
        }
        
        if let first = pagination.first {
            queryItems.append(URLQueryItem(name: "first", value: String(first)))
        }
        
        if let after = pagination.after {
            queryItems.append(URLQueryItem(name: "after", value: after))
        }
        
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        // Add authorization header if we have a token
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        return try JSONDecoder().decode(Connection<Issue>.self, from: data)
    }
}

/// Response type for the viewer query
private struct ViewerResponse: Decodable {
    let viewer: User
} 