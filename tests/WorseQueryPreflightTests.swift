import XCTest
@testable import AirCard_iOS

final class WorseQueryPreflightTests: XCTestCase {
    func testUnrelatedOSDoesNotClaimSupport() {
        let report = WorseQueryPreflight.evaluate(
            osMajorVersion: 25,
            configuredAppGroup: "group.example.aircard",
            hasGroupContainer: true
        )
        XCTAssertEqual(report.status, .unsupportedOS)
        XCTAssertFalse(report.isBackendImplemented)
    }

    func testMissingGroupIsReported() {
        let report = WorseQueryPreflight.evaluate(
            osMajorVersion: 27,
            configuredAppGroup: nil,
            hasGroupContainer: false
        )
        XCTAssertEqual(report.status, .appGroupNotConfigured)
    }

    func testGroupMustUseAppleAppGroupPrefix() {
        let report = WorseQueryPreflight.evaluate(
            osMajorVersion: 27,
            configuredAppGroup: "com.example.aircard",
            hasGroupContainer: true
        )
        XCTAssertEqual(report.status, .appGroupNotConfigured)
    }

    func testUnavailableSignedContainerIsReported() {
        let report = WorseQueryPreflight.evaluate(
            osMajorVersion: 26,
            configuredAppGroup: "group.example.aircard",
            hasGroupContainer: false
        )
        XCTAssertEqual(report.status, .appGroupUnavailable)
    }

    func testPrerequisitesDoNotClaimImplementation() {
        let report = WorseQueryPreflight.evaluate(
            osMajorVersion: 27,
            configuredAppGroup: "group.example.aircard",
            hasGroupContainer: true
        )
        XCTAssertEqual(report.status, .prerequisitesPresent)
        XCTAssertFalse(report.isBackendImplemented)
    }
}
