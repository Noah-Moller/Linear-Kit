import Foundation

/// Service for interacting with teams in Linear
public class TeamService {
    /// The Linear client
    private let client: LinearClient
    
    /// Initialize a new team service
    /// - Parameter client: The Linear client
    public init(client: LinearClient) {
        self.client = client
    }
    
    /// Fetch a team by ID
    /// - Parameters:
    ///   - id: The ID of the team
    ///   - completion: Completion handler with Result containing either the team or an error
    public func getTeam(id: String, completion: @escaping @Sendable (Result<Team, LinearAPIError>) -> Void) {
        let query = """
        query Team($id: ID!) {
            team(id: $id) {
                id
                name
                key
                description
                color
                icon
                organizationId
                createdAt
                updatedAt
                memberIds
                leadUserIds
                url
            }
        }
        """
        
        let variables: [String: Any] = ["id": id]
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<TeamResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let team = response.data?.team {
                    completion(.success(team))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Fetch teams
    /// - Parameters:
    ///   - pagination: Pagination parameters
    ///   - completion: Completion handler with Result containing either the teams or an error
    public func getTeams(
        pagination: PaginationInput = PaginationInput(first: 50),
        completion: @escaping @Sendable (Result<Connection<Team>, LinearAPIError>) -> Void
    ) {
        let query = """
        query Teams($first: Int, $after: String, $last: Int, $before: String) {
            teams(
                first: $first
                after: $after
                last: $last
                before: $before
            ) {
                nodes {
                    id
                    name
                    key
                    description
                    color
                    icon
                    organizationId
                    createdAt
                    updatedAt
                    memberIds
                    leadUserIds
                    url
                }
                pageInfo {
                    hasNextPage
                    hasPreviousPage
                    endCursor
                    startCursor
                }
            }
        }
        """
        
        var variables: [String: Any] = [:]
        if let first = pagination.first {
            variables["first"] = first
        }
        if let after = pagination.after {
            variables["after"] = after
        }
        if let last = pagination.last {
            variables["last"] = last
        }
        if let before = pagination.before {
            variables["before"] = before
        }
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<TeamsResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let teams = response.data?.teams {
                    completion(.success(teams))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Create a new team
    /// - Parameters:
    ///   - input: The team input data
    ///   - completion: Completion handler with Result containing either the created team or an error
    public func createTeam(
        input: CreateTeamInput,
        completion: @escaping @Sendable (Result<Team, LinearAPIError>) -> Void
    ) {
        let mutation = """
        mutation CreateTeam($input: TeamCreateInput!) {
            teamCreate(input: $input) {
                success
                team {
                    id
                    name
                    key
                    description
                    color
                    icon
                    organizationId
                    createdAt
                    updatedAt
                    memberIds
                    leadUserIds
                    url
                }
            }
        }
        """
        
        // Convert Swift struct to dictionary for GraphQL variables
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        guard let inputData = try? encoder.encode(input),
              let inputDict = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any] else {
            completion(.failure(.encodingError))
            return
        }
        
        let variables: [String: Any] = ["input": inputDict]
        
        client.execute(query: mutation, variables: variables) { (result: Result<GraphQLResponse<CreateTeamResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let team = response.data?.createTeam.team {
                    completion(.success(team))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Update an existing team
    /// - Parameters:
    ///   - input: The team update input data
    ///   - completion: Completion handler with Result containing either the updated team or an error
    public func updateTeam(
        input: UpdateTeamInput,
        completion: @escaping @Sendable (Result<Team, LinearAPIError>) -> Void
    ) {
        let mutation = """
        mutation UpdateTeam($input: TeamUpdateInput!) {
            teamUpdate(input: $input) {
                success
                team {
                    id
                    name
                    key
                    description
                    color
                    icon
                    organizationId
                    createdAt
                    updatedAt
                    memberIds
                    leadUserIds
                    url
                }
            }
        }
        """
        
        // Convert Swift struct to dictionary for GraphQL variables
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        guard let inputData = try? encoder.encode(input),
              let inputDict = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any] else {
            completion(.failure(.encodingError))
            return
        }
        
        let variables: [String: Any] = ["input": inputDict]
        
        client.execute(query: mutation, variables: variables) { (result: Result<GraphQLResponse<UpdateTeamResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let team = response.data?.updateTeam.team {
                    completion(.success(team))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Delete a team
    /// - Parameters:
    ///   - id: The ID of the team to delete
    ///   - completion: Completion handler with Result containing either success or an error
    public func deleteTeam(
        id: String,
        completion: @escaping @Sendable (Result<Bool, LinearAPIError>) -> Void
    ) {
        let mutation = """
        mutation DeleteTeam($id: ID!) {
            teamDelete(id: $id) {
                success
            }
        }
        """
        
        let variables: [String: Any] = ["id": id]
        
        client.execute(query: mutation, variables: variables) { (result: Result<GraphQLResponse<DeleteTeamResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let success = response.data?.deleteTeam.success {
                    completion(.success(success))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Async version of getTeam
    /// - Parameter id: The team ID
    /// - Returns: The requested team
    @available(iOS 15.0, macOS 12.0, *)
    public func getTeam(id: String) async throws -> Team {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Team, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            getTeam(id: id, completion: completion)
        }
    }
    
    /// Async version of getTeams
    /// - Parameter pagination: Pagination parameters
    /// - Returns: A connection of teams
    @available(iOS 15.0, macOS 12.0, *)
    public func getTeams(
        pagination: PaginationInput = PaginationInput(first: 50)
    ) async throws -> Connection<Team> {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Connection<Team>, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            getTeams(pagination: pagination, completion: completion)
        }
    }
    
    /// Async version of createTeam
    /// - Parameter input: The team input data
    /// - Returns: The created team
    @available(iOS 15.0, macOS 12.0, *)
    public func createTeam(input: CreateTeamInput) async throws -> Team {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Team, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            createTeam(input: input, completion: completion)
        }
    }
    
    /// Async version of updateTeam
    /// - Parameter input: The team update data
    /// - Returns: The updated team
    @available(iOS 15.0, macOS 12.0, *)
    public func updateTeam(input: UpdateTeamInput) async throws -> Team {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Team, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            updateTeam(input: input, completion: completion)
        }
    }
    
    /// Async version of deleteTeam
    /// - Parameter id: The ID of the team to delete
    /// - Returns: A boolean indicating success
    @available(iOS 15.0, macOS 12.0, *)
    public func deleteTeam(id: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Bool, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            deleteTeam(id: id, completion: completion)
        }
    }
}

// MARK: - Response container structs

/// Container for a team in a GraphQL response
private struct TeamResponse: Decodable {
    let team: Team
}

/// Container for teams in a GraphQL response
private struct TeamsResponse: Decodable {
    let teams: Connection<Team>
}

/// Response for team creation
private struct CreateTeamResponse: Decodable {
    let createTeam: TeamResult
    
    struct TeamResult: Decodable {
        let team: Team
    }
}

/// Response for team update
private struct UpdateTeamResponse: Decodable {
    let updateTeam: TeamResult
    
    struct TeamResult: Decodable {
        let team: Team
    }
}

/// Response for team deletion
private struct DeleteTeamResponse: Decodable {
    let deleteTeam: DeleteResult
    
    struct DeleteResult: Decodable {
        let success: Bool
    }
} 