import UIKit
import WebKit
import AVFoundation

/// Internal WebView container that hosts the BeaconBar JavaScript library
/// Equivalent to Android's BeaconBarView
internal class BeaconBarView: UIView {
    
    // Properties
    
    /// WebView instance for hosting JavaScript
    private var webView: WKWebView!
    
    /// Configuration object
    private let config: BeaconConfig
    
    /// WebView configuration
    private var webViewConfiguration: WKWebViewConfiguration!
    
    /// JavaScript bridge interface
    private var webAppInterface: WebAppInterface!
    
    /// Flag indicating if JS library has loaded
    private var jsLibraryLoaded = false
    
    /// Queue for pending JavaScript actions
    private var pendingActions: [String] = []
    
    /// Base URL for WebView content
    private let baseUrl = "https://app.local"
    
    /// Log tag for debugging
    private let logTag = "BeaconBarView"
    
    /// Closure called when close is requested
    internal var onCloseRequested: (() -> Void)?
    
    /// Reference to presenting view controller
    private weak var presentingViewController: UIViewController?
    
    /// Metadata JSON string
    private lazy var metadata: String = {
        let orgId = config.orgId
        let userIdentifier = config.userIdentifier
        let isDebug = config.isDebug
        let scriptUrl = config.scriptUrl ?? "https://cdn-staging.beacon.li/sdk/tushar-test.js"
        
        let metadataDict: [String: Any] = [
            "isDebug": "\(isDebug)",
            "scriptUrl": scriptUrl,
            "iosBridgeName": "iOSBridge", // FIXED: Changed from "webkit.messageHandlers"
            "user": [
                "identifier": userIdentifier,
                "metaData": Utils.getMetadata(from: config)
            ]
        ]
        
        return Utils.dictionaryToJsonString(metadataDict)
    }()
    
    // Initialization
    
    init(presentingViewController: UIViewController?, config: BeaconConfig) {
        self.presentingViewController = presentingViewController
        self.config = config
        super.init(frame: .zero)
        
        Logger.d(logTag, "BeaconBarView init with config: \(config)")
        setupWebView()
        setupConstraints()
        loadContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Logger.d(logTag, "BeaconBarView deinit")
        
        // Perform cleanup synchronously in deinit to avoid capturing self
        webAppInterface?.onDestroy()
        
        // WebView cleanup operations will be handled by onDestroy method
        // which can be called explicitly before deallocation
        
        pendingActions.removeAll()
        jsLibraryLoaded = false
    }
    
    // Setup Methods
    
    private func setupWebView() {
        // Create WKWebView configuration
        webViewConfiguration = WKWebViewConfiguration()
        
        // Enable JavaScript
        webViewConfiguration.preferences.javaScriptEnabled = true
        webViewConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Configure media playback
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        // Set up user content controller for JavaScript bridge
        let userContentController = WKUserContentController()
        webViewConfiguration.userContentController = userContentController
        
        // Create and configure WebAppInterface
        webAppInterface = WebAppInterface(viewController: presentingViewController, beaconBarView: self)
        webAppInterface.registerScriptMessageHandlers(with: userContentController)
        
        // Create WebView
        webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Configure WebView settings
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = true
        
        // Enable debugging in development
        if #available(iOS 16.4, *) {
            webView.isInspectable = config.isDebug
        }
        
        addSubview(webView)
        
        Logger.d(logTag, "WebView setup completed")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func loadContent() {
        let htmlContent = Utils.getHtmlPage()
        
        guard let baseURL = URL(string: baseUrl) else {
            Logger.e(logTag, "Invalid base URL: \(baseUrl)")
            return
        }
        
        Logger.d(logTag, "Loading HTML content with base URL: \(baseUrl)")
        webView.loadHTMLString(htmlContent, baseURL: baseURL)
    }
    
    // Public Methods
    
    /// Check if WebView can go back
    internal func canGoBack() -> Bool {
        return webView.canGoBack
    }
    
    /// Navigate WebView back
    internal func goBack() {
        webView.goBack()
    }
    
    /// Called when JavaScript library is successfully loaded
    internal func onJsLibraryActuallyLoaded() {
        Logger.d(logTag, "JavaScript library loaded successfully")
        jsLibraryLoaded = true
        
        // Execute any pending JavaScript actions
        for action in pendingActions {
            executeJavaScript(action)
        }
        pendingActions.removeAll()
    }
    
    /// Called when JavaScript library fails to load
    internal func onJsLibraryLoadFailed(_ errorMessage: String) {
        Logger.e(logTag, "JavaScript library load failed: \(errorMessage)")
        jsLibraryLoaded = false
        
        // Notify presenting view controller of the error
        DispatchQueue.main.async { [weak self] in
            if let viewController = self?.presentingViewController {
                Toaster.showError("Failed to load BeaconBar library", in: viewController)
            }
        }
    }
    
