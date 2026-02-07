import Foundation
import SwiftData

@Model
public final class SmokingEntry {
    public var id: UUID
    public var timestamp: Date

    public var dayString: String {
        timestamp.dayString
    }

    public init(timestamp: Date = .now) {
        self.id = UUID()
        self.timestamp = timestamp
    }
}
