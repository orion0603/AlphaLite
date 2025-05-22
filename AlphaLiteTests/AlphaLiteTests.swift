import XCTest
@testable import AlphaLite

final class AlphaLiteTests: XCTestCase {
    func testCoreDataStackLoads() {
        _ = ReminderStore()
        _ = MemoryStore()
    }
} 