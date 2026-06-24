import Foundation

public struct Smart7QueuedFrame {
    public let label: String
    public let delayBeforeMilliseconds: UInt64
    public let plain: Data
    fileprivate let sequenceID: UUID?
    fileprivate let isLastInSequence: Bool
    fileprivate let completion: ((Result<Void, Error>) -> Void)?
}

public final class Smart7SendQueue {
    public typealias Writer = (Smart7QueuedFrame) throws -> Void

    private let writer: Writer
    private var regularFrames: [Smart7QueuedFrame] = []
    private var priorityFrames: [Smart7QueuedFrame] = []
    private var sequenceCompletions: [UUID: (Result<Void, Error>) -> Void] = [:]
    private var isSending = false

    public init(writer: @escaping Writer) {
        self.writer = writer
    }

    public var hasPendingRegularFrames: Bool {
        !regularFrames.isEmpty
    }

    public func enqueueSequence(_ frames: [Smart7ScheduledFrame], completion: @escaping (Result<Void, Error>) -> Void) {
        guard !frames.isEmpty else {
            completion(.success(()))
            return
        }
        let sequenceID = UUID()
        sequenceCompletions[sequenceID] = completion
        regularFrames.append(contentsOf: frames.enumerated().map { index, frame in
            Smart7QueuedFrame(
                label: frame.label,
                delayBeforeMilliseconds: frame.delayBeforeMilliseconds,
                plain: frame.plain,
                sequenceID: sequenceID,
                isLastInSequence: index == frames.count - 1,
                completion: nil
            )
        })
        drain()
    }

    public func enqueuePriority(label: String, plain: Data, completion: ((Result<Void, Error>) -> Void)? = nil) {
        priorityFrames.append(Smart7QueuedFrame(
            label: label,
            delayBeforeMilliseconds: 0,
            plain: plain,
            sequenceID: nil,
            isLastInSequence: false,
            completion: completion
        ))
        drain()
    }

    public func cancelRegularFrames() {
        regularFrames.removeAll()
        sequenceCompletions.removeAll()
    }

    private func drain() {
        guard !isSending else { return }

        let frame: Smart7QueuedFrame
        if !priorityFrames.isEmpty {
            frame = priorityFrames.removeFirst()
        } else if !regularFrames.isEmpty {
            frame = regularFrames.removeFirst()
        } else {
            return
        }

        isSending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(frame.delayBeforeMilliseconds))) { [weak self] in
            guard let self else { return }
            do {
                try self.writer(frame)
                self.finish(frame, result: .success(()))
            } catch {
                self.finish(frame, result: .failure(error))
            }
        }
    }

    private func finish(_ frame: Smart7QueuedFrame, result: Result<Void, Error>) {
        isSending = false

        if let sequenceID = frame.sequenceID {
            switch result {
            case .success where frame.isLastInSequence:
                sequenceCompletions.removeValue(forKey: sequenceID)?(.success(()))
            case .success:
                break
            case .failure:
                regularFrames.removeAll { $0.sequenceID == sequenceID }
                sequenceCompletions.removeValue(forKey: sequenceID)?(result)
            }
        } else {
            frame.completion?(result)
        }

        drain()
    }
}
