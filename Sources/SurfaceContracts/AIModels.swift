import Foundation

/// Supported local OpenAI-compatible runtime kinds.
public enum LocalAIProviderKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case appleIntelligence = "apple_intelligence"
    case ollama
    case omlx
    case llamaCpp = "llama_cpp"
    case custom

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .appleIntelligence: return "Apple Intelligence (On-Device)"
        case .ollama: return "Ollama"
        case .omlx: return "oMLX"
        case .llamaCpp: return "llama.cpp"
        case .custom: return "Custom OpenAI-Compatible"
        }
    }

    public var defaultBaseURL: String {
        switch self {
        case .appleIntelligence: return "apple://foundation-models"
        case .ollama: return "http://127.0.0.1:11434/v1"
        case .omlx: return "http://127.0.0.1:8000/v1"
        case .llamaCpp: return "http://127.0.0.1:8080/v1"
        case .custom: return "http://127.0.0.1:8080/v1"
        }
    }

    public var iconName: String {
        switch self {
        case .appleIntelligence: return "apple.intelligence"
        case .ollama: return "cpu.fill"
        case .omlx: return "bolt.horizontal.fill"
        case .llamaCpp: return "terminal.fill"
        case .custom: return "server.rack"
        }
    }
}

/// Configuration for a single local OpenAI-compatible AI endpoint (users may configure multiple).
public struct LocalAIProviderConfig: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var kind: LocalAIProviderKind
    public var baseURL: String
    public var isEnabled: Bool
    public var defaultModel: String?
    public var discoveredModels: [String]
    public var isReachable: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        kind: LocalAIProviderKind,
        baseURL: String? = nil,
        isEnabled: Bool = true,
        defaultModel: String? = nil,
        discoveredModels: [String] = [],
        isReachable: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.baseURL = baseURL ?? kind.defaultBaseURL
        self.isEnabled = isEnabled
        self.defaultModel = defaultModel
        self.discoveredModels = discoveredModels
        self.isReachable = isReachable
    }
}

/// Supported cloud AI providers authenticated via CLI login.
public enum CloudAIProviderKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case openai
    case claude
    case gemini
    case openrouter
    case githubCopilot = "github_copilot"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .openai: return "OpenAI"
        case .claude: return "Claude"
        case .gemini: return "Gemini"
        case .openrouter: return "OpenRouter"
        case .githubCopilot: return "GitHub Copilot"
        }
    }

    public var cliCommandHint: String {
        switch self {
        case .openai: return "codex login"
        case .claude: return "claude login"
        case .gemini: return "gemini auth login"
        case .openrouter: return "openrouter login"
        case .githubCopilot: return "gh auth login"
        }
    }

    public var suggestedModels: [String] {
        switch self {
        case .openai: return ["gpt-5.4", "gpt-5.4-mini", "gpt-4.1", "whisper-1"]
        case .claude: return ["claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5"]
        case .gemini: return ["gemini-2.5-pro", "gemini-2.5-flash", "gemini-2.5-flash-lite"]
        case .openrouter: return ["openai/gpt-5.4", "anthropic/claude-sonnet-4-6", "nvidia/parakeet-tdt-0.6b-v2"]
        case .githubCopilot: return ["gpt-5.4", "claude-sonnet-4-6", "gemini-2.5-pro"]
        }
    }
}

public enum CloudAIAuthStatus: String, Codable, Equatable, Sendable {
    case notConfigured = "not_configured"
    case signedOut = "signed_out"
    case authenticated
    case error
}

/// Configuration & auth status for a cloud AI provider.
public struct CloudAIProviderConfig: Codable, Equatable, Identifiable, Sendable {
    public var id: String { provider.rawValue }
    public let provider: CloudAIProviderKind
    public var isEnabled: Bool
    public var authStatus: CloudAIAuthStatus
    public var accountLabel: String?
    public var defaultModel: String?
    public var availableModels: [String]

