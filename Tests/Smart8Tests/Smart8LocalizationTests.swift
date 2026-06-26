import XCTest
@testable import Smart8

final class Smart8LocalizationTests: XCTestCase {
    func testEnglishCopyReturnsEnglishInterfaceLabels() {
        let copy = Smart8Copy(language: .english)

        XCTAssertEqual(copy.startBrewing, "Start brew")
        XCTAssertEqual(copy.stopBrewing, "Stop brew")
        XCTAssertEqual(copy.drainWater, "Drain water")
        XCTAssertEqual(copy.setDefaultRecipe, "Make default")
    }

    func testJapaneseCopyReturnsJapaneseInterfaceLabels() {
        let copy = Smart8Copy(language: .japanese)

        XCTAssertEqual(copy.startBrewing, "抽出開始")
        XCTAssertEqual(copy.stopBrewing, "抽出停止")
        XCTAssertEqual(copy.drainWater, "残水排出")
        XCTAssertEqual(copy.setDefaultRecipe, "このレシピを既定にする")
    }

    func testConnectionStatusMapsKnownJapaneseStatusesToEnglish() {
        let copy = Smart8Copy(language: .english)

        XCTAssertEqual(copy.connectionStatus("未接続"), "Not connected")
        XCTAssertEqual(copy.connectionStatus("5秒後に排水開始"), "5 sec until drain starts")
        XCTAssertEqual(copy.connectionStatus("接続中: EVS-70"), "Connecting: EVS-70")
    }
}
