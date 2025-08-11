import Foundation
import os.log

/// Internal logging utility for BeaconBar SDK
internal class Logger {
    
    // Properties
    
    /// Simple logging flag - we'll accept the concurrency warning for simplicity
    nonisolated(unsafe) private static var isLoggingEnabled: Bool = false
    
    /// OSLog subsystem identifier
    private static let subsystem = "com.beaconbar.sdk"
    
    /// Default log category
    private static let defaultCategory = "BeaconBar"
    
    /// OSLog instance for structured logging (iOS 14+)
    @available(iOS 14.0, *)
    private static let osLog = os.Logger(subsystem: subsystem, category: defaultCategory)
    
    /// OSLog instance for iOS 12-13 compatibility
    @available(iOS 12.0, *)
    private static let legacyOSLog = OSLog(subsystem: subsystem, category: defaultCategory)
    
    // Public Methods
    
    /// Update global logging status
    /// - Parameter enabled: Whether logging should be enabled
    internal static func updateLoggingStatus(_ enabled: Bool) {
        isLoggingEnabled = enabled
        if enabled {
            print("🟢 DEBUG [Logger] Logging status updated: \(enabled)")
        }
    }
    
    /// Log debug message
    /// - Parameters:
    ///   - tag: Log tag/category
    ///   - message: Message to log
    ///   - file: Source file (automatically captured)
    ///   - function: Source function (automatically captured)
    ///   - line: Source line (automatically captured)
    internal static func d(_ tag: String, 
                          _ message: String,
                          file: String = #file,
                          function: String = #function,
                          line: Int = #line) {
        guard isLoggingEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(tag)] \(message)"
        
        if #available(iOS 14.0, *) {
            osLog.debug("\(logMessage)")
        } else if #available(iOS 12.0, *) {
            os_log("%@", log: legacyOSLog, type: .debug, logMessage)
        } else {
            NSLog("🟢 DEBUG [\(fileName):\(line)] \(logMessage)")
        }
        
        // Also print to console for Xcode debugging
        print("🟢 DEBUG [\(fileName):\(line)] \(logMessage)")
    }
    
    /// Log info message
    /// - Parameters:
    ///   - tag: Log tag/category
    ///   - message: Message to log
    ///   - file: Source file (automatically captured)
    ///   - function: Source function (automatically captured)
    ///   - line: Source line (automatically captured)
    internal static func i(_ tag: String,
                          _ message: String,
                          file: String = #file,
                          function: String = #function,
                          line: Int = #line) {
        guard isLoggingEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(tag)] \(message)"
        
        if #available(iOS 14.0, *) {
            osLog.info("\(logMessage)")
        } else if #available(iOS 12.0, *) {
            os_log("%@", log: legacyOSLog, type: .info, logMessage)
        } else {
            NSLog("🔵 INFO [\(fileName):\(line)] \(logMessage)")
        }
        
        print("🔵 INFO [\(fileName):\(line)] \(logMessage)")
    }
    
    /// Log warning message
    /// - Parameters:
    ///   - tag: Log tag/category
    ///   - message: Message to log
    ///   - file: Source file (automatically captured)
    ///   - function: Source function (automatically captured)
    ///   - line: Source line (automatically captured)
    internal static func w(_ tag: String,
                          _ message: String,
                          file: String = #file,
                          function: String = #function,
                          line: Int = #line) {
        guard isLoggingEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(tag)] \(message)"
        
        if #available(iOS 14.0, *) {
            osLog.warning("\(logMessage)")
        } else if #available(iOS 12.0, *) {
            os_log("%@", log: legacyOSLog, type: .default, logMessage)
        } else {
            NSLog("🟡 WARN [\(fileName):\(line)] \(logMessage)")
        }
        
        print("🟡 WARN [\(fileName):\(line)] \(logMessage)")
    }
    
    /// Log error message
    /// - Parameters:
    ///   - tag: Log tag/category
    ///   - message: Message to log
    ///   - error: Optional error object
    ///   - file: Source file (automatically captured)
    ///   - function: Source function (automatically captured)
    ///   - line: Source line (automatically captured)
    internal static func e(_ tag: String,
                          _ message: String,
                          _ error: Error? = nil,
                          file: String = #file,
                          function: String = #function,
                          line: Int = #line) {
        guard isLoggingEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "[\(tag)] \(message)"
        
        if let error = error {
            logMessage += " Error: \(error.localizedDescription)"
        }
        
        if #available(iOS 14.0, *) {
            osLog.error("\(logMessage)")
        } else if #available(iOS 12.0, *) {
            os_log("%@", log: legacyOSLog, type: .error, logMessage)
        } else {
            NSLog("🔴 ERROR [\(fileName):\(line)] \(logMessage)")
        }
        
        print("🔴 ERROR [\(fileName):\(line)] \(logMessage)")
        
        // Print stack trace for errors if available
        if let error = error {
            print("🔴 ERROR Stack trace: \(error)")
        }
    }
    
    /// Log fatal error message (always logs regardless of logging status)
    /// - Parameters:
    ///   - tag: Log tag/category
    ///   - message: Message to log
    ///   - error: Optional error object
    ///   - file: Source file (automatically captured)
    ///   - function: Source function (automatically captured)
    ///   - line: Source line (automatically captured)
    internal static func fatal(_ tag: String,
                              _ message: String,
                              _ error: Error? = nil,
                              file: String = #file,
                              function: String = #function,
                              line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "[\(tag)] FATAL: \(message)"
        
        if let error = error {
            logMessage += " Error: \(error.localizedDescription)"
        }
        
        if #available(iOS 14.0, *) {
            osLog.fault("\(logMessage)")
        } else if #available(iOS 12.0, *) {
            os_log("%@", log: legacyOSLog, type: .fault, logMessage)
        } else {
            NSLog("💀 FATAL [\(fileName):\(line)] \(logMessage)")
        }
        
        print("💀 FATAL [\(fileName):\(line)] \(logMessage)")
        
        if let error = error {
            print("💀 FATAL Stack trace: \(error)")
        }
    }
}
