import XCTest
@testable import SnippetFlow

final class ScreenCapturerTests: XCTestCase {
    func testPermissionDeniedErrorIsActionable() {
        let message = ScreenCaptureError.permissionDenied.errorDescription ?? ""

        XCTAssertTrue(message.contains("Screen Recording"))
        XCTAssertTrue(message.contains("System Settings"))
        XCTAssertTrue(message.contains("relaunch the app"))
    }

    func testTCCFailuresAreClassifiedAsPermissionFailures() {
        XCTAssertTrue(ScreenCapturer.isPermissionFailure("could not create image from rect"))
        XCTAssertTrue(ScreenCapturer.isPermissionFailure("could not create image from display"))
        XCTAssertTrue(
            ScreenCapturer.isPermissionFailure(
                "The user declined TCCs for application, window, display capture"
            )
        )
    }

    func testUnrelatedErrorsAreNotClassifiedAsPermissionFailures() {
        XCTAssertFalse(ScreenCapturer.isPermissionFailure(""))
        XCTAssertFalse(ScreenCapturer.isPermissionFailure("The capture did not produce an image."))
    }
}
