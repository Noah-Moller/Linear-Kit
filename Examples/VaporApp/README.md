# Linear API Vapor Example

This is a sample Vapor application that demonstrates how to integrate with Linear using the `LinearAPIVapor` module.

## Features

- OAuth authentication with Linear
- Server-side token management (storage, refresh, and revocation)
- Example routes for accessing Linear data
- User authentication with Fluent

## Requirements

- macOS 12.0 or later
- Swift 5.8 or later
- Vapor 4.76.0 or later

## Getting Started

1. Clone the repository
2. Navigate to the `Examples/VaporApp` directory
3. Set up your environment variables:
   ```
   export LINEAR_CLIENT_ID="your_client_id"
   export LINEAR_CLIENT_SECRET="your_client_secret" 
   export LINEAR_REDIRECT_URI="http://localhost:8080/linear/auth/callback"
   ```
4. Run the application:
   ```
   swift run
   ```
5. Access the application at http://localhost:8080

## Environment Variables

- `LINEAR_CLIENT_ID`: Your Linear OAuth client ID
- `LINEAR_CLIENT_SECRET`: Your Linear OAuth client secret
- `LINEAR_REDIRECT_URI`: The redirect URI for your Linear OAuth application

## OAuth Flow

1. User accesses `/linear/auth/login`
2. User is redirected to Linear for authentication
3. After authentication, Linear redirects to `/linear/auth/callback`
4. The application exchanges the code for a token and stores it
5. The user can now access Linear data via the API

## API Endpoints

- `/linear/api/graphql`: Execute GraphQL queries against the Linear API
- `/linear/api/me`: Get the current user's information
- `/linear/api/teams`: Get the user's teams
- `/linear/api/issues`: Get the user's issues

## App Structure

- `configure.swift`: Application configuration
- `routes.swift`: Route definitions
- `Models/User.swift`: User model and migration
- `entrypoint.swift`: Application entry point
- `Resources/Views`: Leaf templates for rendering HTML

## License

This example is part of the Linear API integration package. 