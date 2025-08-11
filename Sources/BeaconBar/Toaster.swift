import UIKit
import Foundation

/// Internal toast notification utility for BeaconBar SDK
/// Provides Android-style toast messages for iOS
internal class Toaster {
    
    // Properties
    
    /// Toast display duration options
    internal enum Duration {
        case short
        case long
        
        var timeInterval: TimeInterval {
            switch self {
            case .short:
                return 2.0
            case .long:
                return 3.5
            }
        }
    }
    
    /// Toast position on screen
    internal enum Position {
        case top
        case center
        case bottom
        
        var yOffset: CGFloat {
            switch self {
            case .top:
                return 100
            case .center:
                return 0
            case .bottom:
                return -100
            }
        }
    }
    
    /// Currently displayed toast view (to prevent overlapping)
    nonisolated(unsafe) private static var currentToastView: UIView?
    
    /// Toast animation duration
    private static let animationDuration: TimeInterval = 0.3
    
    // Public Methods
    
    /// Show toast message with default settings
    /// - Parameters:
    ///   - message: Message to display
    ///   - viewController: Optional view controller to present from (uses key window if nil)
    internal static func show(_ message: String, in viewController: UIViewController? = nil) {
        show(message, duration: .short, position: .bottom, in: viewController)
    }
    
    /// Show toast message with custom duration
    /// - Parameters:
    ///   - message: Message to display
    ///   - duration: Display duration
    ///   - viewController: Optional view controller to present from
    internal static func show(_ message: String, 
                             duration: Duration, 
                             in viewController: UIViewController? = nil) {
        show(message, duration: duration, position: .bottom, in: viewController)
    }
    
    /// Show toast message with full customization
    /// - Parameters:
    ///   - message: Message to display
    ///   - duration: Display duration
    ///   - position: Screen position
    ///   - viewController: Optional view controller to present from
    internal static func show(_ message: String,
                             duration: Duration = .short,
                             position: Position = .bottom,
                             in viewController: UIViewController? = nil) {
        
        DispatchQueue.main.async {
            // Remove any existing toast
            hideCurrentToast()
            
            // Find the appropriate view to add toast to
            guard let targetView = getTargetView(from: viewController) else {
                Logger.w("Toaster", "Cannot find target view to display toast")
                return
            }
            
            // Create toast view
            let toastView = createToastView(message: message)
            currentToastView = toastView
            
            // Add to view hierarchy
            targetView.addSubview(toastView)
            
            // Setup constraints
            setupConstraints(for: toastView, in: targetView, position: position)
            
            // Initial state (hidden)
            toastView.alpha = 0.0
            toastView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            // Animate in
            UIView.animate(withDuration: animationDuration,
                          delay: 0,
                          usingSpringWithDamping: 0.8,
                          initialSpringVelocity: 0.5,
                          options: [.curveEaseInOut, .allowUserInteraction],
                          animations: {
                toastView.alpha = 1.0
                toastView.transform = CGAffineTransform.identity
            }) { _ in
                // Schedule hide animation
                DispatchQueue.main.asyncAfter(deadline: .now() + duration.timeInterval) {
                    hideToast(toastView)
                }
            }
        }
    }
    
    /// Hide current toast immediately
    internal static func hide() {
        DispatchQueue.main.async {
            hideCurrentToast()
        }
    }
    
    // Private Methods
    
