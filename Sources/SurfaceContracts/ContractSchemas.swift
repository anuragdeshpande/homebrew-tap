import Foundation

public enum IPCMessageKind: String, Codable, Sendable {
    case handshake
    case heartbeat
    case heartbeatAck = "heartbeat-ack"
    case request
    case response
    case event
    case error
    case cancel
    case terminate
}

public struct IPCMessage: Codable, Equatable, Sendable {
    public let kind: IPCMessageKind
    public let requestID: String?
    public let method: String?
    public let payload: Data?
    public let nonce: String?
    public let deadline: UInt64?
    public let capability: String?
    public let error: String?

    public init(
        kind: IPCMessageKind,
        requestID: String? = nil,
        method: String? = nil,
        payload: Data? = nil,
        nonce: String? = nil,
        deadline: UInt64? = nil,
        capability: String? = nil,
        error: String? = nil
    ) {
        self.kind = kind
        self.requestID = requestID
        self.method = method
        self.payload = payload
        self.nonce = nonce
        self.deadline = deadline
        self.capability = capability
        self.error = error
    }

    public func encodedFrame() throws -> IPCFrame {
        IPCFrame(payload: Array(try JSONEncoder().encode(self)))
    }

    public static func decode(frame: IPCFrame) throws -> Self {
        try JSONDecoder().decode(Self.self, from: Data(frame.payload))
    }
}

public struct IPCFrameDecoder: Sendable {
    private var buffer: [UInt8] = []

    public init() {}

    public mutating func append(_ bytes: [UInt8]) -> Result<[IPCFrame], IPCFrameError> {
        buffer.append(contentsOf: bytes)
        var frames: [IPCFrame] = []
        while true {
            guard buffer.count >= 4 else { return .success(frames) }
            let length = (UInt32(buffer[0]) << 24)
                | (UInt32(buffer[1]) << 16)
                | (UInt32(buffer[2]) << 8)
                | UInt32(buffer[3])
            guard length > 0 else { return .failure(.emptyPayload) }
            guard length <= IPCFrame.maximumPayloadLength else {
                return .failure(.payloadTooLarge)
            }
            let total = 4 + Int(length)
            guard buffer.count >= total else { return .success(frames) }
            let bytes = Array(buffer.prefix(total))
            buffer.removeFirst(total)
            guard case .success(let frame) = IPCFrame.decode(bytes) else {
                return .failure(.lengthMismatch)
            }
            frames.append(frame)
        }
    }
}

public struct IPCHandshakeSchema: Codable, Equatable, Sendable {
    public let instanceID: String
    public let nonce: String
    public let contracts: ContractSet
    public let heartbeatIntervalMilliseconds: UInt32
    public let requestDeadlineMilliseconds: UInt32

    public init(
        instanceID: String,
        nonce: String,
        contracts: ContractSet,
        heartbeatIntervalMilliseconds: UInt32 = 5_000,
        requestDeadlineMilliseconds: UInt32 = 30_000
    ) {
        self.instanceID = instanceID
        self.nonce = nonce
        self.contracts = contracts
        self.heartbeatIntervalMilliseconds = heartbeatIntervalMilliseconds
        self.requestDeadlineMilliseconds = requestDeadlineMilliseconds
    }

    public var isValid: Bool {
        !instanceID.isEmpty && !nonce.isEmpty &&
            heartbeatIntervalMilliseconds > 0 &&
            requestDeadlineMilliseconds >= heartbeatIntervalMilliseconds
    }
}

public enum LifecycleRole: String, Codable, CaseIterable, Sendable {
    case primary
    case secondary
    case queued
    case inactive
}

public struct LifecycleSchema: Codable, Equatable, Sendable {
    public let activityID: String
    public let sourceID: String
    public let role: LifecycleRole
    public let priority: Int
    public let supportsPromotion: Bool
    public let secondaryLifetimeSeconds: UInt32?

    public init(
        activityID: String,
        sourceID: String,
        role: LifecycleRole,
        priority: Int = 0,
        supportsPromotion: Bool = false,
        secondaryLifetimeSeconds: UInt32? = nil
    ) {
        self.activityID = activityID
        self.sourceID = sourceID
        self.role = role
        self.priority = priority
        self.supportsPromotion = supportsPromotion
        self.secondaryLifetimeSeconds = secondaryLifetimeSeconds
    }

