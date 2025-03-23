import SwiftUI
import AuthenticationServices

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A presentation context provider for ASWebAuthenticationSession
@available(iOS 13.0, macOS 10.15, *)
public class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    #if canImport(UIKit)
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        } else {
            return UIWindow()
        }
    }
    #elseif canImport(AppKit)
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApp.windows.first ?? NSWindow()
    }
    #endif
    
    public override init() {
        super.init()
    }
}

/// A SwiftUI view for authenticating with the Linear server
@available(iOS 14.0, macOS 11.0, *)
public struct LinearServerLoginView: View {
    @ObservedObject var client: LinearServerClient
    let contextProvider: ASWebAuthenticationPresentationContextProviding
    
    @State private var isAuthenticating = false
    @State private var error: Error?
    
    public init(client: LinearServerClient, contextProvider: ASWebAuthenticationPresentationContextProviding) {
        self.client = client
        self.contextProvider = contextProvider
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            if #available(iOS 13.0, macOS 11.0, *) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
            }
            
            Text("Connect to Linear")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Authorize this app to access your Linear account.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if isAuthenticating {
                if #available(iOS 14.0, macOS 11.0, *) {
                    ProgressView()
                        .padding()
                } else {
                    Text("Authenticating...")
                        .padding()
                }
            } else {
                Button(action: startAuthentication) {
                    HStack {
                        if #available(iOS 13.0, macOS 11.0, *) {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text("Connect Linear Account")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
    }
    
    private func startAuthentication() {
        isAuthenticating = true
        error = nil
        
        client.authenticate(from: contextProvider)
        
        // Monitor authentication state changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if client.isAuthenticated {
                isAuthenticating = false
            } else if let authError = client.authError {
                isAuthenticating = false
                error = authError
            } else if !client.isAuthenticating {
                isAuthenticating = false
            } else {
                // Keep checking until authentication completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAuthenticating = client.isAuthenticating
                    error = client.authError
                }
            }
        }
    }
}

/// A preview provider for LinearServerLoginView
#if DEBUG
@available(iOS 14.0, macOS 11.0, *)
struct LinearServerLoginView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, macOS 11.0, *) {
            LinearServerLoginView(
                client: LinearServerClient(serverURL: URL(string: "https://example.com")!),
                contextProvider: PresentationContextProvider()
            )
        } else {
            Text("Preview not available")
        }
    }
}
#endif 