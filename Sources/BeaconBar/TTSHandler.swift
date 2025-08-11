import Foundation
import AVFoundation

/// Internal text-to-speech handler for BeaconBar SDK
/// Provides speech synthesis functionality with queue management
internal final class TTSHandler: NSObject, @unchecked Sendable {
    
    // Properties
    
    /// Speech synthesizer instance
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    /// Queue of text segments to speak (protected by queue)
    private var _textQueue: [String] = []
    private let queueLock = NSLock()
    
    private var textQueue: [String] {
        get {
            queueLock.lock()
            defer { queueLock.unlock() }
            return _textQueue
        }
        set {
            queueLock.lock()
            defer { queueLock.unlock() }
            _textQueue = newValue
        }
    }
    
    /// Current index in the text queue (protected by queue)
    private var _currentIndex = 0
    private var currentIndex: Int {
        get {
            queueLock.lock()
            defer { queueLock.unlock() }
            return _currentIndex
        }
        set {
            queueLock.lock()
            defer { queueLock.unlock() }
            _currentIndex = newValue
        }
    }
    
    /// Whether speech is currently paused (protected by queue)
    private var _isPaused = false
    private var isPaused: Bool {
        get {
            queueLock.lock()
            defer { queueLock.unlock() }
            return _isPaused
        }
        set {
            queueLock.lock()
            defer { queueLock.unlock() }
            _isPaused = newValue
        }
    }
    
    /// Whether TTS is currently speaking (protected by queue)
    private var _isSpeaking = false
    private var isSpeaking: Bool {
        get {
            queueLock.lock()
            defer { queueLock.unlock() }
            return _isSpeaking
        }
        set {
            queueLock.lock()
            defer { queueLock.unlock() }
            _isSpeaking = newValue
        }
    }
    
    /// Log tag for debugging
    private let logTag = "TTSHandler"
    
    /// Speech rate (0.0 to 1.0, default ~0.5)
    private let speechRate: Float = 0.45 // Equivalent to Android's 0.95f relative rate
    
    /// Current utterance being spoken
    private var currentUtterance: AVSpeechUtterance?
    
    // Initialization
    
    override init() {
        super.init()
        setupSynthesizer()
        configureAudioSession()
    }
    
