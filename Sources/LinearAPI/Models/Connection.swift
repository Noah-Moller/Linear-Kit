import Foundation

/// A connection of nodes with pagination information
@available(iOS 13.0, macOS 10.15, *)
public struct Connection<T: Codable & Identifiable & Sendable>: Codable, Sendable {
    /// The nodes in the connection
    public let nodes: [T]
    
    /// Pagination information
    public let pageInfo: PageInfo
    
    /// Initialize a new connection
    /// - Parameters:
    ///   - nodes: The nodes in the connection
    ///   - pageInfo: Pagination information
    public init(nodes: [T], pageInfo: PageInfo) {
        self.nodes = nodes
        self.pageInfo = pageInfo
    }
}

/// Pagination information for a connection
@available(iOS 13.0, macOS 10.15, *)
public struct PageInfo: Codable, Sendable {
    /// Whether there are more results after this page
    public let hasNextPage: Bool
    
    /// Whether there are more results before this page
    public let hasPreviousPage: Bool
    
    /// The cursor pointing to the first result in this page
    public let startCursor: String?
    
    /// The cursor pointing to the last result in this page
    public let endCursor: String?
    
    /// Initialize new pagination information
    /// - Parameters:
    ///   - hasNextPage: Whether there are more results after this page
    ///   - hasPreviousPage: Whether there are more results before this page
    ///   - startCursor: The cursor pointing to the first result in this page
    ///   - endCursor: The cursor pointing to the last result in this page
    public init(hasNextPage: Bool, hasPreviousPage: Bool, startCursor: String?, endCursor: String?) {
        self.hasNextPage = hasNextPage
        self.hasPreviousPage = hasPreviousPage
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}

/// Input for pagination requests
@available(iOS 13.0, macOS 10.15, *)
public struct PaginationInput: Codable, Sendable {
    /// The number of results to return after the cursor
    public let first: Int?
    
    /// The cursor to start from
    public let after: String?
    
    /// The number of results to return before the cursor
    public let last: Int?
    
    /// The cursor to end at
    public let before: String?
    
    /// Initialize pagination input for forward pagination
    /// - Parameters:
    ///   - first: The number of results to return
    ///   - after: The cursor to start from
    public init(first: Int? = nil, after: String? = nil) {
        self.first = first
        self.after = after
        self.last = nil
        self.before = nil
    }
    
    /// Initialize pagination input for backward pagination
    /// - Parameters:
    ///   - last: The number of results to return
    ///   - before: The cursor to end at
    public init(last: Int, before: String? = nil) {
        self.first = nil
        self.after = nil
        self.last = last
        self.before = before
    }
    
    /// Convert the pagination input to a dictionary for use in GraphQL variables
    /// - Returns: A dictionary of pagination variables
    public func toVariables() -> [String: Any] {
        var variables: [String: Any] = [:]
        
        if let first = first {
            variables["first"] = first
        }
        
        if let after = after {
            variables["after"] = after
        }
        
        if let last = last {
            variables["last"] = last
        }
        
        if let before = before {
            variables["before"] = before
        }
        
        return variables
    }
} 