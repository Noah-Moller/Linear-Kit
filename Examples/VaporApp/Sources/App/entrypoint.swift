import Vapor
import Logging

@main
struct Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        do {
            if #available(macOS 12.0, iOS 15.0, *) {
                try configure(app)
            } else {
                app.logger.critical("This application requires macOS 12.0 / iOS 15.0 or later.")
                throw VaporError(identifier: "unsupportedPlatform", reason: "This application requires macOS 12.0 / iOS 15.0 or later.")
            }
            
            try await app.run()
        } catch {
            app.logger.report(error: error)
            throw error
        }
    }
} 