    /// Send callback response to JavaScript
    internal func sendJsCallback(callbackId: String, jsonResponse: String) {
        let escapedResponse = Utils.escapeForJavaScript(jsonResponse)
        let jsCode = "if (typeof handleNativeResponse === 'function') { handleNativeResponse('\(callbackId)', '\(escapedResponse)'); }"
        
        if #available(iOS 13.0, *) {
            Task { @MainActor [weak self] in
                self?.executeJavaScript(jsCode)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.executeJavaScript(jsCode)
            }
        }
    }
    
    /// Execute JavaScript code
    @MainActor
    private func executeJavaScript(_ script: String) {
        guard jsLibraryLoaded else {
            Logger.d(logTag, "Queueing JavaScript action until library loads")
            pendingActions.append(script)
            return
        }
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                Logger.e(self.logTag, "JavaScript execution error", error)
            } else {
                Logger.d(self.logTag, "JavaScript executed successfully")
            }
        }
    }
    
    // Lifecycle Methods
    
    internal func onResume() {
        Logger.d(logTag, "BeaconBarView resumed")
        webAppInterface?.onResume()
        
        // Resume WebView if needed
        if #available(iOS 14.0, *) {
            // iOS 14+ WebView resume handling
        }
    }
    
    internal func onPause() {
        Logger.d(logTag, "BeaconBarView paused")
        webAppInterface?.onPause()
        
        // Pause WebView if needed
        if #available(iOS 14.0, *) {
            // iOS 14+ WebView pause handling
        }
    }
    
    internal func onDestroy() {
        Logger.d(logTag, "BeaconBarView destroyed")
        if #available(iOS 13.0, *) {
            Task { @MainActor [weak self] in
                self?.cleanup()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.cleanup()
            }
        }
    }
    
    @MainActor
    private func cleanup() {
        webAppInterface?.onDestroy()
        
        if let userContentController = webViewConfiguration?.userContentController {
            webAppInterface?.unregisterScriptMessageHandlers(from: userContentController)
        }
        
        // Stop loading and clear WebView
        webView?.stopLoading()
        webView?.loadHTMLString("", baseURL: nil)
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        
        // Clear caches
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: Date(timeIntervalSince1970: 0)) {
            Logger.d(self.logTag, "WebView data cleared")
        }
        
        pendingActions.removeAll()
        jsLibraryLoaded = false
    }
}

// WKNavigationDelegate

extension BeaconBarView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Logger.d(logTag, "WebView finished loading: \(webView.url?.absoluteString ?? "unknown")")
        
        guard let currentURL = webView.url,
              let baseURL = URL(string: baseUrl) else {
            Logger.w(logTag, "Invalid URL comparison")
            return
        }
        
        // Check if this is our base URL page
        if currentURL.scheme == baseURL.scheme &&
           currentURL.host == baseURL.host &&
           !jsLibraryLoaded {
            Logger.d(logTag, "Base URL page loaded, injecting JavaScript library")
            loadJsLibrary()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Logger.e(logTag, "WebView navigation failed", error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Logger.e(logTag, "WebView provisional navigation failed", error)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        Logger.d(logTag, "Navigation policy decision for: \(url.absoluteString)")
        
        // Handle blob URLs (allow them to load)
        if url.absoluteString.hasPrefix("blob:") {
            Logger.d(logTag, "Allowing blob URL navigation")
            decisionHandler(.allow)
            return
        }
        
        // Handle external URLs (open in Safari)
        if url.scheme == "http" || url.scheme == "https" {
            if url.host != URL(string: baseUrl)?.host {
                Logger.d(logTag, "Opening external URL in Safari: \(url.absoluteString)")
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        
        // Allow navigation for our base URL
        decisionHandler(.allow)
    }
}

// WKUIDelegate

extension BeaconBarView: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        Logger.d(logTag, "JavaScript alert: \(message)")
        
        let alertController = UIAlertController(title: "BeaconBar", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        
        presentingViewController?.present(alertController, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        Logger.d(logTag, "JavaScript confirm: \(message)")
        
        let alertController = UIAlertController(title: "BeaconBar", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        
        presentingViewController?.present(alertController, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        Logger.d(logTag, "JavaScript prompt: \(prompt)")
        
        let alertController = UIAlertController(title: "BeaconBar", message: prompt, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.text = defaultText
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let text = alertController.textFields?.first?.text
            completionHandler(text)
        })
        
        presentingViewController?.present(alertController, animated: true)
    }
    
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        Logger.d(logTag, "Media capture permission requested for type: \(type)")
        
        // Grant permission for microphone and camera
        decisionHandler(.grant)
    }
    
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        Logger.d(logTag, "Device orientation permission requested")
        decisionHandler(.grant)
    }
}

// JavaScript Library Loading

private extension BeaconBarView {
    
    func loadJsLibrary() {
        Logger.d(logTag, "Loading JavaScript library")
        
        // Get the JavaScript script content (this would be loaded from your app bundle or fetched)
        let inlineScript = getBeaconJsScript()
        let scriptInjection = Utils.getScriptInjection(
            orgId: config.orgId,
            metadata: metadata,
            inlineScript: inlineScript
        )
        
        webView.evaluateJavaScript(scriptInjection) { [weak self] result, error in
            if let error = error {
                Logger.e(self?.logTag ?? "BeaconBarView", "Failed to inject JavaScript library", error)
                self?.onJsLibraryLoadFailed("Script injection failed: \(error.localizedDescription)")
            } else {
                Logger.d(self?.logTag ?? "BeaconBarView", "JavaScript library injection completed")
            }
        }
    }
    
    func getBeaconJsScript() -> String? {
        // In a real implementation, you might:
        // 1. Load this from a bundled file
        // 2. Fetch it from a CDN
        // 3. Return pre-loaded script content
        
        // For now, return nil to use the CDN URL in the script injection
        return nil
    }
}

// File Upload Support (Future Enhancement)

extension BeaconBarView {
    
    // This would handle file upload functionality similar to Android's BeaconInternalActivity
    // Implementation would use UIDocumentPickerViewController
    private func handleFileUpload() {
        // Implementation for file upload support
        // This would be called from JavaScript bridge when file input is triggered
    }
}
