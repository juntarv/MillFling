import Foundation

enum LaunchOptions {
    private static let arguments = ProcessInfo.processInfo.arguments
    /// Deterministic RNG + scripted throws on the demo field.
    static let demoMode = arguments.contains("-demoMode")
    /// Skips onboarding, seeds demo progress into an in-memory store and cycles the screens.
    static let screenshotTour = arguments.contains("-screenshotTour")
    static var deterministic: Bool { demoMode || screenshotTour }
}

enum Format {
    private static let grouped: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "\u{2009}"
        f.usesGroupingSeparator = true
        return f
    }()

    static func number(_ value: Int) -> String { grouped.string(from: NSNumber(value: value)) ?? "\(value)" }

    static func wind(_ value: Double) -> String {
        if abs(value) < 0.05 { return "Calm" }
        return String(format: "%.1f %@", abs(value), value >= 0 ? "E" : "W")
    }

    static func relative(_ date: Date, now: Date = Date()) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3_600 { return "\(seconds / 60) min ago" }
        if seconds < 86_400 { return "\(seconds / 3_600) h ago" }
        let days = seconds / 86_400
        if days == 1 { return "yesterday" }
        if days < 7 { return "\(days) days ago" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    static func duration(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        return s < 60 ? "\(s) s" : "\(s / 60) m \(s % 60) s"
    }

    static func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }

    static func multiplier(_ value: Double) -> String {
        value == value.rounded() ? "x\(Int(value))" : String(format: "x%.2g", value)
    }
}
