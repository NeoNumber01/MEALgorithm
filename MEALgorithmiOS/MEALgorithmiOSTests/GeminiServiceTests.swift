import XCTest
@testable import MEALgorithmiOS

final class GeminiServiceTests: XCTestCase {

    var service: GeminiService!

    override func setUp() {
        super.setUp()
        service = GeminiService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testCleanJSON_StandardRawJSON_ReturnsSame() async {
        let json = "{\"key\": \"value\"}"
        let cleaned = await service.cleanJSON(json)
        XCTAssertEqual(cleaned, json)
    }

    func testCleanJSON_MarkdownBlock_ReturnsRawJSON() async {
        let json = """
        ```json
        {
            "key": "value"
        }
        ```
        """
        let expected = """
        {
            "key": "value"
        }
        """
        let cleaned = await service.cleanJSON(json)
        XCTAssertEqual(cleaned, expected)
    }

    func testCleanJSON_MarkdownBlockNoLang_ReturnsRawJSON() async {
        let json = """
        ```
        {
            "key": "value"
        }
        ```
        """
        let expected = """
        {
            "key": "value"
        }
        """
        let cleaned = await service.cleanJSON(json)
        XCTAssertEqual(cleaned, expected)
    }

    func testCleanJSON_LeadingWhitespace_ReturnsTrimmedJSON() async {
        let json = """
           ```json
           {"key": "value"}
           ```   
        """
        let expected = "{\"key\": \"value\"}"
        let cleaned = await service.cleanJSON(json)
        XCTAssertEqual(cleaned, expected)
    }

    func testCleanJSON_MessyPrefix_ReturnsCleanJSON() async {
        // Simulating the error: Unexpected character '`'
        let json = "` {\"key\": \"value\"} `"
        let expected = "{\"key\": \"value\"}"
        let cleaned = await service.cleanJSON(json)
        XCTAssertEqual(cleaned, expected)
    }
    
    func testCleanJSON_NoBraces_ReturnsOriginalTrimmed() async {
        let text = "Just some text"
        let cleaned = await service.cleanJSON(text)
        XCTAssertEqual(cleaned, "Just some text")
    }
}
