import XCTest
@testable import LinearAPI

final class LinearAPITests: XCTestCase {
    
    // Mock URLSession for testing network requests
    @available(iOS 13.0, macOS 10.15, *)
    class MockURLSession: URLSession, @unchecked Sendable {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        override init() {
            super.init()
        }
        
        override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            let task = MockURLSessionDataTask()
            task.completionHandler = {
                completionHandler(self.data, self.response, self.error)
            }
            return task
        }
        
        @available(iOS 13.0, macOS 10.15, *)
        class MockURLSessionDataTask: URLSessionDataTask, @unchecked Sendable {
            var completionHandler: (() -> Void)?
            
            override func resume() {
                completionHandler?()
            }
        }
    }
    
    func testClientInitialization() {
        let client = LinearClient(apiToken: "test_token")
        XCTAssertNotNil(client, "Client should be initialized")
    }
    
    func testClientExecuteSuccess() {
        let mockSession = MockURLSession()
        let client = LinearClient(apiToken: "test_token", session: mockSession)
        
        // Setup mock response
        let jsonString = """
        {
            "data": {
                "issue": {
                    "id": "test-id",
                    "identifier": "TEST-123",
                    "title": "Test Issue",
                    "teamId": "team-id",
                    "creatorId": "creator-id",
                    "stateId": "state-id",
                    "createdAt": "2023-01-01T00:00:00Z",
                    "updatedAt": "2023-01-02T00:00:00Z",
                    "url": "https://linear.app/team/issue/TEST-123"
                }
            }
        }
        """
        
        mockSession.data = jsonString.data(using: .utf8)
        mockSession.response = HTTPURLResponse(url: URL(string: "https://api.linear.app/graphql")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Create a container type that matches our expected response structure
        struct TestContainer: Decodable {
            struct IssueContainer: Decodable {
                let issue: TestIssue
            }
            
            let data: IssueContainer
        }
        
        struct TestIssue: Decodable {
            let id: String
            let title: String
        }
        
        // Test execute with completion handler
        let expectation = XCTestExpectation(description: "API call")
        
        client.execute(query: "query { issue { id title } }") { (result: Result<TestContainer, LinearAPIError>) in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.data.issue.id, "test-id")
                XCTAssertEqual(response.data.issue.title, "Test Issue")
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testClientExecuteFailure() {
        let mockSession = MockURLSession()
        let client = LinearClient(apiToken: "test_token", session: mockSession)
        
        // Setup mock error response
        let jsonString = """
        {
            "errors": [
                {
                    "message": "Not authorized"
                }
            ]
        }
        """
        
        mockSession.data = jsonString.data(using: .utf8)
        mockSession.response = HTTPURLResponse(url: URL(string: "https://api.linear.app/graphql")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Create a container type for testing errors
        struct TestErrorContainer: Decodable {
            struct DataContainer: Decodable {
                let test: String?
            }
            
            let data: DataContainer?
            let errors: [GraphQLError]?
        }
        
        // Test execute with completion handler for error scenario
        let expectation = XCTestExpectation(description: "API error call")
        
        client.execute(query: "query { test }") { (result: Result<TestErrorContainer, LinearAPIError>) in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response.errors)
                XCTAssertEqual(response.errors?.first?.message, "Not authorized")
            case .failure(let error):
                XCTFail("Should return success with GraphQL error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testClientNetworkError() {
        let mockSession = MockURLSession()
        let client = LinearClient(apiToken: "test_token", session: mockSession)
        
        // Setup mock network error
        struct TestNetworkError: Error {}
        mockSession.error = TestNetworkError()
        
        // Create a simple container type for testing
        struct TestContainer: Decodable {
            let data: String?
        }
        
        // Test execute with completion handler for network error
        let expectation = XCTestExpectation(description: "Network error call")
        
        client.execute(query: "query { test }") { (result: Result<TestContainer, LinearAPIError>) in
            switch result {
            case .success:
                XCTFail("Should fail with network error")
            case .failure(let error):
                if case .networkError = error {
                    // Expected network error
                    XCTAssertTrue(true)
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testClientOAuthInitialization() {
        let client = LinearClient(accessToken: "test_token")
        XCTAssertNotNil(client, "Client should be initialized with OAuth token")
    }
}
