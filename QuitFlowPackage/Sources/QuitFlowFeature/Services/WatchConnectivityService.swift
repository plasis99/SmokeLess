import Foundation
import WatchConnectivity

@MainActor
@Observable
public final class WatchConnectivityService: NSObject, @unchecked Sendable {
    public static let shared = WatchConnectivityService()

    public var isReachable = false

    /// Called when new entries arrive from the counterpart device
    public var onEntriesReceived: (([SmokingEntryTransfer]) -> Void)?
    /// Called when a delete request arrives from the counterpart device
    public var onEntryDeleted: ((UUID) -> Void)?

    private override init() {
        super.init()
    }

    public func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Send a newly logged cigarette to the counterpart
    public func sendNewEntry(_ transfer: SmokingEntryTransfer) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        var data = transfer.toDictionary()
        data["type"] = "newEntry"

        if session.isReachable {
            session.sendMessage(data, replyHandler: nil)
        } else {
            session.transferUserInfo(data)
        }
    }

    /// Send a delete request to the counterpart (for undo)
    public func sendDeleteEntry(_ id: UUID) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let data: [String: Any] = [
            "type": "deleteEntry",
            "id": id.uuidString
        ]

        if session.isReachable {
            session.sendMessage(data, replyHandler: nil)
        } else {
            session.transferUserInfo(data)
        }
    }

    /// Send all local entries to counterpart for initial sync
    public func sendAllEntries(_ entries: [SmokingEntryTransfer]) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let entriesData = entries.map { $0.toDictionary() }
        let data: [String: Any] = [
            "type": "fullSync",
            "entries": entriesData
        ]

        if session.isReachable {
            session.sendMessage(data, replyHandler: nil)
        } else {
            session.transferUserInfo(data)
        }
    }

    // MARK: - Private

    /// Parsed message types that are Sendable, extracted before crossing isolation boundary
    private enum ReceivedMessage: Sendable {
        case newEntry(SmokingEntryTransfer)
        case deleteEntry(UUID)
        case fullSync([SmokingEntryTransfer])
    }

    /// Parse data on the calling (nonisolated) thread, then dispatch Sendable result to MainActor
    nonisolated private func handleReceivedData(_ data: [String: Any]) {
        // Parse everything here — no crossing of non-Sendable [String: Any]
        guard let type = data["type"] as? String else { return }

        let message: ReceivedMessage?
        switch type {
        case "newEntry":
            if let transfer = SmokingEntryTransfer.from(dictionary: data) {
                message = .newEntry(transfer)
            } else {
                message = nil
            }
        case "deleteEntry":
            if let idString = data["id"] as? String, let id = UUID(uuidString: idString) {
                message = .deleteEntry(id)
            } else {
                message = nil
            }
        case "fullSync":
            if let entriesData = data["entries"] as? [[String: Any]] {
                let transfers = entriesData.compactMap { SmokingEntryTransfer.from(dictionary: $0) }
                message = transfers.isEmpty ? nil : .fullSync(transfers)
            } else {
                message = nil
            }
        default:
            message = nil
        }

        guard let message else { return }
        Task { @MainActor in
            switch message {
            case .newEntry(let transfer):
                self.onEntriesReceived?([transfer])
            case .deleteEntry(let id):
                self.onEntryDeleted?(id)
            case .fullSync(let transfers):
                self.onEntriesReceived?(transfers)
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
        }
    }

    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleReceivedData(message)
    }

    nonisolated public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleReceivedData(userInfo)
    }

    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
        }
    }

    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
