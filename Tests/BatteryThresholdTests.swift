import Foundation

@main
struct BatteryThresholdTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("threshold")
        var threshold = BatteryThreshold(file: file)
        precondition(threshold.value == 10)
        for text in ["", "invalid", "0", "101", "-1"] {
            try text.write(to: file, atomically: true, encoding: .utf8)
            precondition(BatteryThreshold(file: file).value == 10)
        }

        for value in 1...100 {
            let changed = try threshold.set(UInt64(value), file: nil)
            precondition(changed)
            for percent in 0...100 {
                let starting = threshold.shouldProtect(at: percent, previouslyActive: false)
                let recovering = threshold.shouldProtect(at: percent, previouslyActive: true)
                precondition(starting == (percent <= value))
                precondition(recovering == (percent <= value || percent < min(100, value + 5)))
            }
        }
        precondition(threshold.shouldProtect(at: nil, previouslyActive: false))
        print("PASS: threshold and recovery boundaries across all battery percentages")

        let changed = try threshold.set(37, file: file)
        precondition(changed && BatteryThreshold(file: file).value == 37)
        let inaccessible = directory.appendingPathComponent("missing/file")
        let repeated = try threshold.set(37, file: inaccessible)
        precondition(!repeated)
        precondition(threshold.shouldProtect(at: 39, previouslyActive: true))
        precondition(!threshold.shouldProtect(at: 39, previouslyActive: false))
        precondition(threshold.shouldProtect(at: nil, previouslyActive: true))
        precondition(!threshold.shouldProtect(at: nil, previouslyActive: false))
        print("PASS: saved threshold reloads and repeat requests preserve hysteresis")

        for invalid: UInt64 in [0, 101, UInt64.max] {
            do {
                _ = try threshold.set(invalid, file: file)
                preconditionFailure("Accepted out-of-range threshold")
            } catch BatteryThreshold.Error.outOfRange {}
            precondition(threshold.value == 37 && BatteryThreshold(file: file).value == 37)
        }
        do {
            _ = try threshold.set(67, file: inaccessible)
            preconditionFailure("Reported success for failed write")
        } catch let error as CocoaError {
            precondition(error.code == .fileNoSuchFile)
        }
        precondition(threshold.value == 37 && BatteryThreshold(file: file).value == 37)
        print("PASS: missing or invalid files fall back, rejected or failed writes preserve the last value")
    }
}