    @MainActor
    private static func getTargetView(from viewController: UIViewController?) -> UIView? {
        if let viewController = viewController {
            return viewController.view
        }
        
        // Fallback to key window
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    @MainActor
    private static func createToastView(message: String) -> UIView {
        // Container view
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 4
        containerView.layer.masksToBounds = false
        
        // Message label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(messageLabel)
        
        // Label constraints
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        return containerView
    }
    
    @MainActor
    private static func setupConstraints(for toastView: UIView, 
                                       in targetView: UIView, 
                                       position: Position) {
        
        NSLayoutConstraint.activate([
            // Horizontal centering
            toastView.centerXAnchor.constraint(equalTo: targetView.centerXAnchor),
            
            // Maximum width
            toastView.widthAnchor.constraint(lessThanOrEqualTo: targetView.widthAnchor, 
                                           multiplier: 0.8),
            toastView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
        
        // Vertical positioning
        switch position {
        case .top:
            if #available(iOS 11.0, *) {
                toastView.topAnchor.constraint(equalTo: targetView.safeAreaLayoutGuide.topAnchor, 
                                             constant: 20).isActive = true
            } else {
                toastView.topAnchor.constraint(equalTo: targetView.topAnchor, 
                                             constant: 80).isActive = true
            }
            
        case .center:
            toastView.centerYAnchor.constraint(equalTo: targetView.centerYAnchor).isActive = true
            
        case .bottom:
            if #available(iOS 11.0, *) {
                toastView.bottomAnchor.constraint(equalTo: targetView.safeAreaLayoutGuide.bottomAnchor, 
                                                constant: -20).isActive = true
            } else {
                toastView.bottomAnchor.constraint(equalTo: targetView.bottomAnchor, 
                                                constant: -80).isActive = true
            }
        }
    }
    
    @MainActor
    private static func hideCurrentToast() {
        guard let currentToast = currentToastView else { return }
        hideToast(currentToast)
    }
    
    @MainActor
    private static func hideToast(_ toastView: UIView) {
        UIView.animate(withDuration: animationDuration,
                      delay: 0,
                      options: [.curveEaseInOut, .allowUserInteraction],
                      animations: {
            toastView.alpha = 0.0
            toastView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            toastView.removeFromSuperview()
            if currentToastView == toastView {
                currentToastView = nil
            }
        }
    }
}

// Convenience Extensions

internal extension Toaster {
    
    /// Show success toast with green styling
    /// - Parameters:
    ///   - message: Success message
    ///   - viewController: Optional view controller
    static func showSuccess(_ message: String, in viewController: UIViewController? = nil) {
        show("✅ \(message)", duration: .short, in: viewController)
    }
    
    /// Show error toast with red styling
    /// - Parameters:
    ///   - message: Error message
    ///   - viewController: Optional view controller
    static func showError(_ message: String, in viewController: UIViewController? = nil) {
        show("❌ \(message)", duration: .long, in: viewController)
    }
    
    /// Show warning toast with yellow styling
    /// - Parameters:
    ///   - message: Warning message
    ///   - viewController: Optional view controller
    static func showWarning(_ message: String, in viewController: UIViewController? = nil) {
        show("⚠️ \(message)", duration: .short, in: viewController)
    }
    
    /// Show info toast with blue styling
    /// - Parameters:
    ///   - message: Info message
    ///   - viewController: Optional view controller
    static func showInfo(_ message: String, in viewController: UIViewController? = nil) {
        show("ℹ️ \(message)", duration: .short, in: viewController)
    }
    
    /// Show loading toast (typically used with manual dismissal)
    /// - Parameters:
    ///   - message: Loading message
    ///   - viewController: Optional view controller
    static func showLoading(_ message: String, in viewController: UIViewController? = nil) {
        show("⏳ \(message)", duration: .long, in: viewController)
    }
}

// Thread Safety

internal extension Toaster {
    
    /// Thread-safe show method that ensures execution on main queue
    /// - Parameters:
    ///   - message: Message to display
    ///   - duration: Display duration
    ///   - position: Screen position
    ///   - viewController: Optional view controller
    static func safeShow(_ message: String,
                        duration: Duration = .short,
                        position: Position = .bottom,
                        in viewController: UIViewController? = nil) {
        
        if Thread.isMainThread {
            show(message, duration: duration, position: position, in: viewController)
        } else {
            DispatchQueue.main.async {
                show(message, duration: duration, position: position, in: viewController)
            }
        }
    }
}
