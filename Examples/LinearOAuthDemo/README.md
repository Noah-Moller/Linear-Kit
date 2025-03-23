# Linear OAuth Demo

This example project demonstrates how to integrate Linear's OAuth authentication into an iOS or macOS application using the LinearAPI Swift package.

## Getting Started

1. Clone this repository
2. Open the `LinearOAuthDemo.xcodeproj` in Xcode
3. Create a new Linear OAuth application at https://linear.app/settings/api/applications
4. Set your application's redirect URI to `linearoauthdemo://oauth-callback`
5. Replace the placeholder values in `Secrets.swift` with your OAuth client ID and client secret
6. Choose a simulator or device and run the app

## Key Files

- **LinearAuthManager.swift**: Handles the OAuth authentication flow
- **ContentView.swift**: Main SwiftUI view showing login and user data
- **Secrets.swift**: Configuration for your OAuth application credentials

## Features

- OAuth authentication with Linear
- Secure token storage
- Automatic token refresh
- User profile display
- Teams and issues lists

## Requirements

- iOS 14.0+ or macOS 11.0+
- Xcode 13.0+
- Swift 5.5+

## Usage

1. Tap "Connect Linear Account" to start the OAuth flow
2. Authorize the application in the presented web view
3. After successful authentication, the app will display your Linear profile
4. Your teams and recent issues will be loaded and displayed

## Implementation Notes

This example demonstrates:

1. Setting up ASWebAuthenticationSession for the OAuth flow
2. Securely storing OAuth tokens in UserDefaults (use Keychain in production)
3. Using the LinearAPI package to interact with Linear's API
4. Structuring a SwiftUI app to handle authentication state
5. Displaying Linear data using SwiftUI components

## Next Steps

For a production application, you might want to:

- Store tokens in the Keychain instead of UserDefaults
- Implement a more robust token refresh mechanism
- Add additional error handling
- Expand the functionality to create and update issues
- Implement a more comprehensive UI

## License

This example is provided under the MIT License. See the LICENSE file for details. 