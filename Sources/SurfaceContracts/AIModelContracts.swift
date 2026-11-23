import Foundation

/// Runtime backend required to host an extension-declared AI model.
public enum AIModelRuntimeKind: String, Codable, Equatable, Sendable {
    case omlx
    case parakeet
    case custom
}

/// Declarative verification check an extension provides so `AIModelKit` can confirm
/// a downloaded model and runtime are up and running.
public enum AIModelVerificationCheck: Codable, Equatable, Sendable {
    case httpHealth(urlString: String, expectedStatus: Int)
    case pythonImport(modules: [String])
    case fileExists(relativePath: String)
}

/// Model requirement announced by an extension to `AIModelKit` (Core) for consent,
/// download, setup, and health verification.
public struct AIModelRequirement: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let runtimeKind: AIModelRuntimeKind
    public let modelIdentifier: String
    public let estimatedSizeLabel: String
    public let verificationCheck: AIModelVerificationCheck

    public init(
        id: String,
        displayName: String,
        runtimeKind: AIModelRuntimeKind,
        modelIdentifier: String,
        estimatedSizeLabel: String,
        verificationCheck: AIModelVerificationCheck
    ) {
        self.id = id
        self.displayName = displayName
        self.runtimeKind = runtimeKind
        self.modelIdentifier = modelIdentifier
        self.estimatedSizeLabel = estimatedSizeLabel
        self.verificationCheck = verificationCheck
    }
}

/// User consent state for an extension-announced AI model download.
public enum AIModelConsentState: String, Codable, Equatable, Sendable {
    case unknown
    case consented
    case declined
}

/// Lifecycle state managed by `AIModelKit` for an extension's declared model.
public enum AIModelSetupStatus: Equatable, Sendable {
    case notInstalled
    case awaitingConsent
    case downloading(progress: Double)
    case verifying
    case ready
    case failed(String)

    public var label: String {
        switch self {
        case .notInstalled: return "not_installed"
        case .awaitingConsent: return "awaiting_consent"
        case .downloading(let progress): return "downloading_\(Int((progress * 100).rounded()))"
        case .verifying: return "verifying"
        case .ready: return "ready"
        case .failed(let msg): return "failed:\(msg)"
        }
    }
}
