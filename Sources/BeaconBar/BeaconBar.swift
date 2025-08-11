import UIKit
import Foundation

/// Main public interface for BeaconBar SDK
/// This is the only class exposed to client apps
@objc public class BeaconBar: NSObject {
    
    private static let logTag = "BeaconBar"
    
    /// Launch BeaconBar with the provided configuration
    /// - Parameters:
    ///   - presentingViewController: The view controller that will present BeaconBar
    ///   - config: BeaconBar configuration object
    @MainActor
    @objc public static func launch(from presentingViewController: UIViewController, config: BeaconConfig) {
        Logger.d(logTag, "Launching BeaconBar with config: \(config)")
        
        // Update logging status based on config
        Logger.updateLoggingStatus(config.isDebug)
        
        // Create and configure the BeaconBar view controller
        let beaconBarVC = BeaconBarViewController(config: config)
        
        // Configure presentation style based on UI config
        setupPresentationStyle(for: beaconBarVC, uiConfig: config.uiConfig)
        
        // Present the BeaconBar
        presentingViewController.present(beaconBarVC, animated: true) {
            Logger.d(logTag, "BeaconBar presented successfully")
        }
    }
    
    /// Alternative launch method for SwiftUI or other contexts
    /// - Parameter config: BeaconBar configuration object
    /// - Returns: BeaconBarViewController that can be presented manually
    @MainActor
    @objc public static func createViewController(config: BeaconConfig) -> UIViewController {
        Logger.updateLoggingStatus(config.isDebug)
        let beaconBarVC = BeaconBarViewController(config: config)
        setupPresentationStyle(for: beaconBarVC, uiConfig: config.uiConfig)
        return beaconBarVC
    }
    
    // Private Helper Methods
    
    @MainActor
    private static func setupPresentationStyle(for viewController: BeaconBarViewController, uiConfig: BeaconUiConfig) {
        // Configure modal presentation style
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        
        // Store UI config for later use in view controller
        viewController.uiConfig = uiConfig
    }
}

// Objective-C Compatibility Extensions

@objc public extension BeaconBar {
    
    /// Objective-C compatible launch method
    /// - Parameters:
    ///   - presentingViewController: The view controller that will present BeaconBar
    ///   - orgId: Organization identifier
    ///   - userIdentifier: User identifier
    ///   - isDebug: Debug mode flag
    @MainActor
    static func launchObjC(from presentingViewController: UIViewController, 
                          orgId: String, 
                          userIdentifier: String, 
                          isDebug: Bool) {
        let config = BeaconConfig(
            isDebug: isDebug,
            orgId: orgId,
            userIdentifier: userIdentifier
        )
        launch(from: presentingViewController, config: config)
    }
    
    /// Objective-C compatible launch method with script URL
    /// - Parameters:
    ///   - presentingViewController: The view controller that will present BeaconBar
    ///   - orgId: Organization identifier
    ///   - userIdentifier: User identifier
    ///   - scriptUrl: Custom script URL
    ///   - isDebug: Debug mode flag
    @MainActor
    static func launchObjC(from presentingViewController: UIViewController,
                          orgId: String,
                          userIdentifier: String,
                          scriptUrl: String?,
                          isDebug: Bool) {
        let config = BeaconConfig(
            isDebug: isDebug,
            orgId: orgId,
            userIdentifier: userIdentifier,
            scriptUrl: scriptUrl
        )
        launch(from: presentingViewController, config: config)
    }
}
