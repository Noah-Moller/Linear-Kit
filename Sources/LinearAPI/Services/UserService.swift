import Foundation

/// Service for managing users in Linear
@available(iOS 13.0, macOS 10.15, *)
public class UserService {
    /// The Linear client
    private let client: LinearClient
    
    /// Initialize a new user service
    /// - Parameter client: The LinearClient to use for API requests
    public init(client: LinearClient) {
        self.client = client
    }
    
    /// Get the currently authenticated user
    /// - Parameter completion: Completion handler with Result containing either the user or an error
    public func getCurrentUser(completion: @escaping @Sendable (Result<User, LinearAPIError>) -> Void) {
        let query = """
        query {
          viewer {
            id
            name
            email
            displayName
            avatarUrl
            status {
              label
              emoji
              message
              updatedAt
            }
          }
        }
        """
        
        client.execute(query: query, variables: nil) { (result: Result<GraphQLResponse<ViewerResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let viewer = response.data?.viewer {
                    completion(.success(viewer))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get a user by ID
    /// - Parameters:
    ///   - id: The ID of the user to fetch
    ///   - completion: Completion handler with Result containing either the user or an error
    public func getUser(id: String, completion: @escaping @Sendable (Result<User, LinearAPIError>) -> Void) {
        let query = """
        query GetUser($id: ID!) {
          user(id: $id) {
            id
            name
            email
            displayName
            avatarUrl
            status {
              label
              emoji
              message
              updatedAt
            }
          }
        }
        """
        
        let variables: [String: Any] = ["id": id]
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<UserResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let user = response.data?.user {
                    completion(.success(user))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get all users for the organization
    /// - Parameters:
    ///   - pagination: Optional pagination input
    ///   - completion: Completion handler with Result containing either a connection of users or an error
    public func getUsers(pagination: PaginationInput? = nil, completion: @escaping @Sendable (Result<Connection<User>, LinearAPIError>) -> Void) {
        var query = """
        query GetUsers {
          users {
            nodes {
              id
              name
              email
              displayName
              avatarUrl
              status {
                label
                emoji
                message
                updatedAt
              }
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
          }
        }
        """
        
        var variables: [String: Any]? = nil
        
        if let pagination = pagination {
            query = """
            query GetUsers($first: Int, $after: String, $last: Int, $before: String) {
              users(first: $first, after: $after, last: $last, before: $before) {
                nodes {
                  id
                  name
                  email
                  displayName
                  avatarUrl
                  status {
                    label
                    emoji
                    message
                    updatedAt
                  }
                }
                pageInfo {
                  hasNextPage
                  hasPreviousPage
                  startCursor
                  endCursor
                }
              }
            }
            """
            
            variables = pagination.toVariables()
        }
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<UsersResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let users = response.data?.users {
                    completion(.success(users))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Update the current user's information
    /// - Parameters:
    ///   - input: The user update input data
    ///   - completion: Completion handler with Result containing either the updated user or an error
    public func updateCurrentUser(input: UpdateUserInput, completion: @escaping @Sendable (Result<User, LinearAPIError>) -> Void) {
        let query = """
        mutation UpdateUser($input: UpdateUserInput!) {
          updateUser(input: $input) {
            user {
              id
              name
              email
              displayName
              avatarUrl
              status {
                label
                emoji
                message
                updatedAt
              }
            }
          }
        }
        """
        
        let variables: [String: Any] = ["input": input.toDictionary()]
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<UpdateUserResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let user = response.data?.updateUser.user {
                    completion(.success(user))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Update the current user's status
    /// - Parameters:
    ///   - input: The status update input data
    ///   - completion: Completion handler with Result containing either the updated user or an error
    public func updateUserStatus(input: UserStatusInput, completion: @escaping @Sendable (Result<User, LinearAPIError>) -> Void) {
        let query = """
        mutation UpdateUserStatus($input: UserStatusInput!) {
          updateUserStatus(input: $input) {
            user {
              id
              name
              email
              displayName
              avatarUrl
              status {
                label
                emoji
                message
                updatedAt
              }
            }
          }
        }
        """
        
        let variables: [String: Any] = ["input": input.toDictionary()]
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<UpdateUserStatusResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let user = response.data?.updateUserStatus.user {
                    completion(.success(user))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get all teammates of the currently authenticated user
    /// - Parameters:
    ///   - pagination: Optional pagination input
    ///   - completion: Completion handler with Result containing either a connection of users or an error
    public func getTeammates(pagination: PaginationInput? = nil, completion: @escaping @Sendable (Result<Connection<User>, LinearAPIError>) -> Void) {
        var query = """
        query {
          teammates {
            nodes {
              id
              name
              email
              displayName
              avatarUrl
              status {
                label
                emoji
                message
                updatedAt
              }
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
          }
        }
        """
        
        var variables: [String: Any]? = nil
        
        if let pagination = pagination {
            query = """
            query GetTeammates($first: Int, $after: String, $last: Int, $before: String) {
              teammates(first: $first, after: $after, last: $last, before: $before) {
                nodes {
                  id
                  name
                  email
                  displayName
                  avatarUrl
                  status {
                    label
                    emoji
                    message
                    updatedAt
                  }
                }
                pageInfo {
                  hasNextPage
                  hasPreviousPage
                  startCursor
                  endCursor
                }
              }
            }
            """
            
            variables = pagination.toVariables()
        }
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<TeammatesResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let teammates = response.data?.teammates {
                    completion(.success(teammates))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Response types for GraphQL queries

private struct ViewerResponse: Codable {
    let viewer: User
}

private struct UserResponse: Codable {
    let user: User
}

private struct UsersResponse: Codable {
    let users: Connection<User>
}

private struct UpdateUserResponse: Codable {
    let updateUser: UpdateUserResult
    
    struct UpdateUserResult: Codable {
        let user: User
    }
}

private struct UpdateUserStatusResponse: Codable {
    let updateUserStatus: UpdateUserStatusResult
    
    struct UpdateUserStatusResult: Codable {
        let user: User
    }
}

private struct TeammatesResponse: Codable {
    let teammates: Connection<User>
}

// MARK: - Async extensions

@available(iOS 15.0, macOS 12.0, *)
extension UserService {
    /// Get the currently authenticated user (async version)
    /// - Returns: The authenticated user
    public func getCurrentUser() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            getCurrentUser { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get a user by ID (async version)
    /// - Parameter id: The ID of the user to fetch
    /// - Returns: The user with the specified ID
    public func getUser(id: String) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            getUser(id: id) { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get all users for the organization (async version)
    /// - Parameter pagination: Optional pagination input
    /// - Returns: A connection of users
    public func getUsers(pagination: PaginationInput? = nil) async throws -> Connection<User> {
        return try await withCheckedThrowingContinuation { continuation in
            getUsers(pagination: pagination) { result in
                switch result {
                case .success(let users):
                    continuation.resume(returning: users)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update the current user's information (async version)
    /// - Parameter input: The user update input data
    /// - Returns: The updated user
    public func updateCurrentUser(input: UpdateUserInput) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            updateCurrentUser(input: input) { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update the current user's status (async version)
    /// - Parameter input: The status update input data
    /// - Returns: The updated user
    public func updateUserStatus(input: UserStatusInput) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            updateUserStatus(input: input) { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get all teammates of the currently authenticated user (async version)
    /// - Parameter pagination: Optional pagination input
    /// - Returns: A connection of users
    public func getTeammates(pagination: PaginationInput? = nil) async throws -> Connection<User> {
        return try await withCheckedThrowingContinuation { continuation in
            getTeammates(pagination: pagination) { result in
                switch result {
                case .success(let teammates):
                    continuation.resume(returning: teammates)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
} 