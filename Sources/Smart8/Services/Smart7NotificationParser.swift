import Foundation

public struct Smart7NotificationParser {
    private var buffer = Data()

    public init() {}

    public mutating func append(_ chunk: Data) throws -> [Smart7Frame] {
        buffer.append(chunk)
        var frames: [Smart7Frame] = []

        while true {
            guard let markerIndex = buffer.firstIndex(of: Smart7Protocol.envelopeMarker) else {
                buffer.removeAll(keepingCapacity: true)
                return frames
            }
            if markerIndex > buffer.startIndex {
                buffer.removeSubrange(buffer.startIndex..<markerIndex)
            }
            guard buffer.count >= 3 else {
                return frames
            }

            let bytes = [UInt8](buffer)
            let plainLength = Int(bytes[1] ^ Smart7Protocol.envelopeMarker) - 1
            guard plainLength >= 1 else {
                buffer.removeFirst()
                continue
            }
            let envelopeLength = plainLength + 3
            guard buffer.count >= envelopeLength else {
                return frames
            }

            let envelope = buffer.prefix(envelopeLength)
            let decoded = try Smart7Protocol.decodeEnvelope(Data(envelope))
            frames.append(contentsOf: Smart7Protocol.splitPlainFrames(decoded, requireChecksum: true))
            buffer.removeFirst(envelopeLength)
        }
    }
}
