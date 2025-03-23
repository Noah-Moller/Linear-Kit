import Foundation

/// Represents a GraphQL response from the Linear API
public struct GraphQLResponse<T: Decodable>: Decodable {
    /// The data returned by the API
    public let data: T?
    
    /// Any errors that occurred during the request
    public let errors: [GraphQLError]?
    
    /// Check if the response contains errors
    public var hasErrors: Bool {
        return errors != nil && !(errors?.isEmpty ?? true)
    }
}

/// Represents an error in a GraphQL response
public struct GraphQLError: Decodable {
    /// The error message
    public let message: String
    
    /// The location of the error in the query
    public let locations: [GraphQLErrorLocation]?
    
    /// The path to the field that caused the error
    public let path: [String]?
    
    /// Additional error details
    public let extensions: [String: String]?
}

/// Represents the location of an error in a GraphQL query
public struct GraphQLErrorLocation: Decodable {
    /// The line number where the error occurred
    public let line: Int
    
    /// The column number where the error occurred
    public let column: Int
} 