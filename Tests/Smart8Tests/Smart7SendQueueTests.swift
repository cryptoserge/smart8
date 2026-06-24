import XCTest
@testable import Smart8

final class Smart7SendQueueTests: XCTestCase {
    func testFailureStopsRemainingRegularFrames() throws {
        let expectation = expectation(description: "sequence fails")
        var sent: [String] = []
        enum Failure: Error { case step }

        let queue = Smart7SendQueue { frame in
            sent.append(frame.label)
            if frame.label == "工程1" {
                throw Failure.step
            }
        }

        let frames = [
            Smart7ScheduledFrame(label: "レシピ初期化", delayBeforeMilliseconds: 0, plain: Data([0x01])),
            Smart7ScheduledFrame(label: "工程1", delayBeforeMilliseconds: 0, plain: Data([0x02])),
            Smart7ScheduledFrame(label: "抽出開始", delayBeforeMilliseconds: 0, plain: Data([0x03]))
        ]
        queue.enqueueSequence(frames) { result in
            if case .failure = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(sent, ["レシピ初期化", "工程1"])
    }

    func testPriorityFrameRunsBeforeQueuedRegularFrame() {
        let expectation = expectation(description: "priority sent")
        var sent: [String] = []

        let queue = Smart7SendQueue { frame in
            sent.append(frame.label)
            if sent.count == 2 {
                expectation.fulfill()
            }
        }

        queue.enqueueSequence([
            Smart7ScheduledFrame(label: "通常1", delayBeforeMilliseconds: 0, plain: Data([0x01])),
            Smart7ScheduledFrame(label: "通常2", delayBeforeMilliseconds: 0, plain: Data([0x02]))
        ]) { _ in }
        queue.enqueuePriority(label: "停止", plain: Data([0x03]))

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(sent.prefix(2), ["通常1", "停止"])
    }
}
