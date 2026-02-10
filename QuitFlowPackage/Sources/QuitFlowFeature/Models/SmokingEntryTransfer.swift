import Foundation

public struct SmokingEntryTransfer: Codable, Sendable, Identifiable {
    public let id: UUID
    public let timestamp: Date

    public init(id: UUID, timestamp: Date) {
        self.id = id
        self.timestamp = timestamp
    }

    public init(from entry: SmokingEntry) {
        self.id = entry.id
        self.timestamp = entry.timestamp
    }

    public func toDictionary() -> [String: Any] {
        [
            "id": id.uuidString,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }

    public static func from(dictionary: [String: Any]) -> SmokingEntryTransfer? {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestamp = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        return SmokingEntryTransfer(id: id, timestamp: Date(timeIntervalSince1970: timestamp))
    }
}
