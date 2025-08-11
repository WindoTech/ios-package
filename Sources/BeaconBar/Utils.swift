import Foundation
import UIKit

/// Internal utility functions for BeaconBar SDK
internal class Utils {
    
    // Metadata Utilities
    
    /// Convert BeaconConfig userMetadata to JSON string
    /// - Parameter config: BeaconConfig instance
    /// - Returns: JSON string representation of user metadata
    internal static func getMetadata(from config: BeaconConfig) -> String {
        guard let userMetadata = config.userMetadata else {
            return "{}"
        }
        
        do {
            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: userMetadata, options: [])
            // Convert to string
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            Logger.e("Utils", "Failed to serialize userMetadata to JSON", error)
            return "{}"
        }
    }
    
    // HTML Generation
    
    /// Generate the base HTML page for WebView
    /// - Returns: HTML string for the WebView container
    internal static func getHtmlPage() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1.0, user-scalable=no">
            <title>Beacon Host</title>
            <style>
                body, html {
                  margin: 0;
                  padding: 0;
                  height: 100%;
                  width: 100%;
                  color: transparent;
                  background-color: transparent;
                  overflow: hidden;
                  -webkit-user-select: none;
                  -webkit-touch-callout: none;
                  -webkit-tap-highlight-color: transparent;
                }
                
                /* Prevent zoom on input focus */
                input, textarea, select {
                  font-size: 16px;
                }
                
                /* Smooth scrolling */
                * {
                  -webkit-overflow-scrolling: touch;
                }
            </style>
        </head>
        <body>
            <h1>.</h1>
            <!-- Beacon SDK can inject UI here -->
        </body>
        </html>
        """
    }
    
    // Script Injection

    /// Generate JavaScript injection script for BeaconBar
    /// - Parameters:
    ///   - orgId: Organization identifier
    ///   - metadata: JSON metadata string
    ///   - inlineScript: Optional inline script content
    /// - Returns: Complete JavaScript injection string
    internal static func getScriptInjection(orgId: String, metadata: String, inlineScript: String?) -> String {
        // Safely escape the inline script for JavaScript injection
        let safeInlineScript = inlineScript?
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
        
        return """
        javascript:(function (b, e, a, c, o, n, metadata) {
            const LOG_TAG = "BeaconBarJs: ✅✅"
            const ERR_TAG = "BeaconBarJs: ❌❌"
            const isLoggingEnabled = metadata.isDebug === "true";
            console.log(LOG_TAG, "Input to script -- ", JSON.stringify(metadata, null, 2));
            
            class Logger {
                log(...msg) {
                    if (isLoggingEnabled) console.log(...msg);
                }
                warn(...msg) {
                    if (isLoggingEnabled) console.warn(...msg);
                }
                error(...err) {
                    if (isLoggingEnabled) console.error(...err);
                }
            }
            const logger = new Logger();
            
            let scriptUrl = metadata.scriptUrl;
            let user = metadata.user;
            let iosBridgeName = metadata.iosBridgeName;
            
            // FIXED: Create iOS bridge helper object
            const iOSBridge = {
                speakText: (text) => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.speakText) {
                        b.webkit.messageHandlers.speakText.postMessage(text);
                    } else {
                        logger.error(ERR_TAG + "speakText handler not available");
                    }
                },
                speakCancel: () => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.speakCancel) {
                        b.webkit.messageHandlers.speakCancel.postMessage("");
                    } else {
                        logger.error(ERR_TAG + "speakCancel handler not available");
                    }
                },
                speakPause: () => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.speakPause) {
                        b.webkit.messageHandlers.speakPause.postMessage("");
                    } else {
                        logger.error(ERR_TAG + "speakPause handler not available");
                    }
                },
                speakResume: () => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.speakResume) {
                        b.webkit.messageHandlers.speakResume.postMessage("");
                    } else {
                        logger.error(ERR_TAG + "speakResume handler not available");
                    }
                },
                closeBeaconBar: () => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.closeBeaconBar) {
                        b.webkit.messageHandlers.closeBeaconBar.postMessage("");
                    } else {
                        logger.error(ERR_TAG + "closeBeaconBar handler not available");
                    }
                },
                handleFetch: (requestData, callbackId) => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.handleFetch) {
                        // FIXED: Send data in the format iOS expects
                        b.webkit.messageHandlers.handleFetch.postMessage({
                            request: requestData,
                            callbackId: callbackId
                        });
                    } else {
                        logger.error(ERR_TAG + "handleFetch handler not available");
                    }
                },
                saveFileFromBase64: (fileName, base64Data, mimeType) => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.saveFileFromBase64) {
                        b.webkit.messageHandlers.saveFileFromBase64.postMessage({
                            fileName: fileName,
                            base64Data: base64Data,
                            mimeType: mimeType
                        });
                    } else {
                        logger.error(ERR_TAG + "saveFileFromBase64 handler not available");
                    }
                },
                onJsLibraryLoaded: (message) => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.onJsLibraryLoaded) {
                        b.webkit.messageHandlers.onJsLibraryLoaded.postMessage(message);
                    } else {
                        logger.error(ERR_TAG + "onJsLibraryLoaded handler not available");
                    }
                },
                onJsLibraryLoadError: (message) => {
                    if (b.webkit && b.webkit.messageHandlers && b.webkit.messageHandlers.onJsLibraryLoadError) {
                        b.webkit.messageHandlers.onJsLibraryLoadError.postMessage(message);
                    } else {
                        logger.error(ERR_TAG + "onJsLibraryLoadError handler not available");
                    }
                }
            };
            
            b[c] = {
                closeBeaconBar: () => {
                    iOSBridge.closeBeaconBar();
                },
                platform: "android",
                orgId: n,
                open: () => { b[c].opened = true },
                user: user
            };
            
            function setBrowserStorageFromData(data) {
                try {
                    logger.log(LOG_TAG, "Setting local and session storage");
                    if (data.localStorage) {
                        logger.log(LOG_TAG, "Setting local-storage");
                        const localStorageData = JSON.parse(data.localStorage);
                        for (const key in localStorageData) {
                            if (localStorageData.hasOwnProperty(key)) {
                                localStorage.setItem(key, localStorageData[key]);
                            }
                        }
                    } else {
                        logger.warn(LOG_TAG, "Missing local-storage");
                    }
            
                    if (data.sessionStorage) {
                        logger.log(LOG_TAG, "Setting session-storage");
                        const sessionStorageData = JSON.parse(data.sessionStorage);
                        for (const key in sessionStorageData) {
                            if (sessionStorageData.hasOwnProperty(key)) {
                                sessionStorage.setItem(key, sessionStorageData[key]);
                            }
                        }
                    } else {
                        logger.warn(LOG_TAG, "Missing session-storage");
                    }
                    
                    if (data.cookies) {
                        logger.log(LOG_TAG, "Restoring cookies from document.cookie string");
                        try {
                            const cookiePairs = data.cookies.split(';').map(cookie => cookie.trim());
                            for (const pair of cookiePairs) {
                                if (pair) {
                                    document.cookie = pair + `; path=/`;
                                }
                            }
                        } catch (e) {
                            logger.error(LOG_TAG, "Failed to restore cookies:", e);
                        }
                    } else {
                        logger.warn(LOG_TAG, "No cookies to restore");
                    }
            
                    logger.log(LOG_TAG, "Storage successfully updated.");
                } catch (e) {
                    logger.error(ERR_TAG, "Failed to set storage from data:", e);
                }
            }
            
            if (user?.metaData) {
                setBrowserStorageFromData(user?.metaData);
            }

            
            // this allows print from webview
            (function () {
                let oldCreateObjectURL = URL.createObjectURL;
                URL.createObjectURL = function (blob) {
                    const url = oldCreateObjectURL(blob);
                    window._lastBlobUrl = url;
                    return url;
                };
            
                const observer = new MutationObserver(() => {
                    const iframe = document.querySelector("iframe");
                    if (iframe && iframe.contentWindow && !iframe._printHooked) {
                        iframe._printHooked = true;
                        try {
                            logger.log("✅ Hooking iframe.contentWindow.print", window._lastBlobUrl);
                            const filename = 'Ai Chat Exports.pdf';
                            saveFile(window._lastBlobUrl, filename);
                        } catch (e) {
                            logger.error("❌ Error while hooking print", e);
                        }
                    }
                });
            
                observer.observe(document.body, { childList: true, subtree: true });
            })();
            
            // intercepting speech synthesis
            (() => {
                // Create a dummy SpeechSynthesisUtterance if not already defined
                if (typeof window.SpeechSynthesisUtterance === "undefined") {
                    logger.log("✅ Creating Dummy SpeechSynthesisUtterance due to its absence");
                    window.SpeechSynthesisUtterance = function (text) {
                        this.text = text || "";
                        this.lang = "";
                        this.voice = null;
                        this.pitch = 1;
                        this.rate = 1;
                        this.volume = 1;
            
                        logger.log("✅ Creating Dummy SpeechSynthesisUtterance instance");
                        // Allow event listeners like `onend`, etc.
                        this.addEventListener = () => { };
                        this.removeEventListener = () => { };
                        this.dispatchEvent = () => { };
                    };
                }
            
                // Override speechSynthesis
                window.speechSynthesis = {
                    speak: function (utterance) {
                        logger.log("✅ speechSynthesis.speaking");
                        if (utterance && utterance.text) {
                            iOSBridge.speakText(utterance.text);
                            // simulate onend if defined
                            if (typeof utterance.onend === "function") {
                                setTimeout(() => utterance.onend(), 100);
                            }
                        }
                    },
                    cancel: function () {
                        try {
                            logger.log("✅ speechSynthesis.canceling");
                            iOSBridge.speakCancel();
                        } catch (e) {
                            logger.error("❌ speechSynthesis.cancel error", e.message);
                        }
                    },
                    pause: function () {
                        logger.log("✅ speechSynthesis.pausing");
                        iOSBridge.speakPause();
                    },
                    resume: function (input) {
                        logger.log("✅ speechSynthesis.resuming -- ", input);
                        iOSBridge.speakResume();
                    }
                };
            })();
            
            // intercepting fetch requests
            const iosFetchCallbacks = {};
            let cbIdCount = 0;
            window.handleNativeResponse = function(callbackId, responseJsonStr) {
                logger.log(LOG_TAG, "handleNativeResponse called for callbackId-- ", callbackId);
                const callback = iosFetchCallbacks[callbackId];
                if (callback) {
                    callback(responseJsonStr);
                    delete iosFetchCallbacks[callbackId]; // cleanup
                } else {
                    logger.warn(LOG_TAG, "No JS callback found for", callbackId);
                }
            };
            (() => {
                logger.log(LOG_TAG, "Overwriting fetch function");
                const originalFetch = window.fetch;
                
                window.fetch = function(input, init = {}) {
                    let url = '';
                    if (typeof input === 'string') {
                        url = input;
                    } else if (input instanceof Request) {
                        url = input.url;
                    } else if (input instanceof URL) {
                        url = input.toString();
                    } else if (typeof input?.toString === 'function') {
                        url = input.toString();
                    }
                    
                    if (url.startsWith("blob:")) {
                        logger.log(LOG_TAG, "Bypassing fetch interception for blob URL: ", url);
                        return originalFetch(input, init);
                    }
                    
                    logger.log(LOG_TAG, "intercepted fetch for url -- ", url);
                    if (!url) {
                        logger.log(LOG_TAG, " ✅✅ Url missing -- ", input, JSON.stringify(input), init, JSON.stringify(init));
                    }
                    
                    const method = init.method || 'GET';
                    const headers = init.headers || {};
                    const body = init.body || null;
                    
                    // Handle specific domain cookies (like Walmart in Android)
                    if (url.startsWith("https://seller.walmart.com")) {
                        logger.log(LOG_TAG, "Adding cookies in header", url);
                        headers.Cookie = document.cookie;
                    }
                    

                    const requestData = {
                        url,
                        method,
                        headers,
                        body
                    };
                    logger.log(LOG_TAG, "intercepted fetch for ", JSON.stringify(requestData, null, 2));

                    return new Promise((resolve, reject) => {
                        const callbackId = `cb_` + (cbIdCount++);
                        iosFetchCallbacks[callbackId] = (responseJsonStr) => {
                            try {
                                logger.log(LOG_TAG, "iOSBridge.iosFetchCallbacks success for callbackId -- ", callbackId);
                                const responseObj = JSON.parse(responseJsonStr);
                                const blob = new Blob([responseObj.body], { type: responseObj.contentType || 'application/json' });
                                const response = new Response(blob, {
                                    status: responseObj.status || 200,
                                    headers: responseObj.headers || {}
                                });
                                resolve(response);
                            } catch (e) {
                                logger.error(LOG_TAG, "iOSBridge.iosFetchCallbacks failed for callbackId -- ", callbackId);
                                reject(e);
                            }
                        };
                        // FIXED: Use the iOS bridge helper
                        iOSBridge.handleFetch(JSON.stringify(requestData), callbackId);
                    });
                };
            })();
            
            async function saveFile(href, filename) {
                logger.log(LOG_TAG + "Saving file from URL ", filename, href);
                fetch(href)
                    .then(res => res.blob())
                    .then(blob => {
                        const reader = new FileReader();
                        reader.onloadend = function () {
                            const base64data = reader.result.split(',')[1]; // Strip "data:*/*;base64,"
                            const mimeType = blob.type || "application/octet-stream";
        
                            iOSBridge.saveFileFromBase64(filename, base64data, mimeType);
                        };
                        reader.readAsDataURL(blob);
                    })
                    .catch(err => {
                        logger.error(ERR_TAG + "Error fetching blob", err);
                    });
            }
            
            // to intercept blob downloads
            document.addEventListener('click', function (e) {
                const link = e.target.closest('a');
                logger.log(LOG_TAG + "Intercepting Click ", link);
                if (!link) return;
                const href = link.getAttribute('href');
                if (href && href.startsWith('blob:')) {
                    e.preventDefault(); // Stop browser from navigating
                    logger.log(LOG_TAG + "Saving file from URL ", href);
                    const filename = 'Ai Chat Exports.txt';
                    saveFile(href, filename);
                }
            }, true);

            var d = e.createElement(o);
            d.id = "beacon-user";
            d.dataset.extension = "true";
            d.dataset.orgId = n;
            e.body.appendChild(d);

            var s = e.createElement(a);
            s.src = scriptUrl;
            s.async = true;
            s.type = 'module';

            s.onload = function() {
                logger.log(LOG_TAG + 'Beacon SDK (latest.js) has loaded via injected script.');
                logger.log(LOG_TAG + 'orgId:', BeaconBar.orgId, BeaconBar);
                
                // FIXED: Use the iOS bridge helper
                iOSBridge.onJsLibraryLoaded(LOG_TAG + ' Beacon SDK OrgId: ' + BeaconBar.orgId);
            };

            s.onerror = function(event) {
                logger.error(ERR_TAG+'Failed to load Beacon SDK (latest.js).', event?.error?.toString());
                // FIXED: Use the iOS bridge helper
                iOSBridge.onJsLibraryLoadError(ERR_TAG+'Beacon SDK (latest.js) - FAILED_TO_LOAD');
            };

            e.head.appendChild(s);
        })(window, document, 'script', 'BeaconBar', 'div', '\(orgId)', \(metadata));
        """
    }
    
    // Device Information
    
    /// Get device information for metadata
    /// - Returns: Dictionary with device information
    @MainActor
    internal static func getDeviceInfo() -> [String: Any] {
        let device = UIDevice.current
        let screen = UIScreen.main
        
        return [
            "platform": "iOS",
            "deviceModel": deviceModel(),
            "systemVersion": device.systemVersion,
            "systemName": device.systemName,
            "screenWidth": screen.bounds.width,
            "screenHeight": screen.bounds.height,
            "screenScale": screen.scale,
            "bundleId": Bundle.main.bundleIdentifier ?? "unknown",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] ?? "unknown"
        ]
    }
    
    /// Get device model string
    /// - Returns: Device model identifier
    private static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            let unicodeScalar = UnicodeScalar(UInt8(value))
            return identifier + String(unicodeScalar)
        }
        
        return identifier.isEmpty ? "Unknown" : identifier
    }
    
    // File Utilities
    
    /// Get documents directory URL
    /// - Returns: Documents directory URL
    internal static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Save data to file in documents directory
    /// - Parameters:
    ///   - data: Data to save
    ///   - fileName: File name
    /// - Returns: Success boolean
    internal static func saveDataToFile(_ data: Data, fileName: String) -> Bool {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            Logger.d("Utils", "File saved successfully: \(fileURL.path)")
            return true
        } catch {
            Logger.e("Utils", "Failed to save file: \(fileName)", error)
            return false
        }
    }
    
    /// Load data from file in documents directory
    /// - Parameter fileName: File name
    /// - Returns: Data if successful, nil otherwise
    internal static func loadDataFromFile(_ fileName: String) -> Data? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            Logger.d("Utils", "File loaded successfully: \(fileURL.path)")
            return data
        } catch {
            Logger.e("Utils", "Failed to load file: \(fileName)", error)
            return nil
        }
    }
    
    // String Utilities
    
    /// Safely escape string for JavaScript injection
    /// - Parameter string: String to escape
    /// - Returns: JavaScript-safe escaped string
    internal static func escapeForJavaScript(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
    
    /// Generate unique identifier
    /// - Returns: Unique string identifier
    internal static func generateUniqueId() -> String {
        return UUID().uuidString.lowercased()
    }
    
    // Permission Utilities
    
    /// Check if microphone permission is granted
    /// - Returns: True if granted, false otherwise
    @MainActor
    internal static func isMicrophonePermissionGranted() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied, .undetermined:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Request microphone permission
    /// - Parameter completion: Completion handler with result
    internal static func requestMicrophonePermission(completion: @escaping @MainActor (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Check if camera permission is granted
    /// - Returns: True if granted, false otherwise
    @MainActor
    internal static func isCameraPermissionGranted() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .denied, .restricted, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Request camera permission
    /// - Parameter completion: Completion handler with result
    internal static func requestCameraPermission(completion: @escaping @MainActor (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}

// Extensions

internal extension Utils {
    
    /// Convert dictionary to JSON string
    /// - Parameter dictionary: Dictionary to convert
    /// - Returns: JSON string or empty object if conversion fails
    static func dictionaryToJsonString(_ dictionary: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            Logger.e("Utils", "Failed to convert dictionary to JSON", error)
            return "{}"
        }
    }
    
    /// Parse JSON string to dictionary
    /// - Parameter jsonString: JSON string to parse
    /// - Returns: Dictionary or nil if parsing fails
    static func jsonStringToDictionary(_ jsonString: String) -> [String: Any]? {
        guard let data = jsonString.data(using: .utf8) else {
            Logger.e("Utils", "Failed to convert JSON string to data")
            return nil
        }
        
        do {
            let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return dictionary
        } catch {
            Logger.e("Utils", "Failed to parse JSON string", error)
            return nil
        }
    }
}

// Import required frameworks

import AVFoundation
