import Foundation

/// Service for handling Linear OAuth authentication
@available(iOS 13.0, macOS 10.15, *)
public class AuthService {
    /// The client ID from your Linear OAuth application
    public let clientId: String
    
    /// The client secret from your Linear OAuth application
    public let clientSecret: String
    
    /// The redirect URI registered with your Linear OAuth application
    public let redirectUri: String
    
    /// The base URL for Linear's authentication API
    private let authBaseURL = "https://linear.app/oauth"
    
    /// Initializes a new AuthService with the provided OAuth credentials
    /// - Parameters:
    ///   - clientId: The client ID from your Linear OAuth application
    ///   - clientSecret: The client secret from your Linear OAuth application
    ///   - redirectUri: The redirect URI registered with your Linear OAuth application
    public init(clientId: String, clientSecret: String, redirectUri: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
    }
    
    /// Creates the authorization URL for initiating the OAuth flow
    /// - Parameters:
    ///   - scopes: The permissions to request from the user
    ///   - state: A random string to protect against CSRF attacks
    ///   - actor: The authentication actor (user or application)
    /// - Returns: The authorization URL to redirect the user to
    public func getAuthorizationURL(scopes: [String], state: String, actor: String = "user") -> URL {
        var components = URLComponents(string: "\(authBaseURL)/authorize")!
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "actor", value: actor)
        ]
        
        return components.url!
    }
    
    /// Exchanges an authorization code for an access token
    /// - Parameters:
    ///   - code: The authorization code received from the redirect
    ///   - completion: A callback that will be called with the result
    public func exchangeCodeForToken(code: String, completion: @escaping @Sendable (Result<TokenResponse, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "\(authBaseURL)/token")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create form-urlencoded body
        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        // Convert parameters to form-urlencoded format
        let formBody = parameters.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        
        request.httpBody = formBody.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                completion(.success(tokenResponse))
            } catch {
                // Try to extract error message from response
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorJson["error_description"] as? String ?? errorJson["error"] as? String {
                    completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                } else {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Refreshes an access token using a refresh token
    /// - Parameters:
    ///   - refreshToken: The refresh token to use
    ///   - completion: A callback that will be called with the result
    public func refreshAccessToken(refreshToken: String, completion: @escaping @Sendable (Result<TokenResponse, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "\(authBaseURL)/token")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create form-urlencoded body
        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        // Convert parameters to form-urlencoded format
        let formBody = parameters.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        
        request.httpBody = formBody.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                completion(.success(tokenResponse))
            } catch {
                // Try to extract error message from response
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorJson["error_description"] as? String ?? errorJson["error"] as? String {
                    completion(.failure(NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                } else {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Revokes an access token
    /// - Parameters:
    ///   - accessToken: The access token to revoke
    ///   - completion: A callback that will be called with the result
    public func revokeToken(accessToken: String, completion: @escaping @Sendable (Bool, Error?) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.linear.app/oauth/revoke")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    completion(true, nil)
                case 400:
                    completion(false, NSError(domain: "com.linearapi", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unable to revoke token (may already be revoked)"]))
                case 401:
                    completion(false, NSError(domain: "com.linearapi", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unable to authenticate with the token"]))
                default:
                    completion(false, NSError(domain: "com.linearapi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                }
            } else {
                completion(false, NSError(domain: "com.linearapi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
        }.resume()
    }
    
    /// Exchanges an authorization code for an access token using async/await
    /// - Parameter code: The authorization code received from the redirect
    /// - Returns: A token response containing access and refresh tokens
    /// - Throws: An error if the exchange fails
    @available(iOS 15.0, macOS 12.0, *)
    public func exchangeCodeForToken(code: String) async throws -> TokenResponse {
        return try await withCheckedThrowingContinuation { continuation in
            exchangeCodeForToken(code: code) { result in
                switch result {
                case .success(let tokenResponse):
                    continuation.resume(returning: tokenResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Refreshes an access token using a refresh token with async/await
    /// - Parameter refreshToken: The refresh token to use
    /// - Returns: A token response containing the new access and refresh tokens
    /// - Throws: An error if the refresh fails
    @available(iOS 15.0, macOS 12.0, *)
    public func refreshAccessToken(refreshToken: String) async throws -> TokenResponse {
        return try await withCheckedThrowingContinuation { continuation in
            refreshAccessToken(refreshToken: refreshToken) { result in
                switch result {
                case .success(let tokenResponse):
                    continuation.resume(returning: tokenResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Revokes an access token using async/await
    /// - Parameter accessToken: The access token to revoke
    /// - Returns: Whether the revocation was successful
    /// - Throws: An error if the revocation fails
    @available(iOS 15.0, macOS 12.0, *)
    public func revokeToken(accessToken: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            revokeToken(accessToken: accessToken) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
} 