import Vapor
import LinearAPIVapor
import LinearAPI

struct UserInfo: Content {
    let id: String
    let name: String
    let email: String
    let avatarUrl: String?
    let teams: [TeamInfo]
    let issues: [IssueInfo]
}

struct TeamInfo: Content {
    let id: String
    let name: String
    let key: String
}

struct IssueInfo: Content {
    let id: String
    let title: String
    let state: String
    let priority: Int?
    let url: String
}

func routes(_ app: Application) throws {
    // Home page
    app.get { req -> EventLoopFuture<View> in
        let user = try? req.session.get("linearUser") as? String
        let isLoggedIn = user != nil
        
        return req.view.render("index", [
            "isLoggedIn": isLoggedIn
        ])
    }
    
    // API routes
    let apiController = APIController(app)
    app.grouped("api").register(collection: apiController)
}

struct APIController: RouteCollection {
    let app: Application
    
    init(_ app: Application) {
        self.app = app
    }
    
    func boot(routes: RoutesBuilder) throws {
        // Get current user info
        routes.get("user") { req -> EventLoopFuture<UserInfo> in
            guard let userId = try? req.session.get("linearUser") as? String else {
                throw Abort(.unauthorized)
            }
            
            let linearService = req.application.linear
            
            return linearService.getClientForUser(userId, on: req.eventLoop).flatMap { client in
                // Get user info
                let userFuture = client.users.getCurrentUser().map { $0 }
                
                // Get teams
                let teamsFuture = client.teams.getTeams().map { $0.nodes }
                
                // Get issues
                let issuesFuture = client.issues.getIssues().map { $0.nodes }
                
                // Combine all results
                return userFuture.and(teamsFuture).and(issuesFuture).map { result in
                    let ((user, teams), issues) = result
                    
                    let teamInfos = teams.map { team in
                        TeamInfo(id: team.id, name: team.name, key: team.key)
                    }
                    
                    let issueInfos = issues.map { issue in
                        IssueInfo(
                            id: issue.id,
                            title: issue.title,
                            state: issue.state.name,
                            priority: issue.priority,
                            url: issue.url
                        )
                    }
                    
                    return UserInfo(
                        id: user.id,
                        name: user.name,
                        email: user.email,
                        avatarUrl: user.avatarUrl,
                        teams: teamInfos,
                        issues: issueInfos
                    )
                }
            }
        }
        
        // Create a new issue
        routes.post("issues") { req -> EventLoopFuture<HTTPStatus> in
            guard let userId = try? req.session.get("linearUser") as? String else {
                throw Abort(.unauthorized)
            }
            
            // Parse request
            struct IssueRequest: Content {
                let title: String
                let description: String?
                let teamId: String
                let priority: Int?
            }
            
            let issueRequest = try req.content.decode(IssueRequest.self)
            let linearService = req.application.linear
            
            return linearService.getClientForUser(userId, on: req.eventLoop).flatMap { client in
                let input = CreateIssueInput(
                    title: issueRequest.title,
                    teamId: issueRequest.teamId,
                    description: issueRequest.description,
                    priority: issueRequest.priority
                )
                
                return client.issues.createIssue(input: input).map { _ in
                    return .created
                }
            }
        }
    }
} 