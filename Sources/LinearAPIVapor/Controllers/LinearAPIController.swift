import Foundation
import Vapor
import LinearAPI

/// Controller for handling Linear API requests
@available(macOS 12.0, iOS 15.0, *)
public struct LinearAPIController: RouteCollection {
    /// The Linear service
    private let linearService: LinearService
    
    /// Initializes a new LinearAPIController
    /// - Parameter linearService: The Linear service
    public init(linearService: LinearService) {
        self.linearService = linearService
    }
    
    /// Registers routes with the given route builder
    /// - Parameter routes: The route builder to register routes with
    public func boot(routes: RoutesBuilder) throws {
        let apiRoutes = routes.grouped("linear", "api")
        
        // Route for executing GraphQL queries
        apiRoutes.post("graphql") { req -> ClientResponse in
            // Get the user ID from the request (you should implement user authentication)
            guard let userId = try? req.auth.require(AuthUserModel.self).id else {
                throw Abort(.unauthorized, reason: "User must be authenticated")
            }
            
            // Extract the query and variables from the request
            struct GraphQLRequest: Content {
                let query: String
                let variables: [String: String]?
            }
            
            let graphQLRequest = try req.content.decode(GraphQLRequest.self)
            
            // Get a client for the user
            let client = try await linearService.getClientForUser(userId)
            
            // Execute the query and get the response
            let linearResponse: GraphQLResponse<[String: AnyDecodable]> = try await client.execute(
                query: graphQLRequest.query,
                variables: graphQLRequest.variables as [String: Any]?
            )
            
            // Convert to Vapor-compatible response
            let vaporResponse = VaporGraphQLResponse(from: linearResponse)
            
            // Return the response as JSON
            return ClientResponse(status: .ok, headers: ["Content-Type": "application/json"], body: .init(data: try JSONEncoder().encode(vaporResponse)))
        }
        
        // Route for getting the current user
        apiRoutes.get("me") { req -> ClientResponse in
            // Get the user ID from the request (you should implement user authentication)
            guard let userId = try? req.auth.require(AuthUserModel.self).id else {
                throw Abort(.unauthorized, reason: "User must be authenticated")
            }
            
            // Get a client for the user
            let client = try await linearService.getClientForUser(userId)
            
            // Execute the query to get the current user
            let linearResponse: GraphQLResponse<ViewerResponse> = try await client.execute(
                query: """
                query {
                  viewer {
                    id
                    name
                    email
                    avatarUrl
                    displayName
                  }
                }
                """
            )
            
            // Convert to Vapor-compatible response
            let vaporResponse = VaporGraphQLResponse(from: linearResponse)
            
            // Return the response as JSON
            return ClientResponse(status: .ok, headers: ["Content-Type": "application/json"], body: .init(data: try JSONEncoder().encode(vaporResponse)))
        }
        
        // Route for getting user's teams
        apiRoutes.get("teams") { req -> ClientResponse in
            // Get the user ID from the request (you should implement user authentication)
            guard let userId = try? req.auth.require(AuthUserModel.self).id else {
                throw Abort(.unauthorized, reason: "User must be authenticated")
            }
            
            // Get a client for the user
            let client = try await linearService.getClientForUser(userId)
            
            // Execute the query to get the user's teams
            let response = try await client.teams.getTeams()
            
            // Return the response as JSON
            return ClientResponse(status: .ok, headers: ["Content-Type": "application/json"], body: .init(data: try JSONEncoder().encode(response)))
        }
        
        // Route for getting user's issues
        apiRoutes.get("issues") { req -> ClientResponse in
            // Get the user ID from the request (you should implement user authentication)
            guard let userId = try? req.auth.require(AuthUserModel.self).id else {
                throw Abort(.unauthorized, reason: "User must be authenticated")
            }
            
            // Get optional team ID and pagination parameters from the request
            let teamId = req.query[String.self, at: "teamId"]
            let first = req.query[Int.self, at: "first"] ?? 50
            let after = req.query[String.self, at: "after"]
            
            // Create pagination input
            let pagination = PaginationInput(first: first, after: after)
            
            // Get a client for the user
            let client = try await linearService.getClientForUser(userId)
            
            // Execute the query to get the user's issues
            let response = try await client.issues.getIssues(teamId: teamId, pagination: pagination)
            
            // Return the response as JSON
            return ClientResponse(status: .ok, headers: ["Content-Type": "application/json"], body: .init(data: try JSONEncoder().encode(response)))
        }
    }
}

/// Helper type for decoding any value from JSON
struct AnyDecodable: Codable {
    let value: Any
    
    init(value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyDecodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyDecodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyDecodable cannot decode \(type(of: container))")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull, is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyDecodable(value: $0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyDecodable(value: $0) })
        default:
            throw EncodingError.invalidValue(self.value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyDecodable cannot encode \(type(of: self.value))"))
        }
    }
}

/// Response type for the viewer query
struct ViewerResponse: Codable {
    let viewer: User
} 