import SwiftUI
import LinearAPI

struct ContentView: View {
    @StateObject private var linearClient = LinearServerClient(
        serverURL: URL(string: "http://localhost:8080")!
    )
    
    private let contextProvider = PresentationContextProvider()
    
    var body: some View {
        NavigationView {
            if linearClient.isAuthenticated {
                LinearDashboardView(client: linearClient)
            } else {
                LinearServerLoginView(
                    client: linearClient,
                    contextProvider: contextProvider
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LinearDashboardView: View {
    @ObservedObject var client: LinearServerClient
    @State private var user: User?
    @State private var teams: [Team] = []
    @State private var issues: [Issue] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else {
                if let user = user {
                    Section(header: Text("Profile")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
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
                }
                
                if !teams.isEmpty {
                    Section(header: Text("Teams")) {
                        ForEach(teams, id: \.id) { team in
                            VStack(alignment: .leading) {
                                Text(team.name)
                                    .font(.headline)
                                Text(team.key)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if !issues.isEmpty {
                    Section(header: Text("Recent Issues")) {
                        ForEach(issues, id: \.id) { issue in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(issue.title)
                                    .font(.headline)
                                
                                HStack {
                                    Text(issue.state.name)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(4)
                                    
                                    if let priority = issue.priority {
                                        Text("P\(priority)")
                                            .font(.caption)
                                            .padding(4)
                                            .background(priorityColor(priority).opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Open") {
                                        if let url = URL(string: issue.url) {
                                            #if os(iOS)
                                            UIApplication.shared.open(url)
                                            #elseif os(macOS)
                                            NSWorkspace.shared.open(url)
                                            #endif
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            loadData()
        }
        .navigationTitle("Linear Dashboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign Out") {
                    client.signOut()
                }
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        isLoading = true
        error = nil
        
        client.getCurrentUser { result in
            switch result {
            case .success(let user):
                self.user = user
                
                client.getTeams { result in
                    switch result {
                    case .success(let teams):
                        self.teams = teams
                        
                        client.getIssues { result in
                            isLoading = false
                            
                            switch result {
                            case .success(let issues):
                                self.issues = issues
                            case .failure(let error):
                                self.error = error
                            }
                        }
                    case .failure(let error):
                        isLoading = false
                        self.error = error
                    }
                }
            case .failure(let error):
                isLoading = false
                self.error = error
            }
        }
    }
    
    private func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 0:
            return .gray
        case 1:
            return .red
        case 2:
            return .orange
        case 3:
            return .yellow
        case 4:
            return .green
        default:
            return .blue
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 