import Foundation

struct BatteryThreshold {
    enum Error: Swift.Error { case outOfRange }

    private static let validRange = 1...100
    private(set) var value = 10

    init(file: URL?) {
        guard let file, let text = try? String(contentsOf: file, encoding: .utf8),
              let saved = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)),
              Self.validRange.contains(saved) else { return }
        value = saved
    }

    // 先持久化，再切换实际策略；写入失败时继续沿用上一个阈值。
    mutating func set(_ requested: UInt64, file: URL?) throws -> Bool {
        guard let newValue = Int(exactly: requested), Self.validRange.contains(newValue) else {
            throw Error.outOfRange
        }
        guard newValue != value else { return false }
        if let file {
            try String(newValue).write(to: file, atomically: true, encoding: .utf8)
        }
        value = newValue
        return true
    }

    func shouldProtect(at percent: Int?, previouslyActive: Bool) -> Bool {
        if value == 100 { return true }
        guard let percent, (0...100).contains(percent) else { return previouslyActive }
        if percent <= value { return true }
        return previouslyActive && percent < min(100, value + 5)
    }
}
