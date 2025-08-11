import UIKit
import Foundation

// BeaconUiConfig

/// UI configuration for BeaconBar presentation and layout
public class BeaconUiConfig: NSObject, Codable {
    
    /// Width in points (equivalent to dp in Android)
    public let width: CGFloat?
    
    /// Height in points (equivalent to dp in Android) 
    public let height: CGFloat?
    
    /// Leading margin in points
    public let marginLeading: CGFloat?
    
    /// Top margin in points
    public let marginTop: CGFloat?
    
    /// Trailing margin in points
    public let marginTrailing: CGFloat?
    
    /// Bottom margin in points
    public let marginBottom: CGFloat?
    
    /// Padding in points
    public let padding: CGFloat?
    
    /// Content alignment (equivalent to gravity in Android)
    public let alignment: BeaconAlignment
    
    /// Designated initializer
    public init(width: CGFloat? = nil,
                height: CGFloat? = nil,
                marginLeading: CGFloat? = nil,
                marginTop: CGFloat? = nil,
                marginTrailing: CGFloat? = nil,
                marginBottom: CGFloat? = nil,
                padding: CGFloat? = nil,
                alignment: BeaconAlignment = .bottomLeading) {
        self.width = width
        self.height = height
        self.marginLeading = marginLeading
        self.marginTop = marginTop
        self.marginTrailing = marginTrailing
        self.marginBottom = marginBottom
        self.padding = padding
        self.alignment = alignment
        super.init()
    }
    
    /// Convenience initializer for full screen
    @MainActor
    public static func fullScreen(padding: CGFloat = 0) -> BeaconUiConfig {
        return BeaconUiConfig(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height,
            marginLeading: 0,
            marginTop: 0,
            marginTrailing: 0,
            marginBottom: 0,
            padding: padding,
            alignment: .bottomLeading
        )
    }
    
    /// Default UI configuration
    @MainActor
    public static func `default`() -> BeaconUiConfig {
        return BeaconUiConfig(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height,
            marginLeading: 0,
            marginTop: 0,
            marginTrailing: 0,
            marginBottom: 0,
            padding: 0,
            alignment: .bottomLeading
        )
    }
    
    // Objective-C Compatibility Methods
    
    /// Objective-C compatible factory method for full screen
    @objc @MainActor
    public static func createFullScreen() -> BeaconUiConfig {
        return fullScreen()
    }
    
    /// Objective-C compatible factory method for full screen with padding
    @objc @MainActor
    public static func createFullScreen(withPadding padding: CGFloat) -> BeaconUiConfig {
        return fullScreen(padding: padding)
    }
    
    /// Objective-C compatible factory method with basic parameters
    @objc public static func create(width: CGFloat, 
                                   height: CGFloat, 
                                   marginLeading: CGFloat, 
                                   marginTop: CGFloat,
                                   marginTrailing: CGFloat,
                                   marginBottom: CGFloat) -> BeaconUiConfig {
        return BeaconUiConfig(
            width: width,
            height: height,
            marginLeading: marginLeading,
            marginTop: marginTop,
            marginTrailing: marginTrailing,
            marginBottom: marginBottom,
            padding: 0,
            alignment: .bottomLeading
        )
    }
}

// BeaconAlignment

/// Content alignment options (equivalent to Android Gravity)
@objc public enum BeaconAlignment: Int, Codable, CaseIterable {
    case topLeading = 0
    case topCenter = 1
    case topTrailing = 2
    case centerLeading = 3
    case center = 4
    case centerTrailing = 5
    case bottomLeading = 6
    case bottomCenter = 7
    case bottomTrailing = 8
    
    /// Convert to UIKit alignment
    internal var uiAlignment: (horizontal: NSLayoutConstraint.Attribute, vertical: NSLayoutConstraint.Attribute) {
        switch self {
        case .topLeading:
            return (.leading, .top)
        case .topCenter:
            return (.centerX, .top)
        case .topTrailing:
            return (.trailing, .top)
        case .centerLeading:
            return (.leading, .centerY)
        case .center:
            return (.centerX, .centerY)
        case .centerTrailing:
            return (.trailing, .centerY)
        case .bottomLeading:
            return (.leading, .bottom)
        case .bottomCenter:
            return (.centerX, .bottom)
        case .bottomTrailing:
            return (.trailing, .bottom)
        }
    }
}

// BeaconConfig

/// Main configuration object for BeaconBar
public class BeaconConfig: NSObject, Codable {
    
    /// Enable debug logging and features
    public let isDebug: Bool
    
    /// Organization identifier
    public let orgId: String
    
    /// User identifier
    public let userIdentifier: String
    
    /// Optional custom script URL
    public let scriptUrl: String?
    
    /// Optional user metadata
    public let userMetadata: [String: Any]?
    
    /// UI configuration
    public let uiConfig: BeaconUiConfig
    
