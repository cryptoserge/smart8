import Foundation

public struct DiagnosticLogEntry: Identifiable, Equatable {
    public enum Direction: String, Equatable {
        case event = "EVENT"
        case outbound = "SEND"
        case inbound = "RECV"
        case error = "ERROR"
    }

    public let id: UUID
    public let timestamp: Date
    public let direction: Direction
    public let message: String
    public let plainHex: String?
    public let encodedHex: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        direction: Direction,
        message: String,
        plainHex: String? = nil,
        encodedHex: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.direction = direction
        self.message = message
        self.plainHex = plainHex
        self.encodedHex = encodedHex
    }

    public var displayText: String {
        let time = Self.timeFormatter.string(from: timestamp)
        var parts = ["[\(time)]", direction.rawValue, message]
        if let plainHex {
            parts.append("plain=\(plainHex)")
        }
        if let encodedHex {
            parts.append("encoded=\(encodedHex)")
        }
        return parts.joined(separator: " ")
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
