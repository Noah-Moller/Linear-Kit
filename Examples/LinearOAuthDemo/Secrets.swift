import Foundation

/// Secrets for the Linear OAuth application
/// Replace these with your own values from Linear settings
struct Secrets {
    /// OAuth client ID from Linear
    static let clientId = "YOUR_CLIENT_ID"
    
    /// OAuth client secret from Linear
    static let clientSecret = "YOUR_CLIENT_SECRET"
    
    /// IMPORTANT: In a real app, you should never hardcode secrets.
    /// Instead, use a more secure approach like:
    /// 1. Environment variables for server-side apps
    /// 2. Secure storage solutions for client apps
    /// 3. A backend service that handles the OAuth flow
} 