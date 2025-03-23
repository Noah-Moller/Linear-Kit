import SwiftUI
import LinearAPI
import AuthenticationServices

struct ContentView: View {
    @StateObject private var authManager = LinearAuthManager(
        config: LinearOAuthConfig(
            clientId: Secrets.clientId,
            clientSecret: Secrets.clientSecret,
            redirectUri: "linearoauthdemo://oauth-callback",
            scopes: ["read", "write", "issues:create"]
        )
    )
    
    @State private var teams: [Team] = []
    @State private var issues: [Issue] = []
    @State private var isLoadingTeams = false
    @State private var isLoadingIssues = false
    @State private var selectedTeamId: String?
    
    var body: some View {
        NavigationView {
            Group {
                if authManager.isAuthenticated {
                    authenticatedView
                } else {
                    unauthenticatedView
                }
            }
            .navigationTitle("Linear OAuth Demo")
            .navigationBarItems(
                trailing: authManager.isAuthenticated ? 
                    Button("Sign Out") { authManager.signOut() } : nil
            )
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                loadData()
            } else {
                teams = []
                issues = []
            }
        }
    }
    
    private var unauthenticatedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 70))
                .foregroundColor(.blue)
            
            Text("Connect to Linear")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Sign in with your Linear account to view and manage your issues, teams, and projects.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                #if os(iOS)
                authManager.startAuthFlow(from: authManager)
                #else
                // On macOS, we need a presentation anchor provider
                // This could be implemented with NSWindow
                #endif
            }) {
                HStack {
                    Image(systemName: "link")
                    Text("Connect Linear Account")
                }
                .frame(minWidth: 200, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var authenticatedView: some View {
        List {
            if let user = authManager.currentUser {
                Section(header: Text("Profile")) {
                    HStack {
                        if let url = user.avatarUrl {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 50, height: 50)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("Teams")) {
                if isLoadingTeams {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                } else if teams.isEmpty {
                    Text("No teams found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(teams) { team in
                        Button(action: {
                            selectedTeamId = selectedTeamId == team.id ? nil : team.id
                            loadIssues(for: selectedTeamId)
                        }) {
                            HStack {
                                Text(team.key)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                                
                                Text(team.name)
                                
                                Spacer()
                                
                                if selectedTeamId == team.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            
            Section(header: Text(selectedTeamId == nil ? "Recent Issues" : "Team Issues")) {
                if isLoadingIssues {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                } else if issues.isEmpty {
                    Text("No issues found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(issues) { issue in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(issue.identifier)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                if let priority = issue.priority {
                                    priorityLabel(for: priority)
                                }
                            }
                            
                            Text(issue.title)
                                .font(.headline)
                            
                            if let description = issue.description, !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            loadData()
        }
    }
    
    private func priorityLabel(for priority: Int) -> some View {
        let (color, label) = priorityInfo(for: priority)
        
        return Text(label)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private func priorityInfo(for priority: Int) -> (Color, String) {
        switch priority {
        case 0:
            return (.gray, "No Priority")
        case 1:
            return (.blue, "Low")
        case 2:
            return (.orange, "Medium")
        case 3:
            return (.red, "High")
        case 4:
            return (.purple, "Urgent")
        default:
            return (.gray, "Unknown")
        }
    }
    
    private func loadData() {
        loadTeams()
        loadIssues(for: selectedTeamId)
    }
    
    private func loadTeams() {
        isLoadingTeams = true
        
        authManager.getTeams { result in
            isLoadingTeams = false
            
            switch result {
            case .success(let connection):
                teams = connection.nodes
            case .failure(let error):
                print("Error loading teams: \(error)")
            }
        }
    }
    
    private func loadIssues(for teamId: String?) {
        isLoadingIssues = true
        
        authManager.getIssues(teamId: teamId) { result in
            isLoadingIssues = false
            
            switch result {
            case .success(let connection):
                issues = connection.nodes
            case .failure(let error):
                print("Error loading issues: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 