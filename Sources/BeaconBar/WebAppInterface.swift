import Foundation
import WebKit
import UIKit

/// Bridge interface between JavaScript and native iOS code
/// Handles communication from WebView JavaScript to iOS native functions
internal final class WebAppInterface: NSObject, @unchecked Sendable {
    
    // Properties
    
    /// Reference to the BeaconBarView for callbacks
    private weak var beaconBarView: BeaconBarView?
    
    /// Reference to the presenting view controller
    private weak var viewController: UIViewController?
    
    /// TTS handler instance
    private let ttsHandler = TTSHandler()
    
    /// Log tag for debugging
    private let logTag = "WebAppInterface"
    
    /// HTTP session for network requests
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    /// PDF delegate references to prevent deallocation during PDF creation (legacy)
    private var pdfDelegateReferences: [Any] = []
    
    // Initialization
    
    init(viewController: UIViewController?, beaconBarView: BeaconBarView) {
        self.viewController = viewController
        self.beaconBarView = beaconBarView
        super.init()
        Logger.d(logTag, "WebAppInterface initialized")
    }
    
    deinit {
        Logger.d(logTag, "WebAppInterface deallocated")
        // Clear PDF delegate references
        pdfDelegateReferences.removeAll()
    }
    
    // Lifecycle Methods
    func onResume() {
        Logger.d(logTag, "WebAppInterface resumed")
        // Resume TTS if needed
    }
    
    func onPause() {
        Logger.d(logTag, "WebAppInterface paused")
        // Pause TTS - use iOS version check for Task API
        if #available(iOS 13.0, *) {
            Task { @MainActor [weak self] in
                self?.ttsHandler.speakPause()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.ttsHandler.speakPause()
            }
        }
    }
    
    func onDestroy() {
        Logger.d(logTag, "WebAppInterface destroyed")
        // Cancel TTS and cleanup
        if #available(iOS 13.0, *) {
            Task { @MainActor [weak self] in
                self?.ttsHandler.speakCancel()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.ttsHandler.speakCancel()
            }
        }
        
        // Clear PDF delegate references
        pdfDelegateReferences.removeAll()
    }
}

// WKScriptMessageHandler

extension WebAppInterface: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Logger.d(logTag, "Received message: \(message.name)")
        
        switch message.name {
            case "speakText":
                if let text = message.body as? String {
                    handleSpeakText(text)
                }
            case "speakCancel":
                handleSpeakCancel()
            case "speakPause":
                handleSpeakPause()
            case "speakResume":
                handleSpeakResume()
            case "onJsLibraryLoaded":
                if let messageStr = message.body as? String {
                    handleOnJsLibraryLoaded(messageStr)
                }
            case "onJsLibraryLoadError":
                if let messageStr = message.body as? String {
                    handleOnJsLibraryLoadError(messageStr)
                }
            case "sendDataToAndroid": // Keep Android name for compatibility
                if let data = message.body as? String {
                    handleSendDataToiOS(data)
                }
            case "closeBeaconBar":
                handleCloseBeaconBar()
            case "handleFetch":
                if let body = message.body as? [String: Any],
                let requestJson = body["request"] as? String,
                let callbackId = body["callbackId"] as? String {
                    handleFetch(requestJson: requestJson, callbackId: callbackId)
                }
            case "saveFileFromBase64":
                if let body = message.body as? [String: Any],
                let fileName = body["fileName"] as? String,
                let base64Data = body["base64Data"] as? String,
                let mimeType = body["mimeType"] as? String {
                    handleSaveFileFromBase64(fileName: fileName, base64Data: base64Data, mimeType: mimeType)
                }
            default:
                Logger.w(logTag, "Unknown message received: \(message.name)")
        }
    }
}

// JavaScript Bridge Methods
private extension WebAppInterface {
    
