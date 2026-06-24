import Foundation

public enum Smart7ProtocolError: Error, Equatable, CustomStringConvertible {
    case invalidByte(name: String, value: Int)
    case emptyPlainData
    case dataTooLong
    case plainFrameTooShort
    case invalidPlainMarker(UInt8)
    case plainLengthMismatch(declared: Int, actual: Int)
    case checksumMismatch(expected: UInt8, actual: UInt8)
    case encodedDataTooShort
    case invalidEnvelopeMarker(UInt8)
    case envelopeLengthMismatch(declared: Int, actual: Int)
    case invalidRecipe(String)
    case invalidPasswordChallenge

    public var description: String {
        switch self {
        case let .invalidByte(name, value):
            return "\(name) must be 0...255; got \(value)"
        case .emptyPlainData:
            return "Plain data must not be empty"
        case .dataTooLong:
            return "Data is too long for the one-byte Smart7 length field"
        case .plainFrameTooShort:
            return "Plain frame is shorter than 4 bytes"
        case let .invalidPlainMarker(value):
            return String(format: "Plain marker must be 0x99; got 0x%02X", value)
        case let .plainLengthMismatch(declared, actual):
            return "Plain frame length mismatch: declared \(declared), actual \(actual)"
        case let .checksumMismatch(expected, actual):
            return String(format: "Checksum mismatch: expected 0x%02X, got 0x%02X", expected, actual)
        case .encodedDataTooShort:
            return "Encoded data must be at least 4 bytes"
        case let .invalidEnvelopeMarker(value):
            return String(format: "Envelope marker must be 0x54; got 0x%02X", value)
        case let .envelopeLengthMismatch(declared, actual):
            return "Envelope length mismatch: declared \(declared), actual \(actual)"
        case let .invalidRecipe(message):
            return message
        case .invalidPasswordChallenge:
            return "The frame is not a usable six-digit password challenge"
        }
    }
}

public enum Smart7Command: UInt8 {
    case recipeStep = 0x01
    case brewControl = 0x02
    case errorOrDrainControl = 0x03
    case getStatus = 0x04
    case resetRecipe = 0x05
    case flowCalibrationResponse = 0x06
    case passwordChallenge = 0x07
    case keepaliveRequest = 0x08
    case requestPassword = 0x09
    case setTemperature = 0x0A
    case setFlowCalibration = 0x0B
    case getFlowCalibration = 0x0C
    case cleanControl = 0x0D
    case acceptSession = 0x0F
    case openPasswordEntry = 0x10
    case cancelSession = 0x11
    case keepaliveReply = 0x12
}

public enum Smart7BrewAction: UInt8 {
    case startOrResume = 0x01
    case pause = 0x02
    case stop = 0x03
}

public struct Smart7Frame: Equatable {
    public let command: UInt8
    public let payload: Data
    public let raw: Data
    public let checksumIsValid: Bool
}

public struct Smart7RecipeStep: Codable, Equatable {
    public var volumeML: Int
    public var pourSeconds: Int
    public var intervalSeconds: Int

    public init(volumeML: Int, pourSeconds: Int, intervalSeconds: Int) {
        self.volumeML = volumeML
        self.pourSeconds = pourSeconds
        self.intervalSeconds = intervalSeconds
    }

    fileprivate func validate() throws {
        guard (0...2550).contains(volumeML), volumeML.isMultiple(of: 10) else {
            throw Smart7ProtocolError.invalidRecipe("volumeML must be 0...2550 and a multiple of 10")
        }
        guard (0...255).contains(pourSeconds) else {
            throw Smart7ProtocolError.invalidRecipe("pourSeconds must be 0...255")
        }
        guard (0...255).contains(intervalSeconds) else {
            throw Smart7ProtocolError.invalidRecipe("intervalSeconds must be 0...255")
        }
    }
}

public struct Smart7ScheduledFrame: Equatable {
    public let label: String
    public let delayBeforeMilliseconds: UInt64
    public let plain: Data

    public init(label: String, delayBeforeMilliseconds: UInt64, plain: Data) {
        self.label = label
        self.delayBeforeMilliseconds = delayBeforeMilliseconds
        self.plain = plain
    }

