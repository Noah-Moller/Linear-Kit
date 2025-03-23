import Foundation
import LinearAPI

/// Vapor-compatible GraphQL response that conforms to both Decodable and Encodable
public struct VaporGraphQLResponse<T: Codable>: Codable {
    /// The data returned by the API
    public let data: T?
    
    /// Any errors that occurred during the request
    public let errors: [VaporGraphQLError]?
    
    /// Check if the response contains errors
    public var hasErrors: Bool {
        return errors != nil && !(errors?.isEmpty ?? true)
    }
    
    /// Initialize from a LinearAPI GraphQLResponse
    public init(from linearResponse: GraphQLResponse<T>) {
        self.data = linearResponse.data
        
        if let errors = linearResponse.errors {
            self.errors = errors.map { VaporGraphQLError(from: $0) }
        } else {
            self.errors = nil
        }
    }
}

/// Vapor-compatible GraphQL error that conforms to both Decodable and Encodable
public struct VaporGraphQLError: Codable {
    /// The error message
    public let message: String
    
    /// The location of the error in the query
    public let locations: [VaporGraphQLErrorLocation]?
    
    /// The path to the field that caused the error
    public let path: [String]?
    
    /// Additional error details
    public let extensions: [String: String]?
    
    /// Initialize from a LinearAPI GraphQLError
    public init(from linearError: GraphQLError) {
        self.message = linearError.message
        
        if let locations = linearError.locations {
            self.locations = locations.map { VaporGraphQLErrorLocation(from: $0) }
        } else {
            self.locations = nil
        }
        
        self.path = linearError.path
        self.extensions = linearError.extensions
    }
}

/// Vapor-compatible GraphQLErrorLocation that conforms to both Decodable and Encodable
public struct VaporGraphQLErrorLocation: Codable {
    /// The line number where the error occurred
    public let line: Int
    
    /// The column number where the error occurred
    public let column: Int
    
    /// Initialize from a LinearAPI GraphQLErrorLocation
    public init(from linearLocation: GraphQLErrorLocation) {
        self.line = linearLocation.line
        self.column = linearLocation.column
    }
} 