    /// Designated initializer
    public init(isDebug: Bool = false,
                orgId: String,
                userIdentifier: String,
                scriptUrl: String? = nil,
                userMetadata: [String: Any]? = nil,
                uiConfig: BeaconUiConfig? = nil) {
        self.isDebug = isDebug
        self.orgId = orgId
        self.userIdentifier = userIdentifier
        self.scriptUrl = scriptUrl
        self.userMetadata = userMetadata
        
        // Use default config if none provided, but handle main actor access
        if let providedConfig = uiConfig {
            self.uiConfig = providedConfig
        } else {
            // Create a default config without accessing UIScreen.main
            self.uiConfig = BeaconUiConfig(
                width: nil, // Will be set to full width in view controller
                height: nil, // Will be set to full height in view controller
                marginLeading: 0,
                marginTop: 0,
                marginTrailing: 0,
                marginBottom: 0,
                padding: 0,
                alignment: .bottomLeading
            )
        }
        
        super.init()
    }
    
    /// Convenience initializer with minimal parameters
    public convenience init(orgId: String, userIdentifier: String) {
        self.init(
            isDebug: false,
            orgId: orgId,
            userIdentifier: userIdentifier,
            scriptUrl: nil,
            userMetadata: nil,
            uiConfig: nil
        )
    }
    
    /// Convenience initializer with debug flag
    public convenience init(orgId: String, userIdentifier: String, isDebug: Bool) {
        self.init(
            isDebug: isDebug,
            orgId: orgId,
            userIdentifier: userIdentifier,
            scriptUrl: nil,
            userMetadata: nil,
            uiConfig: nil
        )
    }
    
    // Objective-C Compatibility Methods
    
    /// Objective-C compatible initializer
    @objc public static func create(orgId: String, userIdentifier: String) -> BeaconConfig {
        return BeaconConfig(orgId: orgId, userIdentifier: userIdentifier)
    }
    
    /// Objective-C compatible initializer with debug
    @objc public static func create(orgId: String, userIdentifier: String, isDebug: Bool) -> BeaconConfig {
        return BeaconConfig(orgId: orgId, userIdentifier: userIdentifier, isDebug: isDebug)
    }
    
    /// Objective-C compatible initializer with script URL
    @objc public static func create(orgId: String, 
                                   userIdentifier: String, 
                                   scriptUrl: String?,
                                   isDebug: Bool) -> BeaconConfig {
        return BeaconConfig(
            isDebug: isDebug,
            orgId: orgId,
            userIdentifier: userIdentifier,
            scriptUrl: scriptUrl
        )
    }
    
    // Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case isDebug
        case orgId
        case userIdentifier
        case scriptUrl
        case userMetadata
        case uiConfig
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isDebug = try container.decode(Bool.self, forKey: .isDebug)
        orgId = try container.decode(String.self, forKey: .orgId)
        userIdentifier = try container.decode(String.self, forKey: .userIdentifier)
        scriptUrl = try container.decodeIfPresent(String.self, forKey: .scriptUrl)
        
        // Handle userMetadata as optional dictionary
        if let metadata = try container.decodeIfPresent([String: String].self, forKey: .userMetadata) {
            userMetadata = metadata
        } else {
            userMetadata = nil
        }
        
        uiConfig = try container.decodeIfPresent(BeaconUiConfig.self, forKey: .uiConfig) ?? BeaconUiConfig(
            width: nil,
            height: nil,
            marginLeading: 0,
            marginTop: 0,
            marginTrailing: 0,
            marginBottom: 0,
            padding: 0,
            alignment: .bottomLeading
        )
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isDebug, forKey: .isDebug)
        try container.encode(orgId, forKey: .orgId)
        try container.encode(userIdentifier, forKey: .userIdentifier)
        try container.encodeIfPresent(scriptUrl, forKey: .scriptUrl)
        
        // Encode userMetadata if it exists and contains only string values
        if let metadata = userMetadata {
            let stringMetadata = metadata.compactMapValues { $0 as? String }
            if !stringMetadata.isEmpty {
                try container.encode(stringMetadata, forKey: .userMetadata)
            }
        }
        
        try container.encode(uiConfig, forKey: .uiConfig)
    }
}

// Extensions for better Swift usage

public extension BeaconConfig {
    
    /// Create a debug configuration
    static func debug(orgId: String, userIdentifier: String, scriptUrl: String? = nil) -> BeaconConfig {
        return BeaconConfig(
            isDebug: true,
            orgId: orgId,
            userIdentifier: userIdentifier,
            scriptUrl: scriptUrl
        )
    }
    
    /// Create a production configuration
    static func production(orgId: String, userIdentifier: String, scriptUrl: String? = nil) -> BeaconConfig {
        return BeaconConfig(
            isDebug: false,
            orgId: orgId,
            userIdentifier: userIdentifier,
            scriptUrl: scriptUrl
        )
    }
}

// CustomStringConvertible

extension BeaconConfig {
    public override var description: String {
        return """
        BeaconConfig(
            isDebug: \(isDebug),
            orgId: "\(orgId)",
            userIdentifier: "\(userIdentifier)",
            scriptUrl: \(scriptUrl ?? "nil"),
            userMetadata: \(userMetadata?.description ?? "nil"),
            uiConfig: \(uiConfig)
        )
        """
    }
}

extension BeaconUiConfig {
    public override var description: String {
        return """
        BeaconUiConfig(
            width: \(width?.description ?? "nil"),
            height: \(height?.description ?? "nil"),
            margins: [\(marginLeading?.description ?? "nil"), \(marginTop?.description ?? "nil"), \(marginTrailing?.description ?? "nil"), \(marginBottom?.description ?? "nil")],
            padding: \(padding?.description ?? "nil"),
            alignment: \(alignment)
        )
        """
    }
}
