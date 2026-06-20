import Foundation

enum TimeFormatter {
    static let stopwatch = StopwatchFormatter(showTenths: true)
    static let short = StopwatchFormatter(showTenths: false)
}

struct StopwatchFormatter {
    let showTenths: Bool

    func string(from value: TimeInterval?) -> String {
        guard let value else { return "—" }
        return string(from: value)
    }

    func string(from value: TimeInterval) -> String {
        let clamped = max(0, value)
        let minutes = Int(clamped) / 60
        let seconds = Int(clamped) % 60

        if showTenths {
            let tenths = Int((clamped * 10).rounded(.down)) % 10
            return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