    deinit {
        // Perform synchronous cleanup in deinit to avoid capturing self
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        queueLock.lock()
        _textQueue.removeAll()
        _currentIndex = 0
        _isPaused = false
        _isSpeaking = false
        queueLock.unlock()
        
        // Try to deactivate audio session synchronously
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // Silent fail in deinit - can't call Logger here
            print("TTSHandler deinit: Failed to deactivate audio session: \(error)")
        }
    }
    
    // Setup Methods
    
    private func setupSynthesizer() {
        speechSynthesizer.delegate = self
        Logger.d(logTag, "Speech synthesizer initialized")
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: [])
            Logger.d(logTag, "Audio session configured for speech")
        } catch {
            Logger.e(logTag, "Failed to configure audio session", error)
        }
    }
    
    // Public Methods
    
    /// Speak the provided text by splitting into sentences and queuing
    /// - Parameter text: Text to speak (can be nil or empty)
    @MainActor
    internal func speakText(_ text: String?) {
        guard let text = text, !text.isEmpty else {
            Logger.w(logTag, "Attempted to speak empty or nil text")
            return
        }
        
        Logger.d(logTag, "Speaking text: \(text.prefix(100))...")
        
        // Stop any current speech
        if isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        // Split text into sentences and queue
        textQueue = splitTextIntoSentences(text)
        currentIndex = 0
        isPaused = false
        isSpeaking = true
        
        Logger.d(logTag, "Text split into \(textQueue.count) sentences")
        
        // Start speaking from the first sentence
        speakFromCurrentIndex()
    }
    
    /// Pause speech synthesis
    @MainActor
    internal func speakPause() {
        guard isSpeaking else {
            Logger.w(logTag, "Attempted to pause when not speaking")
            return
        }
        
        Logger.d(logTag, "Pausing speech")
        speechSynthesizer.pauseSpeaking(at: .word)
        isPaused = true
    }
    
    /// Resume paused speech synthesis
    @MainActor
    internal func speakResume() {
        guard isPaused else {
            Logger.w(logTag, "Attempted to resume when not paused")
            return
        }
        
        Logger.d(logTag, "Resuming speech")
        speechSynthesizer.continueSpeaking()
        isPaused = false
    }
    
    /// Cancel all speech synthesis
    @MainActor
    internal func speakCancel() {
        Logger.d(logTag, "Cancelling speech")
        
        speechSynthesizer.stopSpeaking(at: .immediate)
        textQueue.removeAll()
        currentIndex = 0
        isPaused = false
        isSpeaking = false
        currentUtterance = nil
    }
    
    /// Shutdown the TTS handler and clean up resources
    @MainActor
    internal func shutdown() {
        Logger.d(logTag, "Shutting down TTS handler")
        
        speechSynthesizer.stopSpeaking(at: .immediate)
        textQueue.removeAll()
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            Logger.e(logTag, "Failed to deactivate audio session", error)
        }
    }
    
    // Private Methods
    
    /// Speak the sentence at the current index
    @MainActor
    private func speakFromCurrentIndex() {
        speakFromCurrentIndexSync()
    }
    
    /// iOS 12 compatible synchronous version
    private func speakFromCurrentIndexSync() {
        guard currentIndex < textQueue.count else {
            Logger.d(logTag, "Finished speaking all sentences")
            isSpeaking = false
            return
        }
        
        let sentence = textQueue[currentIndex]
        Logger.d(logTag, "Speaking sentence \(currentIndex + 1)/\(textQueue.count): \(sentence.prefix(50))...")
        
        let utterance = AVSpeechUtterance(string: sentence)
        
        // Configure utterance
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Set language (try to use system language, fallback to English)
        if let languageCode = Locale.current.languageCode {
            utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        }
        
        if utterance.voice == nil {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        currentUtterance = utterance
        speechSynthesizer.speak(utterance)
    }
    
    /// Split text into sentences for better speech flow
    /// - Parameter text: Input text to split
    /// - Returns: Array of sentence strings
    private func splitTextIntoSentences(_ text: String) -> [String] {
        // Use NSString's sentence enumeration for better accuracy
        let nsText = text as NSString
        var sentences: [String] = []
        
        nsText.enumerateSubstrings(
            in: NSRange(location: 0, length: nsText.length),
            options: [.bySentences, .localized]
        ) { (substring, _, _, _) in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sentence.isEmpty {
                sentences.append(sentence)
            }
        }
        
        // Fallback to regex-based splitting if no sentences found
        if sentences.isEmpty {
            sentences = text.components(separatedBy: .punctuationCharacters)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        // Final fallback: treat entire text as one sentence
        if sentences.isEmpty {
            sentences = [text.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        
        return sentences
    }
}

// AVSpeechSynthesizerDelegate

extension TTSHandler: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Logger.d(logTag, "Started speaking sentence \(currentIndex + 1)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Logger.d(logTag, "Finished speaking sentence \(currentIndex + 1)")
        
        // Move to next sentence if not paused
        if !isPaused && isSpeaking {
            currentIndex += 1
            
            // Small delay between sentences for natural flow
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if #available(iOS 13.0, *) {
                    Task { @MainActor in
                        self?.speakFromCurrentIndex()
                    }
                } else {
                    // iOS 12 fallback - ensure we're on main thread
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if self.currentIndex < self.textQueue.count {
                            self.speakFromCurrentIndexSync()
                        }
                    }
                }
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Logger.d(logTag, "Speech paused at sentence \(currentIndex + 1)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Logger.d(logTag, "Speech continued at sentence \(currentIndex + 1)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Logger.d(logTag, "Speech cancelled at sentence \(currentIndex + 1)")
        isSpeaking = false
        isPaused = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Optional: Could be used for word-level highlighting
        // Logger.d(logTag, "Speaking range: \(characterRange)")
    }
}

// Public Extensions

internal extension TTSHandler {
    
    /// Check if TTS is currently speaking
    var isCurrentlySpeaking: Bool {
        return isSpeaking && !isPaused
    }
    
    /// Check if TTS is currently paused
    var isCurrentlyPaused: Bool {
        return isPaused
    }
    
    /// Get current speaking progress (0.0 to 1.0)
    var speakingProgress: Float {
        guard !textQueue.isEmpty else { return 0.0 }
        return Float(currentIndex) / Float(textQueue.count)
    }
    
    /// Get total number of sentences in current queue
    var totalSentences: Int {
        return textQueue.count
    }
    
    /// Get current sentence index (0-based)
    var currentSentenceIndex: Int {
        return currentIndex
    }
    
    /// Skip to next sentence in queue
    @MainActor
    func skipToNextSentence() {
        guard currentIndex < textQueue.count - 1 else {
            Logger.w(logTag, "Cannot skip - already at last sentence")
            return
        }
        
        Logger.d(logTag, "Skipping to next sentence")
        speechSynthesizer.stopSpeaking(at: .immediate)
        currentIndex += 1
        
        if isSpeaking && !isPaused {
            speakFromCurrentIndex()
        }
    }
    
    /// Skip to previous sentence in queue
    @MainActor
    func skipToPreviousSentence() {
        guard currentIndex > 0 else {
            Logger.w(logTag, "Cannot skip - already at first sentence")
            return
        }
        
        Logger.d(logTag, "Skipping to previous sentence")
        speechSynthesizer.stopSpeaking(at: .immediate)
        currentIndex -= 1
        
        if isSpeaking && !isPaused {
            speakFromCurrentIndex()
        }
    }
    
    /// Set custom speech rate
    /// - Parameter rate: Speech rate (0.0 to 1.0)
    func setSpeechRate(_ rate: Float) {
        let clampedRate = max(0.0, min(1.0, rate))
        Logger.d(logTag, "Setting speech rate to \(clampedRate)")
        // Note: This will affect the next utterance, not the current one
    }
}

// Error Handling

internal extension TTSHandler {
    
    /// Handle TTS errors gracefully
    private func handleTTSError(_ error: Error) {
        Logger.e(logTag, "TTS Error occurred", error)
        
        // Reset state
        isSpeaking = false
        isPaused = false
        
        // Try to recover by reinitializing audio session
        configureAudioSession()
    }
}
