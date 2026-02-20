import Foundation

public enum LogLevel {
    case debug
    case info
    case success
    case warning
    case error

    var color: String {
        switch self {
        case .debug: return "\u{001B}[90m"  // Gray
        case .info: return "\u{001B}[36m"  // Cyan
        case .success: return "\u{001B}[32m"  // Green
        case .warning: return "\u{001B}[33m"  // Yellow
        case .error: return "\u{001B}[31m"  // Red
        }
    }

    var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .success: return "SUCCESS"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }
}

public struct Logger {
    private static let reset = "\u{001B}[0m"
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private static func log(_ level: LogLevel, _ message: String) {
        let time = dateFormatter.string(from: Date())
        print("\(level.color)[\(time)] [\(level.label)] \(message)\(reset)")
    }

    public static func debug(_ message: String) {
        log(.debug, message)
    }

    public static func info(_ message: String) {
        log(.info, message)
    }

    public static func success(_ message: String) {
        log(.success, message)
    }

    public static func warning(_ message: String) {
        log(.warning, message)
    }

    public static func error(_ message: String) {
        log(.error, message)
    }
}