    public func encoded(key: UInt8? = nil) throws -> Data {
        try Smart7Protocol.encodeEnvelope(plain, key: key)
    }
}

public enum Smart7Protocol {
    public static let serviceUUID = "00001000-0000-1000-8000-00805f9b34fb"
    public static let writeUUID = "00001001-0000-1000-8000-00805f9b34fb"
    public static let notifyUUID = "00001002-0000-1000-8000-00805f9b34fb"
    public static let cccdUUID = "00002902-0000-1000-8000-00805f9b34fb"
    public static let deviceNameSubstring = "EVS-70"

    public static let plainMarker: UInt8 = 0x99
    public static let envelopeMarker: UInt8 = 0x54

    private static func byte(_ value: Int, name: String) throws -> UInt8 {
        guard (0...255).contains(value) else {
            throw Smart7ProtocolError.invalidByte(name: name, value: value)
        }
        return UInt8(value)
    }

    public static func makeFrame(command: UInt8, payload: Data = Data()) throws -> Data {
        guard payload.count <= 255 else { throw Smart7ProtocolError.dataTooLong }
        let payloadBytes = [UInt8](payload)
        let checksumValue = (Int(command) + payloadBytes.count + payloadBytes.reduce(0) { $0 + Int($1) }) & 0xFF
        var result = Data([plainMarker, command, UInt8(payloadBytes.count)])
        result.append(payload)
        result.append(UInt8(checksumValue))
        return result
    }

    public static func makeFrame(command: Smart7Command, payload: Data = Data()) throws -> Data {
        try makeFrame(command: command.rawValue, payload: payload)
    }

    public static func parseFrame(_ raw: Data, requireChecksum: Bool = true) throws -> Smart7Frame {
        let bytes = [UInt8](raw)
        guard bytes.count >= 4 else { throw Smart7ProtocolError.plainFrameTooShort }
        guard bytes[0] == plainMarker else {
            throw Smart7ProtocolError.invalidPlainMarker(bytes[0])
        }
        let declaredLength = Int(bytes[2]) + 4
        guard bytes.count == declaredLength else {
            throw Smart7ProtocolError.plainLengthMismatch(declared: declaredLength, actual: bytes.count)
        }
        let expected = UInt8(bytes[1..<(bytes.count - 1)].reduce(0) { ($0 + Int($1)) & 0xFF })
        let actual = bytes[bytes.count - 1]
        let checksumIsValid = expected == actual
        if requireChecksum && !checksumIsValid {
            throw Smart7ProtocolError.checksumMismatch(expected: expected, actual: actual)
        }
        return Smart7Frame(
            command: bytes[1],
            payload: Data(bytes[3..<(bytes.count - 1)]),
            raw: raw,
            checksumIsValid: checksumIsValid
        )
    }

    public static func splitPlainFrames(_ decoded: Data, requireChecksum: Bool = false) -> [Smart7Frame] {
        let bytes = [UInt8](decoded)
        var frames: [Smart7Frame] = []
        var cursor = 0
        while cursor < bytes.count {
            guard let start = bytes[cursor...].firstIndex(of: plainMarker) else { break }
            guard bytes.count - start >= 3 else { break }
            let total = Int(bytes[start + 2]) + 4
            let end = start + total
            guard end <= bytes.count else { break }
            if let frame = try? parseFrame(Data(bytes[start..<end]), requireChecksum: requireChecksum) {
                frames.append(frame)
            }
            cursor = end
        }
        return frames
    }

    public static func encodeEnvelope(_ plain: Data, key: UInt8? = nil) throws -> Data {
        let plainBytes = [UInt8](plain)
        guard !plainBytes.isEmpty else { throw Smart7ProtocolError.emptyPlainData }
        guard plainBytes.count <= 254 else { throw Smart7ProtocolError.dataTooLong }
        let xorKey = key ?? UInt8.random(in: .min ... .max)
        var result = Data([
            envelopeMarker,
            UInt8(plainBytes.count + 1) ^ envelopeMarker,
            xorKey ^ envelopeMarker
        ])
        result.append(contentsOf: plainBytes.map { $0 ^ xorKey })
        return result
    }