    public var isValid: Bool {
        !activityID.isEmpty && !sourceID.isEmpty &&
            (role != .secondary || secondaryLifetimeSeconds.map { $0 > 0 } ?? true)
    }
}

public enum CapabilityRuntimeState: String, Codable, CaseIterable, Sendable {
    case unavailable
    case declared
    case pendingConsent = "pending-consent"
    case granted
    case denied
    case revoked
}

public struct CapabilitySchema: Codable, Equatable, Sendable {
    public let name: String
    public let reason: String
    public let scope: String
    public let requestedLimit: UInt64
    public let requiresConsent: Bool
    public let state: CapabilityRuntimeState

    public init(
        name: String,
        reason: String,
        scope: String,
        requestedLimit: UInt64,
        requiresConsent: Bool,
        state: CapabilityRuntimeState = .declared
    ) {
        self.name = name
        self.reason = reason
        self.scope = scope
        self.requestedLimit = requestedLimit
        self.requiresConsent = requiresConsent
        self.state = state
    }

    public var isValid: Bool {
        !name.isEmpty && !reason.isEmpty && !scope.isEmpty
    }
}

public enum TrustTier: String, Codable, CaseIterable, Sendable {
    case approved
    case signedUnapproved = "signed-unapproved"
    case unsignedUntrusted = "unsigned-untrusted"
}

public struct TrustSchema: Codable, Equatable, Sendable {
    public let artifactID: String
    public let artifactSHA256: String
    public let publisherID: String
    public let operatorKeyID: String?
    public let trustAnchorID: String?
    public let tier: TrustTier
    public let revoked: Bool

    public init(
        artifactID: String,
        artifactSHA256: String,
        publisherID: String,
        operatorKeyID: String? = nil,
        trustAnchorID: String? = nil,
        tier: TrustTier,
        revoked: Bool = false
    ) {
        self.artifactID = artifactID
        self.artifactSHA256 = artifactSHA256
        self.publisherID = publisherID
        self.operatorKeyID = operatorKeyID
        self.trustAnchorID = trustAnchorID
        self.tier = tier
        self.revoked = revoked
    }

    public var isValid: Bool {
        !artifactID.isEmpty && isSHA256(artifactSHA256) && !publisherID.isEmpty &&
            (tier != .approved || operatorKeyID?.isEmpty == false)
    }

    private func isSHA256(_ value: String) -> Bool {
        value.count == 64 && value.allSatisfy { $0.isHexDigit }
    }
}

public enum CatalogChannel: String, Codable, CaseIterable, Sendable {
    case development
    case preview
    case stable
}

public struct CatalogEntrySchema: Codable, Equatable, Sendable {
    public let artifactID: String
    public let version: ContractVersion
    public let channel: CatalogChannel
    public let artifactSHA256: String
    public let trust: TrustSchema

    public init(
        artifactID: String,
        version: ContractVersion,
        channel: CatalogChannel,
        artifactSHA256: String,
        trust: TrustSchema
    ) {
        self.artifactID = artifactID
        self.version = version
        self.channel = channel
        self.artifactSHA256 = artifactSHA256
        self.trust = trust
    }

    public var isValid: Bool {
        !artifactID.isEmpty && artifactSHA256.count == 64 &&
            trust.artifactID == artifactID && trust.artifactSHA256 == artifactSHA256 &&
            trust.isValid && !trust.revoked &&
            (channel != .stable || trust.tier == .approved)
    }
}

public enum SharedFixtureExpectation: String, Codable, Sendable {
    case pass
    case reject
}

public enum SharedFixtureScenario: String, Codable, Sendable {
    case validNegotiation
    case incompatibleSchema
    case typedActivationFailures
    case versionBoundary
    case malformedManifest
    case staleSDUI
    case unsupportedRequiredPrimitive
    case validIPC
    case invalidIPC
}

public struct SharedConformanceFixture: Codable, Equatable, Sendable {
    public let identifier: String
    public let scenario: SharedFixtureScenario
    public let expectation: SharedFixtureExpectation
    public let payload: Data

    public init(
        identifier: String,
        scenario: SharedFixtureScenario,
        expectation: SharedFixtureExpectation,
        payload: Data
    ) {
        self.identifier = identifier
        self.scenario = scenario
        self.expectation = expectation
        self.payload = payload
    }
}