    /// Handle text-to-speech request from JavaScript
    func handleSpeakText(_ text: String) {
        Logger.d(logTag, "handleSpeakText called with text length: \(text.count)")
        if #available(iOS 13.0, *) {
            Task { @MainActor [weak self] in
                self?.ttsHandler.speakText(text)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.ttsHandler.speakText(text)
            }
        }
    }
    
    /// Handle TTS cancel request from JavaScript
    func handleSpeakCancel() {
        Logger.d(logTag, "handleSpeakCancel called")
        if #available(iOS 13.0, *) {
            Task { @MainActor [weak self] in
                self?.ttsHandler.speakCancel()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.ttsHandler.speakCancel()
            }
        }
    }
    
    /// Handle TTS pause request from JavaScript
    func handleSpeakPause() {
        Logger.d(logTag, "handleSpeakPause called")
        if #available(iOS 13.0, *) {
            Task { @MainActor [weak self] in
                self?.ttsHandler.speakPause()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.ttsHandler.speakPause()
            }
        }
    }
    
    /// Handle TTS resume request from JavaScript
    func handleSpeakResume() {
        Logger.d(logTag, "handleSpeakResume called")
        if #available(iOS 13.0, *) {
            Task { @MainActor [weak self] in
                self?.ttsHandler.speakResume()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.ttsHandler.speakResume()
            }
        }
    }
    
    /// Handle JavaScript library loaded notification
    func handleOnJsLibraryLoaded(_ message: String) {
        Logger.d(logTag, "handleOnJsLibraryLoaded: \(message)")
        
        DispatchQueue.main.async { [weak self] in
            self?.beaconBarView?.onJsLibraryActuallyLoaded()
        }
    }
    
    /// Handle JavaScript library load error
    func handleOnJsLibraryLoadError(_ message: String) {
        Logger.e(logTag, "handleOnJsLibraryLoadError: \(message)")
        
        DispatchQueue.main.async { [weak self] in
            self?.beaconBarView?.onJsLibraryLoadFailed(message)
        }
    }
    
    /// Handle data sent from JavaScript
    func handleSendDataToiOS(_ data: String) {
        Logger.d(logTag, "handleSendDataToiOS: \(data)")
        // Handle any data received from JavaScript library
        // This can be customized based on your needs
    }
    
    /// Handle close BeaconBar request from JavaScript
    func handleCloseBeaconBar() {
        Logger.d(logTag, "handleCloseBeaconBar called")
        
        DispatchQueue.main.async { [weak self] in
            self?.beaconBarView?.onCloseRequested?()
        }
    }
    
    /// Handle HTTP fetch request from JavaScript
    func handleFetch(requestJson: String, callbackId: String) {
        Logger.d(logTag, "handleFetch called with callbackId: \(callbackId)")
        
        guard let requestData = requestJson.data(using: .utf8),
              let requestDict = try? JSONSerialization.jsonObject(with: requestData) as? [String: Any],
              let urlString = requestDict["url"] as? String,
              let url = URL(string: urlString) else {
            Logger.e(logTag, "Invalid fetch request format")
            sendErrorResponse(callbackId: callbackId, error: "Invalid request format")
            return
        }
        
        let method = requestDict["method"] as? String ?? "GET"
        let headers = requestDict["headers"] as? [String: String] ?? [:]
        let body = requestDict["body"] as? String
        
        performHttpRequest(
            url: url,
            method: method,
            headers: headers,
            body: body,
            callbackId: callbackId
        )
    }
    
    /// Handle file save request from JavaScript
    func handleSaveFileFromBase64(fileName: String, base64Data: String, mimeType: String) {
        Logger.d(logTag, "handleSaveFileFromBase64: \(fileName), mimeType: \(mimeType)")
        
        // Handle HTML-to-PDF conversion
        if mimeType.contains("text/html") {
            // FIXED: Convert base64 to HTML string first
            guard let htmlData = Data(base64Encoded: base64Data),
                  let htmlString = String(data: htmlData, encoding: .utf8) else {
                Logger.e(logTag, "Failed to decode HTML data")
                DispatchQueue.main.async { [weak self] in
                    Toaster.showError("Failed to process HTML data", in: self?.viewController)
                }
                return
            }
            createPdfFromHtml(htmlString: htmlString, fileName: fileName)
            return
        }
        
        // Handle regular file saving
        saveFileFromBase64(fileName: fileName, base64Data: base64Data, mimeType: mimeType)
    }
}

