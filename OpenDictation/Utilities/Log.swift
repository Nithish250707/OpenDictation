import os

/// Central loggers, one per subsystem area.
/// Never log secrets, API keys, request headers, or transcript contents.
enum Log {
    private static let subsystem = "org.opendictation.OpenDictation"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    static let paste = Logger(subsystem: subsystem, category: "paste")
}