    public static func decodeEnvelope(_ encoded: Data, validateHeader: Bool = true) throws -> Data {
        let bytes = [UInt8](encoded)
        guard bytes.count > 3 else { throw Smart7ProtocolError.encodedDataTooShort }
        if validateHeader {
            guard bytes[0] == envelopeMarker else {
                throw Smart7ProtocolError.invalidEnvelopeMarker(bytes[0])
            }
            let declared = Int(bytes[1] ^ envelopeMarker) - 1
            let actual = bytes.count - 3
            guard declared == actual else {
                throw Smart7ProtocolError.envelopeLengthMismatch(declared: declared, actual: actual)
            }
        }
        let key = bytes[2] ^ bytes[0]
        return Data(bytes.dropFirst(3).map { $0 ^ key })
    }

    public static func requestPasswordFrame() throws -> Data {
        try makeFrame(command: .requestPassword)
    }

    public static func acceptSessionFrame() throws -> Data {
        try makeFrame(command: .acceptSession)
    }

    public static func cancelSessionFrame() throws -> Data {
        try makeFrame(command: .cancelSession)
    }

    public static func keepaliveReplyFrame() throws -> Data {
        try makeFrame(command: .keepaliveReply)
    }

    public static func brewControlFrame(_ action: Smart7BrewAction) throws -> Data {
        try makeFrame(command: .brewControl, payload: Data([action.rawValue]))
    }

    public static func resetRecipeFrame() throws -> Data {
        try makeFrame(command: .resetRecipe)
    }

    public static func recipeStepFrame(number: Int, step: Smart7RecipeStep) throws -> Data {
        try step.validate()
        let numberByte = try byte(number, name: "step number")
        guard numberByte != 0 else {
            throw Smart7ProtocolError.invalidRecipe("Step number is 1-based")
        }
        return try makeFrame(command: .recipeStep, payload: Data([
            numberByte,
            UInt8(step.volumeML / 10),
            UInt8(step.pourSeconds),
            UInt8(step.intervalSeconds)
        ]))
    }

    public static func setTemperatureFrame(celsius: Int) throws -> Data {
        try makeFrame(command: .setTemperature, payload: Data([try byte(celsius, name: "temperature")]))
    }

    public static func getStatusFrame() throws -> Data {
        try makeFrame(command: .getStatus)
    }

    public static func drainControlFrame(start: Bool) throws -> Data {
        try makeFrame(command: .errorOrDrainControl, payload: Data([start ? 1 : 2]))
    }

    public static func recipeSequence(temperatureCelsius: Int, steps: [Smart7RecipeStep]) throws -> [Smart7ScheduledFrame] {
        guard !steps.isEmpty else {
            throw Smart7ProtocolError.invalidRecipe("At least one recipe step is required")
        }
        var result = [Smart7ScheduledFrame(label: "レシピ初期化", delayBeforeMilliseconds: 0, plain: try resetRecipeFrame())]
        for (offset, step) in steps.enumerated() {
            result.append(Smart7ScheduledFrame(
                label: "工程\(offset + 1)",
                delayBeforeMilliseconds: 200,
                plain: try recipeStepFrame(number: offset + 1, step: step)
            ))
        }
        result.append(Smart7ScheduledFrame(label: "温度設定", delayBeforeMilliseconds: 100, plain: try setTemperatureFrame(celsius: temperatureCelsius)))
        result.append(Smart7ScheduledFrame(label: "抽出開始", delayBeforeMilliseconds: 100, plain: try brewControlFrame(.startOrResume)))
        return result
    }

    public static func password(from challenge: Smart7Frame) throws -> String {
        guard challenge.command == Smart7Command.passwordChallenge.rawValue else {
            throw Smart7ProtocolError.invalidPasswordChallenge
        }
        let bytes = [UInt8](challenge.payload.prefix(6))
        guard bytes.count == 6 else { throw Smart7ProtocolError.invalidPasswordChallenge }
        if bytes.allSatisfy({ (0x30...0x39).contains($0) }) {
            return String(bytes: bytes, encoding: .ascii)!
        }
        let lowNibbles = bytes.map { $0 & 0x0F }
        guard lowNibbles.allSatisfy({ $0 <= 9 }) else {
            throw Smart7ProtocolError.invalidPasswordChallenge
        }
        return lowNibbles.map(String.init).joined()
    }

    public static func hex(_ data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