// HTTP Request Handling

private extension WebAppInterface {
    
    func performHttpRequest(url: URL, method: String, headers: [String: String], body: String?, callbackId: String) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Set headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body for POST/PUT/PATCH requests
        if let body = body, !body.isEmpty {
            request.httpBody = body.data(using: .utf8)
        }
        
        Logger.d(logTag, "Performing \(method) request to: \(url)")
        
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            self?.handleHttpResponse(data: data, response: response, error: error, callbackId: callbackId)
        }.resume()
    }
    
    func handleHttpResponse(data: Data?, response: URLResponse?, error: Error?, callbackId: String) {
        if let error = error {
            Logger.e(logTag, "HTTP request failed", error)
            sendErrorResponse(callbackId: callbackId, error: error.localizedDescription)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.e(logTag, "Invalid HTTP response")
            sendErrorResponse(callbackId: callbackId, error: "Invalid response")
            return
        }
        
        let responseBody = data != nil ? String(data: data!, encoding: .utf8) ?? "" : ""
        let statusCode = httpResponse.statusCode
        
        Logger.d(logTag, "HTTP response: \(statusCode) for callbackId: \(callbackId)")
        
        // Build response headers dictionary - use allHeaderFields for all iOS versions
        var responseHeaders: [String: String] = [:]
        for (key, value) in httpResponse.allHeaderFields {
            if let keyStr = key as? String, let valueStr = value as? String {
                responseHeaders[keyStr] = valueStr
            }
        }
        
        let successResponse: [String: Any] = [
            "status": statusCode,
            "body": responseBody,
            "headers": responseHeaders,
            "contentType": httpResponse.allHeaderFields["Content-Type"] as? String ?? "application/json"
        ]
        
        sendSuccessResponse(callbackId: callbackId, response: successResponse)
    }
    
    func sendSuccessResponse(callbackId: String, response: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            
            DispatchQueue.main.async { [weak self] in
                self?.beaconBarView?.sendJsCallback(callbackId: callbackId, jsonResponse: jsonString)
            }
        } catch {
            Logger.e(logTag, "Failed to serialize success response", error)
            sendErrorResponse(callbackId: callbackId, error: "Response serialization failed")
        }
    }
    
    func sendErrorResponse(callbackId: String, error: String) {
        let errorResponse: [String: Any] = [
            "status": 500,
            "body": "Error: \(error)",
            "headers": [:]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: errorResponse)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            
            DispatchQueue.main.async { [weak self] in
                self?.beaconBarView?.sendJsCallback(callbackId: callbackId, jsonResponse: jsonString)
            }
        } catch {
            Logger.e(logTag, "Failed to serialize error response", error)
        }
    }
}

// File Handling

private extension WebAppInterface {
    
    func saveFileFromBase64(fileName: String, base64Data: String, mimeType: String) {
        guard let data = Data(base64Encoded: base64Data) else {
            Logger.e(logTag, "Invalid base64 data for file: \(fileName)")
            DispatchQueue.main.async { [weak self] in
                Toaster.showError("Failed to decode file data", in: self?.viewController)
            }
            return
        }
        
        // Handle regular file saving
        DispatchQueue.main.async { [weak self] in
            self?.presentDocumentPicker(data: data, fileName: fileName, mimeType: mimeType)
        }
    }
    
