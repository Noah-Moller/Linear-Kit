import Foundation

/// Service for interacting with issues in Linear
public class IssueService {
    /// The Linear client
    private let client: LinearClient
    
    /// Initialize a new issue service
    /// - Parameter client: The Linear client
    public init(client: LinearClient) {
        self.client = client
    }
    
    /// Fetch an issue by ID
    /// - Parameters:
    ///   - id: The ID of the issue
    ///   - completion: Completion handler with Result containing either the issue or an error
    public func getIssue(id: String, completion: @escaping @Sendable (Result<Issue, LinearAPIError>) -> Void) {
        let query = """
        query Issue($id: ID!) {
            issue(id: $id) {
                id
                identifier
                title
                description
                priority
                estimate
                projectId
                teamId
                cycleId
                labelIds
                assigneeId
                creatorId
                parentId
                stateId
                stateName
                createdAt
                updatedAt
                startedAt
                completedAt
                cancelledAt
                dueDate
                trashed
                customerTicketCount
                url
            }
        }
        """
        
        let variables: [String: Any] = ["id": id]
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<IssueResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let issue = response.data?.issue {
                    completion(.success(issue))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Fetch issues
    /// - Parameters:
    ///   - teamId: Optional team ID to filter issues
    ///   - assigneeId: Optional assignee ID to filter issues
    ///   - pagination: Pagination parameters
    ///   - completion: Completion handler with Result containing either the issues or an error
    public func getIssues(
        teamId: String? = nil,
        assigneeId: String? = nil,
        pagination: PaginationInput = PaginationInput(first: 50),
        completion: @escaping @Sendable (Result<Connection<Issue>, LinearAPIError>) -> Void
    ) {
        let query = """
        query Issues($teamId: ID, $assigneeId: ID, $first: Int, $after: String, $last: Int, $before: String) {
            issues(
                filter: {
                    team: { id: { eq: $teamId } }
                    assignee: { id: { eq: $assigneeId } }
                }
                first: $first
                after: $after
                last: $last
                before: $before
            ) {
                nodes {
                    id
                    identifier
                    title
                    description
                    priority
                    estimate
                    projectId
                    teamId
                    cycleId
                    labelIds
                    assigneeId
                    creatorId
                    parentId
                    stateId
                    stateName
                    createdAt
                    updatedAt
                    startedAt
                    completedAt
                    cancelledAt
                    dueDate
                    trashed
                    customerTicketCount
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
        if let teamId = teamId {
            variables["teamId"] = teamId
        }
        if let assigneeId = assigneeId {
            variables["assigneeId"] = assigneeId
        }
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
        
        client.execute(query: query, variables: variables) { (result: Result<GraphQLResponse<IssuesResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let issues = response.data?.issues {
                    completion(.success(issues))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Create a new issue
    /// - Parameters:
    ///   - input: The issue input data
    ///   - completion: Completion handler with Result containing either the created issue or an error
    public func createIssue(
        input: CreateIssueInput,
        completion: @escaping @Sendable (Result<Issue, LinearAPIError>) -> Void
    ) {
        let mutation = """
        mutation CreateIssue($input: IssueCreateInput!) {
            issueCreate(input: $input) {
                success
                issue {
                    id
                    identifier
                    title
                    description
                    priority
                    estimate
                    projectId
                    teamId
                    cycleId
                    labelIds
                    assigneeId
                    creatorId
                    parentId
                    stateId
                    stateName
                    createdAt
                    updatedAt
                    startedAt
                    completedAt
                    cancelledAt
                    dueDate
                    trashed
                    customerTicketCount
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
        
        client.execute(query: mutation, variables: variables) { (result: Result<GraphQLResponse<CreateIssueResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let issue = response.data?.createIssue.issue {
                    completion(.success(issue))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Update an existing issue
    /// - Parameters:
    ///   - input: The issue update input data
    ///   - completion: Completion handler with Result containing either the updated issue or an error
    public func updateIssue(
        input: UpdateIssueInput,
        completion: @escaping @Sendable (Result<Issue, LinearAPIError>) -> Void
    ) {
        let mutation = """
        mutation UpdateIssue($input: IssueUpdateInput!) {
            issueUpdate(input: $input) {
                success
                issue {
                    id
                    identifier
                    title
                    description
                    priority
                    estimate
                    projectId
                    teamId
                    cycleId
                    labelIds
                    assigneeId
                    creatorId
                    parentId
                    stateId
                    stateName
                    createdAt
                    updatedAt
                    startedAt
                    completedAt
                    cancelledAt
                    dueDate
                    trashed
                    customerTicketCount
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
        
        client.execute(query: mutation, variables: variables) { (result: Result<GraphQLResponse<UpdateIssueResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let issue = response.data?.updateIssue.issue {
                    completion(.success(issue))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Delete an issue
    /// - Parameters:
    ///   - id: The ID of the issue to delete
    ///   - completion: Completion handler with Result containing either success or an error
    public func deleteIssue(
        id: String,
        completion: @escaping @Sendable (Result<Bool, LinearAPIError>) -> Void
    ) {
        let mutation = """
        mutation DeleteIssue($id: ID!) {
            issueDelete(id: $id) {
                success
            }
        }
        """
        
        let variables: [String: Any] = ["id": id]
        
        client.execute(query: mutation, variables: variables) { (result: Result<GraphQLResponse<DeleteIssueResponse>, LinearAPIError>) in
            switch result {
            case .success(let response):
                if let success = response.data?.deleteIssue.success {
                    completion(.success(success))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Async version of getIssue
    /// - Parameter id: The issue ID
    /// - Returns: The requested issue
    @available(iOS 15.0, macOS 12.0, *)
    public func getIssue(id: String) async throws -> Issue {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Issue, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            getIssue(id: id, completion: completion)
        }
    }
    
    /// Async version of getIssues
    /// - Parameters:
    ///   - teamId: Optional team ID to filter issues
    ///   - assigneeId: Optional assignee ID to filter issues
    ///   - pagination: Pagination parameters
    /// - Returns: A connection of issues
    @available(iOS 15.0, macOS 12.0, *)
    public func getIssues(
        teamId: String? = nil,
        assigneeId: String? = nil,
        pagination: PaginationInput = PaginationInput(first: 50)
    ) async throws -> Connection<Issue> {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Connection<Issue>, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            getIssues(
                teamId: teamId,
                assigneeId: assigneeId,
                pagination: pagination,
                completion: completion
            )
        }
    }
    
    /// Async version of createIssue
    /// - Parameter input: The issue input data
    /// - Returns: The created issue
    @available(iOS 15.0, macOS 12.0, *)
    public func createIssue(input: CreateIssueInput) async throws -> Issue {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Issue, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            createIssue(input: input, completion: completion)
        }
    }
    
    /// Async version of updateIssue
    /// - Parameter input: The issue update data
    /// - Returns: The updated issue
    @available(iOS 15.0, macOS 12.0, *)
    public func updateIssue(input: UpdateIssueInput) async throws -> Issue {
        return try await withCheckedThrowingContinuation { continuation in
            let completion: @Sendable (Result<Issue, LinearAPIError>) -> Void = { result in
                switch result {
                case .success(let value):
                    let localValue = value
                    continuation.resume(returning: localValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            updateIssue(input: input, completion: completion)
        }
    }
    
    /// Async version of deleteIssue
    /// - Parameter id: The ID of the issue to delete
    /// - Returns: A boolean indicating success
    @available(iOS 15.0, macOS 12.0, *)
    public func deleteIssue(id: String) async throws -> Bool {
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
            
            deleteIssue(id: id, completion: completion)
        }
    }
}

// MARK: - Response container structs

/// Container for an issue in a GraphQL response
private struct IssueResponse: Decodable {
    let issue: Issue
}

/// Container for issues in a GraphQL response
private struct IssuesResponse: Decodable {
    let issues: Connection<Issue>
}

/// Response for issue creation
private struct CreateIssueResponse: Decodable {
    let createIssue: IssueResult
    
    struct IssueResult: Decodable {
        let issue: Issue
    }
}

/// Response for issue update
private struct UpdateIssueResponse: Decodable {
    let updateIssue: IssueResult
    
    struct IssueResult: Decodable {
        let issue: Issue
    }
}

/// Response for issue deletion
private struct DeleteIssueResponse: Decodable {
    let deleteIssue: DeleteResult
    
    struct DeleteResult: Decodable {
        let success: Bool
    }
} 