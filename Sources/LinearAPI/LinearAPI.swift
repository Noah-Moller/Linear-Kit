// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Logging

/// A client for interacting with the Linear API
@available(iOS 13.0, macOS 10.15, *)
public class LinearClient: @unchecked Sendable {
    /// The base URL for Linear API
    private let baseURL = URL(string: "https://api.linear.app/graphql")!
    
    /// Authentication
    public let apiToken: String?
    public let accessToken: String?
    
    /// URLSession for making network requests
    private let urlSession: URLSession
    
    /// Logger for tracking operations
    private let logger = Logger(label: "com.linearapi.client")
    
    /// Services
    public lazy var teams: TeamService = {
        return TeamService(client: self)
    }()
    
    public lazy var issues: IssueService = {
        return IssueService(client: self)
    }()
    
    public lazy var users: UserService = {
        return UserService(client: self)
    }()
    
    /// Internal
    private let jsonDecoder: JSONDecoder
    
    /// A single shared JSON encoder to reuse
    private let jsonEncoder = JSONEncoder()
    
    /// Initialize with API token authentication
    /// - Parameters:
    ///   - apiToken: Linear API token
    ///   - session: The URLSession to use, or nil to create a default one
    public init(apiToken: String, session: URLSession? = nil) {
        self.apiToken = apiToken
        self.accessToken = nil
        
        // Use provided session or create default one
        if let session = session {
            self.urlSession = session
        } else {
            // Configure URL session
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            self.urlSession = URLSession(configuration: config)
        }
        
        // Configure JSON decoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)
            
            // Create the formatters locally for thread safety
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: stringValue) {
                return date
            }
            
            // Try without fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = .withInternetDateTime
            
            if let date = fallbackFormatter.date(from: stringValue) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(stringValue)"
            )
        }
        self.jsonDecoder = decoder
        
        print("LinearClient initialized with API token")
    }
    
    /// Initialize with OAuth token authentication
    /// - Parameters:
    ///   - accessToken: OAuth access token
    ///   - session: The URLSession to use, or nil to create a default one
    public init(accessToken: String, session: URLSession? = nil) {
        self.apiToken = nil
        self.accessToken = accessToken
        
        // Use provided session or create default one
        if let session = session {
            self.urlSession = session
        } else {
            // Configure URL session
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            self.urlSession = URLSession(configuration: config)
        }
        
        // Configure JSON decoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)
            
            // Create the formatters locally for thread safety
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: stringValue) {
                return date
            }
            
            // Try without fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = .withInternetDateTime
            
            if let date = fallbackFormatter.date(from: stringValue) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(stringValue)"
            )
        }
        self.jsonDecoder = decoder
        
        print("LinearClient initialized with OAuth access token")
    }
    
    /// Execute a GraphQL query or mutation
    /// - Parameters:
    ///   - query: The GraphQL query or mutation string
    ///   - variables: Optional variables to include in the request
    ///   - completion: Completion handler with Result containing either the response data or an error
    public func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        completion: @escaping @Sendable (Result<T, LinearAPIError>) -> Void
    ) {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header based on available token
        if let apiToken = apiToken {
            request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        } else if let accessToken = accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let body: [String: Any] = [
            "query": query,
            "variables": variables ?? [:]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            logger.error("Failed to serialize request body: \(error)")
            completion(.failure(.encodingError))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Network error: \(error)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.logger.error("HTTP error: \(httpResponse.statusCode)")
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                self.logger.error("No data received")
                completion(.failure(.noData))
                return
            }
            
            do {
                let result = try self.jsonDecoder.decode(T.self, from: data)
                completion(.success(result))
            } catch {
                self.logger.error("Decoding error: \(error)")
                completion(.failure(.decodingError(error)))
            }
        }
        
        task.resume()
    }
    
    /// Execute a GraphQL query or mutation with async/await pattern
    /// - Parameters:
    ///   - query: The GraphQL query or mutation string
    ///   - variables: Optional variables to include in the request
    /// - Returns: The decoded response
    /// - Throws: LinearAPIError if the request fails
    @available(iOS 15.0, macOS 12.0, *)
    public func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil
    ) async throws -> T where T: Sendable {
        return try await withCheckedThrowingContinuation { continuation in
            // Create a completion handler that's @Sendable
            let completion: @Sendable (Result<T, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    // Create a local copy to avoid data races
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            // Execute the query with our @Sendable completion handler
            execute(query: query, variables: variables, completion: completion)
        }
    }
    
    // MARK: - Static Properties for Thread Safety
    
    /// ISO8601 date formatter with fractional seconds
    @available(iOS 13.0, macOS 10.15, *)
    @MainActor
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Fallback ISO8601 date formatter without fractional seconds
    @available(iOS 13.0, macOS 10.15, *)
    @MainActor
    private static let fallbackFormatter: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
}

/// Errors that can occur when using the Linear API
@available(iOS 13.0, macOS 10.15, *)
public enum LinearAPIError: Error, Sendable {
    case networkError(Error)
    case httpError(Int)
    case noData
    case decodingError(Error)
    case encodingError
    case invalidResponse
    case graphQLError(String)
    case unknown
}

// Helper extension for describing the errors
extension LinearAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error with status code: \(code)"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from server"
        case .graphQLError(let message):
            return "GraphQL error: \(message)"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}
