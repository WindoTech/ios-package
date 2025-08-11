import UIKit
import AVFoundation

/// Main view controller for BeaconBar presentation
/// Equivalent to Android's BeaconBarActivity
internal class BeaconBarViewController: UIViewController {
    
    // Properties
    
    /// BeaconBar configuration
    private let config: BeaconConfig
    
    /// BeaconBar view instance
    private var beaconBarView: BeaconBarView!
    
    /// Container view for BeaconBar
    private var containerView: UIView!
    
    /// UI configuration (set from BeaconBar.swift)
    internal var uiConfig: BeaconUiConfig!
    
    /// Log tag for debugging
    private let logTag = "BeaconBarViewController"
    
    /// Permissions that need to be requested
    private var permissionsToRequest: [Permission] = []
    
    /// Permission types
    private enum Permission {
        case microphone
        case camera
        
        var description: String {
            switch self {
            case .microphone:
                return "Microphone"
            case .camera:
                return "Camera"
            }
        }
    }
    
    // Initialization
    
    init(config: BeaconConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
        Logger.d(logTag, "BeaconBarViewController initialized with config: \(config)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Logger.d(logTag, "BeaconBarViewController deallocated")
    }
    
    // View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Logger.d(logTag, "viewDidLoad")
        
        // Set up the view hierarchy
        setupViewController()
        
        // Request necessary permissions
        requestRuntimePermissions()
        
        // Create and configure BeaconBar view
        setupBeaconBarView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Logger.d(logTag, "viewWillAppear")
        
        // Configure status bar
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.d(logTag, "viewDidAppear")
        
        beaconBarView?.onResume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Logger.d(logTag, "viewWillDisappear")
        
        beaconBarView?.onPause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Logger.d(logTag, "viewDidDisappear")
    }
    
    // Setup Methods
    
    private func setupViewController() {
        // Set background color to clear for overlay effect
        view.backgroundColor = UIColor.clear
        
        // Allow interaction with underlying views if needed
        view.isUserInteractionEnabled = true
        
        // Create container view
        containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        Logger.d(logTag, "View controller setup completed")
    }
    
    private func setupBeaconBarView() {
        // Create BeaconBar view
        beaconBarView = BeaconBarView(presentingViewController: self, config: config)
        beaconBarView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set close callback
        beaconBarView.onCloseRequested = { [weak self] in
            Logger.d(self?.logTag ?? "BeaconBarViewController", "Close requested")
            self?.dismissBeaconBar()
        }
        
        // Add to container
        containerView.addSubview(beaconBarView)
        
        // Apply UI configuration and constraints
        setupBeaconBarConstraints()
        
        Logger.d(logTag, "BeaconBar view setup completed")
    }
    
