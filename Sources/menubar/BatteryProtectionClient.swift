import Foundation
import notify

final class BatteryProtectionClient {
    private let prefix: String
    private var replyToken: Int32?
    var isSaving: Bool { replyToken != nil }

    init(prefix: String) { self.prefix = prefix }

    var threshold: UInt64? {
        guard let value = state("threshold"), (1...100).contains(value) else { return nil }
        return value
    }

    var isProtecting: Bool { state("low-battery") == 1 }

    private func state(_ key: String) -> UInt64? {
        var token: Int32 = 0
        guard notify_register_check("\(prefix).\(key)", &token) == NOTIFY_STATUS_OK else { return nil }
        defer { notify_cancel(token) }
        var value: UInt64 = 0
        return notify_get_state(token, &value) == NOTIFY_STATUS_OK ? value : nil
    }

    @MainActor func setThreshold(_ value: UInt64, completion: @escaping (Bool) -> Void) {
        guard !isSaving, (1...100).contains(value), threshold != nil else { return completion(false) }
        let command = "\(prefix).set-threshold"
        var commandToken: Int32 = 0
        guard notify_register_check(command, &commandToken) == NOTIFY_STATUS_OK else { return completion(false) }
        defer { notify_cancel(commandToken) }

        // Listen before posting. Only the daemon's published value confirms a save.
        var token: Int32 = 0
        let registered = notify_register_dispatch("\(prefix).threshold", &token, .main) { receivedToken in
            guard self.replyToken == receivedToken else { return }
            var applied: UInt64 = 0
            let confirmed = notify_get_state(receivedToken, &applied) == NOTIFY_STATUS_OK && applied == value
            self.finish(receivedToken, confirmed: confirmed, completion: completion)
        }
        guard registered == NOTIFY_STATUS_OK else { return completion(false) }
        replyToken = token
        guard notify_set_state(commandToken, value) == NOTIFY_STATUS_OK,
              notify_post(command) == NOTIFY_STATUS_OK else {
            return finish(token, confirmed: false, completion: completion)
        }

        let expectedToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.finish(expectedToken, confirmed: false, completion: completion)
        }
    }

    @MainActor private func finish(_ token: Int32, confirmed: Bool, completion: (Bool) -> Void) {
        guard replyToken == token else { return }
        notify_cancel(token)
        replyToken = nil
        completion(confirmed)
    }
}