    public init(
        provider: CloudAIProviderKind,
        isEnabled: Bool = false,
        authStatus: CloudAIAuthStatus = .notConfigured,
        accountLabel: String? = nil,
        defaultModel: String? = nil,
        availableModels: [String]? = nil
    ) {
        self.provider = provider
        self.isEnabled = isEnabled
        self.authStatus = authStatus
        self.accountLabel = accountLabel
        self.defaultModel = defaultModel ?? provider.suggestedModels.first
        self.availableModels = availableModels ?? provider.suggestedModels
    }
}

/// Approval policy for a built-in AI feature or an extension declaring AI access.
public enum AIApprovalPolicy: String, CaseIterable, Codable, Sendable {
    case requireApproval = "require_approval"
    case alwaysAllow = "always_allow"

    public var title: String {
        switch self {
        case .requireApproval: return "Require Approval Per Request"
        case .alwaysAllow: return "Always Allow (Automatic)"
        }
    }
}

/// Per-caller (built-in or extension) AI access policy entry.
public struct AICallerPolicyEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { callerId }
    public let callerId: String
    public var callerName: String
    public let isBuiltIn: Bool
    public var policy: AIApprovalPolicy

    public init(
        callerId: String,
        callerName: String,
        isBuiltIn: Bool,
        policy: AIApprovalPolicy = .requireApproval
    ) {
        self.callerId = callerId
        self.callerName = callerName
        self.isBuiltIn = isBuiltIn
        self.policy = policy
    }
}

public enum AIPendingRequestStatus: String, Codable, Equatable, Sendable {
    case pending
    case approved
    case denied
}

/// Queued AI inference or transcription request awaiting explicit user approval.
public struct AIPendingRequest: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let callerId: String
    public let callerName: String
    public let providerLabel: String
    public let model: String
    public let promptPreview: String
    public let createdAt: Date
    public var status: AIPendingRequestStatus

    public init(
        id: String = UUID().uuidString,
        callerId: String,
        callerName: String,
        providerLabel: String,
        model: String,
        promptPreview: String,
        createdAt: Date = Date(),
        status: AIPendingRequestStatus = .pending
    ) {
        self.id = id
        self.callerId = callerId
        self.callerName = callerName
        self.providerLabel = providerLabel
        self.model = model
        self.promptPreview = promptPreview
        self.createdAt = createdAt
        self.status = status
    }
}

/// Metered AI usage counters across callers and providers.
public struct AIUsageSummary: Codable, Equatable, Sendable {
    public var totalRequests: Int
    public var totalPromptTokens: Int
    public var totalCompletionTokens: Int
    public var requestsByCaller: [String: Int]

    public init(
        totalRequests: Int = 0,
        totalPromptTokens: Int = 0,
        totalCompletionTokens: Int = 0,
        requestsByCaller: [String: Int] = [:]
    ) {
        self.totalRequests = totalRequests
        self.totalPromptTokens = totalPromptTokens
        self.totalCompletionTokens = totalCompletionTokens
        self.requestsByCaller = requestsByCaller
    }
}

/// Writing-tools style presets for selected-text AI rewriting.
public enum AIRewriteStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case rewrite
    case concise
    case friendly
    case professional

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .rewrite: return "Rewrite"
        case .concise: return "Concise"
        case .friendly: return "Friendly"
        case .professional: return "Professional"
        }
    }

    public var iconName: String {
        switch self {
        case .rewrite: return "sparkles"
        case .concise: return "arrow.down.right.and.arrow.up.left"
        case .friendly: return "face.smiling"
        case .professional: return "briefcase"
        }
    }

    public var systemInstructions: String {
        switch self {
        case .rewrite:
            return "Rewrite the provided text to improve clarity, grammar, and flow while preserving the original meaning. Return only the rewritten text."
        case .concise:
            return "Make the provided text more concise and direct without losing key information. Return only the rewritten text."
        case .friendly:
            return "Rewrite the provided text in a warm, friendly, and approachable tone. Return only the rewritten text."
        case .professional:
            return "Rewrite the provided text in a clear, polished, professional tone. Return only the rewritten text."
        }
    }
}