    @MainActor
    func presentDocumentPicker(data: Data, fileName: String, mimeType: String) {
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            
            if #available(iOS 14.0, *) {
                let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
                documentPicker.delegate = self
                documentPicker.modalPresentationStyle = .formSheet
                
                viewController?.present(documentPicker, animated: true) {
                    Logger.d(self.logTag, "Document picker presented for file: \(fileName)")
                }
            } else {
                // iOS 13 fallback - use activity view controller
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                activityVC.modalPresentationStyle = .formSheet
                
                viewController?.present(activityVC, animated: true) {
                    Logger.d(self.logTag, "Activity view controller presented for file: \(fileName)")
                }
            }
        } catch {
            Logger.e(logTag, "Failed to create temporary file", error)
            Toaster.showError("Failed to save file", in: viewController)
        }
    }
    
    // COMPLETELY REWRITTEN: Simplified PDF creation
    func createPdfFromHtml(htmlString: String, fileName: String) {
        Logger.d(logTag, "createPdfFromHtml: \(fileName) - using simplified approach")
        Logger.d(logTag, "HTML content length: \(htmlString.count)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Method 1: Try to create PDF from attributed string
            if let pdfData = self.createSimplePdfFromHtml(htmlString) {
                Logger.d(self.logTag, "Successfully created PDF - size: \(pdfData.count) bytes")
                self.savePdfData(pdfData: pdfData, fileName: fileName)
                return
            }
            
            // Method 2: Fallback to saving as HTML file
            Logger.d(self.logTag, "PDF creation failed, saving as HTML file")
            self.saveHtmlAsFile(htmlString, fileName: fileName)
        }
    }
    
    // SIMPLIFIED PDF CREATION
    private func createSimplePdfFromHtml(_ htmlString: String) -> Data? {
        do {
            // Clean HTML and convert to attributed string
            let cleanHtml = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body { 
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                        margin: 20px; 
                        line-height: 1.6;
                        font-size: 14px;
                    }
                </style>
            </head>
            <body>
            \(htmlString)
            </body>
            </html>
            """
            
            guard let htmlData = cleanHtml.data(using: .utf8) else {
                Logger.e(logTag, "Failed to convert HTML to data")
                return nil
            }
            
            // Create attributed string from HTML
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSAttributedString(data: htmlData, options: options, documentAttributes: nil)
            Logger.d(logTag, "Created attributed string with length: \(attributedString.length)")
            
            // Create PDF using simple text rendering
            return createPdfFromText(attributedString)
            
        } catch {
            Logger.e(logTag, "Error creating attributed string from HTML", error)
            
            // Fallback: Create PDF from plain text
            let plainText = htmlString
                .replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let attributedString = NSAttributedString(string: plainText, attributes: attributes)
            return createPdfFromText(attributedString)
        }
    }
    
    // SIMPLE PDF CREATION FROM TEXT
    private func createPdfFromText(_ attributedString: NSAttributedString) -> Data? {
        let pdfData = NSMutableData()
        
        // PDF page setup
        let pageSize = CGSize(width: 595, height: 842) // A4 size
        let margin: CGFloat = 50
        let textRect = CGRect(
            x: margin,
            y: margin,
            width: pageSize.width - (margin * 2),
            height: pageSize.height - (margin * 2)
        )
        
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: pageSize), nil)
        
        var currentLocation = 0
        var pageNumber = 0
        
        while currentLocation < attributedString.length {
            pageNumber += 1
            UIGraphicsBeginPDFPage()
            
            Logger.d(logTag, "Rendering PDF page \(pageNumber)")
            
            // Calculate how much text fits on this page
            let remainingText = attributedString.attributedSubstring(from: NSRange(location: currentLocation, length: attributedString.length - currentLocation))
            
            // Use a simple text container to measure text
            let textStorage = NSTextStorage(attributedString: remainingText)
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(size: textRect.size)
            
            textStorage.addLayoutManager(layoutManager)
            layoutManager.addTextContainer(textContainer)
            
            // Get the range of text that fits in this container
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            
            if characterRange.length > 0 {
                // Draw the text that fits on this page
                let textToDraw = remainingText.attributedSubstring(from: NSRange(location: 0, length: characterRange.length))
                textToDraw.draw(in: textRect)
                
                currentLocation += characterRange.length
            } else {
                // Safety check - if no text fits, break to avoid infinite loop
                break
            }
        }
        
        UIGraphicsEndPDFContext()
        
        Logger.d(logTag, "PDF creation completed - \(pageNumber) pages, \(pdfData.length) bytes")
        
        return pdfData.length > 0 ? (pdfData as Data) : nil
    }
    
    // FALLBACK: Save as HTML file
    private func saveHtmlAsFile(_ htmlString: String, fileName: String) {
        Logger.d(logTag, "Saving as HTML file: \(fileName)")
        
        let htmlFileName = fileName.replacingOccurrences(of: ".pdf", with: ".html")
        guard let htmlData = htmlString.data(using: .utf8) else {
            Logger.e(logTag, "Failed to convert HTML string to data")
            DispatchQueue.main.async { [weak self] in
                Toaster.showError("Failed to process content", in: self?.viewController)
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.presentDocumentPicker(data: htmlData, fileName: htmlFileName, mimeType: "text/html")
        }
    }
    
    func savePdfData(pdfData: Data, fileName: String) {
        let pdfFileName = fileName.hasSuffix(".pdf") ? fileName : "\(fileName).pdf"
        
        DispatchQueue.main.async { [weak self] in
            self?.presentDocumentPicker(data: pdfData, fileName: pdfFileName, mimeType: "application/pdf")
        }
    }
    
    // Helper to retain PDF delegate during creation (legacy - keeping for compatibility)
    func retainPdfDelegate(_ delegate: Any) {
        // No longer needed since we're not using delegates, but keeping method for compatibility
        Logger.d(logTag, "retainPdfDelegate called (legacy method)")
    }
}

// Core Text Import (add this import at the top)

import CoreText

// UIDocumentPickerDelegate

extension WebAppInterface: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Logger.d(logTag, "Document saved to: \(urls)")
        DispatchQueue.main.async { [weak self] in
            Toaster.showSuccess("File saved successfully", in: self?.viewController)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        Logger.d(logTag, "Document picker cancelled")
        
        // Clean up temporary files - iOS 14+ only has .urls property
        // For iOS 13 and below, we don't have access to the URLs, so no cleanup needed
        if #available(iOS 14.0, *) {
            let tempDir = FileManager.default.temporaryDirectory
            do {
                let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                for url in tempFiles where url.lastPathComponent.contains("tmp") {
                    try? FileManager.default.removeItem(at: url)
                }
            } catch {
                Logger.w(logTag, "Failed to clean up temporary files: \(error)")
            }
        }
    }
}

// JavaScript Method Registration

internal extension WebAppInterface {
    
    /// Register all JavaScript bridge methods with the WKUserContentController
    @MainActor
    func registerScriptMessageHandlers(with contentController: WKUserContentController) {
        let methodNames = [
            "speakText",
            "speakCancel", 
            "speakPause",
            "speakResume",
            "onJsLibraryLoaded",
            "onJsLibraryLoadError",
            "sendDataToAndroid", // Keep Android name for compatibility
            "closeBeaconBar",
            "handleFetch",
            "saveFileFromBase64"
        ]
        
        for methodName in methodNames {
            contentController.add(self, name: methodName)
            Logger.d(logTag, "Registered script message handler: \(methodName)")
        }
    }
    
    /// Unregister all JavaScript bridge methods
    @MainActor
    func unregisterScriptMessageHandlers(from contentController: WKUserContentController) {
        let methodNames = [
            "speakText",
            "speakCancel",
            "speakPause", 
            "speakResume",
            "onJsLibraryLoaded",
            "onJsLibraryLoadError",
            "sendDataToAndroid",
            "closeBeaconBar",
            "handleFetch",
            "saveFileFromBase64"
        ]
        
        for methodName in methodNames {
            contentController.removeScriptMessageHandler(forName: methodName)
            Logger.d(logTag, "Unregistered script message handler: \(methodName)")
        }
    }
}
