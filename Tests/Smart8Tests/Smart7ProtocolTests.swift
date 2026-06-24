import XCTest
@testable import Smart8

final class Smart7ProtocolTests: XCTestCase {
    func testKnownFrames() throws {
        XCTAssertEqual(try Smart7Protocol.requestPasswordFrame(), data("99 09 00 09"))
        XCTAssertEqual(try Smart7Protocol.setTemperatureFrame(celsius: 94), data("99 0A 01 5E 69"))
        XCTAssertEqual(try Smart7Protocol.brewControlFrame(.stop), data("99 02 01 03 06"))
        XCTAssertEqual(try Smart7Protocol.drainControlFrame(start: true), data("99 03 01 01 05"))
        XCTAssertEqual(try Smart7Protocol.drainControlFrame(start: false), data("99 03 01 02 06"))
    }

    func testKnownEnvelope() throws {
        let plain = data("99 09 00 09")
        let encoded = try Smart7Protocol.encodeEnvelope(plain, key: 0x2A)
        XCTAssertEqual(encoded, data("54 51 7E B3 23 2A 23"))
        XCTAssertEqual(try Smart7Protocol.decodeEnvelope(encoded), plain)
    }

    func testSplitPlainFrames() throws {
        let combined = try Smart7Protocol.requestPasswordFrame() + Smart7Protocol.keepaliveReplyFrame()
        let frames = Smart7Protocol.splitPlainFrames(combined, requireChecksum: true)
        XCTAssertEqual(frames.map(\.command), [0x09, 0x12])
    }

    func testNotificationParserHandlesSplitEnvelopeAndCombinedPlainFrames() throws {
        let plain = try Smart7Protocol.requestPasswordFrame() + Smart7Protocol.keepaliveReplyFrame()
        let envelope = try Smart7Protocol.encodeEnvelope(plain, key: 0x2A)
        var parser = Smart7NotificationParser()
        XCTAssertEqual(try parser.append(envelope.prefix(3)), [])
        let frames = try parser.append(envelope.dropFirst(3))
        XCTAssertEqual(frames.map(\.command), [0x09, 0x12])
    }

    private func data(_ hex: String) -> Data {
        Data(hex.split(separator: " ").map { UInt8($0, radix: 16)! })
    }
}