    private func setupBeaconBarConstraints() {
        guard let uiConfig = uiConfig else {
            // Use default full-screen constraints
            NSLayoutConstraint.activate([
                beaconBarView.topAnchor.constraint(equalTo: containerView.topAnchor),
                beaconBarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                beaconBarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                beaconBarView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: view.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            return
        }
        
        // Apply custom UI configuration
        var beaconBarConstraints: [NSLayoutConstraint] = []
        var containerConstraints: [NSLayoutConstraint] = []
        
        // Width constraint
        if let width = uiConfig.width {
            beaconBarConstraints.append(
                beaconBarView.widthAnchor.constraint(equalToConstant: width)
            )
        } else {
            beaconBarConstraints.append(
                beaconBarView.widthAnchor.constraint(equalTo: containerView.widthAnchor)
            )
        }
        
        // Height constraint
        if let height = uiConfig.height {
            beaconBarConstraints.append(
                beaconBarView.heightAnchor.constraint(equalToConstant: height)
            )
        } else {
            beaconBarConstraints.append(
                beaconBarView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
            )
        }
        
        // Alignment constraints
        let alignment = uiConfig.alignment.uiAlignment
        
        // Horizontal alignment
        switch alignment.horizontal {
        case .leading:
            beaconBarConstraints.append(
                beaconBarView.leadingAnchor.constraint(
                    equalTo: containerView.leadingAnchor,
                    constant: uiConfig.marginLeading ?? 0
                )
            )
        case .trailing:
            beaconBarConstraints.append(
                beaconBarView.trailingAnchor.constraint(
                    equalTo: containerView.trailingAnchor,
                    constant: -(uiConfig.marginTrailing ?? 0)
                )
            )
        case .centerX:
            beaconBarConstraints.append(
                beaconBarView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
            )
        default:
            break
        }
        
        // Vertical alignment
        switch alignment.vertical {
        case .top:
            beaconBarConstraints.append(
                beaconBarView.topAnchor.constraint(
                    equalTo: containerView.safeAreaLayoutGuide.topAnchor,
                    constant: uiConfig.marginTop ?? 0
                )
            )
        case .bottom:
            beaconBarConstraints.append(
                beaconBarView.bottomAnchor.constraint(
                    equalTo: containerView.safeAreaLayoutGuide.bottomAnchor,
                    constant: -(uiConfig.marginBottom ?? 0)
                )
            )
        case .centerY:
            beaconBarConstraints.append(
                beaconBarView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            )
        default:
            break
        }
        
        // Container constraints (full screen)
        containerConstraints = [
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        
        // Apply padding if specified
        if let padding = uiConfig.padding {
            containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: padding,
                leading: padding,
                bottom: padding,
                trailing: padding
            )
        }
        
        // Activate all constraints
        NSLayoutConstraint.activate(beaconBarConstraints + containerConstraints)
        
        Logger.d(logTag, "Applied custom UI configuration: \(uiConfig)")
    }
    
    // Permission Handling
    
    private func requestRuntimePermissions() {
        // Only request permissions if Info.plist keys are present
        guard hasPermissionKeys() else {
            Logger.w(logTag, "Permission keys not found in Info.plist - skipping permission requests")
            showPermissionSetupWarning()
            return
        }
        
        // Check which permissions need to be requested
        checkPermissionStatus()
        
        // Request permissions if needed
        if !permissionsToRequest.isEmpty {
            requestNextPermission()
        }
    }
    
    private func hasPermissionKeys() -> Bool {
        let bundle = Bundle.main
        let hasMicrophone = bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil
        let hasCamera = bundle.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil
        
        return hasMicrophone || hasCamera
    }
    
    private func showPermissionSetupWarning() {
        guard config.isDebug else { return }
        
        let message = """
        BeaconBar Setup Required:
        
        Add these keys to your app's Info.plist:
        • NSMicrophoneUsageDescription
        • NSCameraUsageDescription
        
        See BeaconBar documentation for details.
        """
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let alert = UIAlertController(title: "BeaconBar Setup", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    private func checkPermissionStatus() {
        permissionsToRequest.removeAll()
        
        // Check microphone permission
        if !Utils.isMicrophonePermissionGranted() {
            permissionsToRequest.append(.microphone)
        }
        
        // Check camera permission
        if !Utils.isCameraPermissionGranted() {
            permissionsToRequest.append(.camera)
        }
        
        Logger.d(logTag, "Permissions to request: \(permissionsToRequest.map { $0.description })")
    }
    
    private func requestNextPermission() {
        guard !permissionsToRequest.isEmpty else {
            Logger.d(logTag, "All permissions processed")
            return
        }
        
        let permission = permissionsToRequest.removeFirst()
        
        switch permission {
            case .microphone:
                requestMicrophonePermission()
            case .camera:
                requestCameraPermission()
        }
    }
    
    private func requestMicrophonePermission() {
        Logger.d(logTag, "Requesting microphone permission")
        
        Utils.requestMicrophonePermission { [weak self] granted in
            if granted {
                Logger.d(self?.logTag ?? "BeaconBarViewController", "Microphone permission granted")
            } else {
                Logger.w(self?.logTag ?? "BeaconBarViewController", "Microphone permission denied")
                self?.showPermissionDeniedAlert(for: "Microphone")
            }
            
            // Request next permission
            self?.requestNextPermission()
        }
    }
    
    private func requestCameraPermission() {
        Logger.d(logTag, "Requesting camera permission")
        
        Utils.requestCameraPermission { [weak self] granted in
            if granted {
                Logger.d(self?.logTag ?? "BeaconBarViewController", "Camera permission granted")
            } else {
                Logger.w(self?.logTag ?? "BeaconBarViewController", "Camera permission denied")
                self?.showPermissionDeniedAlert(for: "Camera")
            }
            
            // Request next permission
            self?.requestNextPermission()
        }
    }
    
    private func showPermissionDeniedAlert(for permissionType: String) {
        let alert = UIAlertController(
            title: "Permission Denied",
            message: "\(permissionType) access was denied. Some features may not work properly.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            self.openAppSettings()
        })
        
        present(alert, animated: true)
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
    
    // Navigation Handling
    
    /// Dismiss BeaconBar (equivalent to Android's finish())
    private func dismissBeaconBar() {
        Logger.d(logTag, "Dismissing BeaconBar")
        
        // Clean up BeaconBar view
        beaconBarView?.onDestroy()
        
        // Dismiss the view controller
        dismiss(animated: true) {
            Logger.d(self.logTag, "BeaconBar dismissed successfully")
        }
    }
    
    // Status Bar Configuration
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    // Back Button Handling (iOS equivalent of onBackPressed)
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            // Handle shake gesture if needed
        }
    }
    
    // Handle swipe gestures for back navigation
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right {
            handleBackNavigation()
        }
    }
    
    private func handleBackNavigation() {
        if beaconBarView.canGoBack() {
            Logger.d(logTag, "Navigating back in WebView")
            beaconBarView.goBack()
        } else {
            Logger.d(logTag, "No WebView history, dismissing BeaconBar")
            dismissBeaconBar()
        }
    }
    
    // Memory Management
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Logger.w(logTag, "Memory warning received")
        
        // Handle memory pressure
        if !isViewLoaded || view.window == nil {
            beaconBarView?.onDestroy()
            beaconBarView = nil
        }
    }
}

// Gesture Recognizer Setup

extension BeaconBarViewController {
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Add swipe gesture recognizer for back navigation
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        // Remove existing gesture recognizers to avoid duplicates
        view.gestureRecognizers?.removeAll()
        
        // Add swipe gesture for back navigation
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
        
        Logger.d(logTag, "Gesture recognizers setup completed")
    }
}

// Debug Helpers

#if DEBUG
extension BeaconBarViewController {
    
    /// Add debug overlay for development
    private func addDebugOverlay() {
        guard config.isDebug else { return }
        
        let debugLabel = UILabel()
        debugLabel.text = "DEBUG MODE"
        debugLabel.textColor = .red
        debugLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        debugLabel.textAlignment = .center
        debugLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        debugLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(debugLabel)
        
        NSLayoutConstraint.activate([
            debugLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            debugLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    /// Log view hierarchy for debugging
    private func logViewHierarchy() {
        Logger.d(logTag, "View hierarchy:")
        Logger.d(logTag, "- View: \(view.frame)")
        Logger.d(logTag, "- Container: \(containerView.frame)")
        Logger.d(logTag, "- BeaconBarView: \(beaconBarView.frame)")
    }
}
#endif
