import CryptoKit
import Foundation
import SurfaceContracts

public struct ExtensionActivity: Codable, Equatable, Sendable {
    public let lifecycle: LifecycleSchema
    public let initialTree: SDUITree

    public init(lifecycle: LifecycleSchema, initialTree: SDUITree) {
        self.lifecycle = lifecycle
        self.initialTree = initialTree
    }
}

public struct SDKManifest: Codable, Equatable, Sendable {
    public let manifest: ExtensionManifest
    public let publisherID: String
    public let capabilities: [CapabilitySchema]
    public let activities: [ExtensionActivity]
    public let permissions: [ExtensionPermissionRequirement]

    public init(
        manifest: ExtensionManifest,
        publisherID: String,
        capabilities: [CapabilitySchema] = [],
        activities: [ExtensionActivity] = [],
        permissions: [ExtensionPermissionRequirement] = []
    ) {
        self.manifest = manifest
        self.publisherID = publisherID
        self.capabilities = capabilities
        self.activities = activities
        self.permissions = permissions
    }

    public var validationIssues: [SDKManifestValidationIssue] {
        var issues = manifest.validationIssues().map(SDKManifestValidationIssue.contract)
        if publisherID.isEmpty {
            issues.append(.emptyPublisherID)
        }
        var activityIDs = Set<String>()
        for activity in activities {
            if !activity.lifecycle.isValid {
                issues.append(.invalidActivity(activity.lifecycle.activityID))
            }
            if !activityIDs.insert(activity.lifecycle.activityID).inserted {
                issues.append(.duplicateActivity(activity.lifecycle.activityID))
            }
            issues.append(contentsOf: activity.initialTree.validate().issues.map {
                .invalidSDUI(activity.lifecycle.activityID, $0)
            })
        }
        var capabilityNames = Set<String>()
        for capability in capabilities {
            if !capability.isValid {
                issues.append(.invalidCapability(capability.name))
            }
            if !capabilityNames.insert(capability.name).inserted {
                issues.append(.duplicateCapability(capability.name))
            }
        }
        var permissionNames = Set<String>()
        for permission in permissions {
            if !permission.isValid {
                issues.append(.invalidPermission(permission.name))
            }
            if !permissionNames.insert(permission.name).inserted {
                issues.append(.duplicatePermission(permission.name))
            }
        }
        return issues
    }

    public var isValid: Bool { validationIssues.isEmpty }

    public func canonicalBytes() throws -> Data {
        guard isValid else { throw SDKManifestError.invalid(validationIssues) }
        let canonical = SDKManifest(
            manifest: manifest,
            publisherID: publisherID,
            capabilities: capabilities.sorted { $0.name < $1.name },
            activities: activities.sorted {
                $0.lifecycle.activityID < $1.lifecycle.activityID
            },
            permissions: permissions.sorted { $0.name < $1.name }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(canonical)
    }
}

public enum SDKManifestValidationIssue: Equatable, Sendable {
    case emptyPublisherID
    case contract(ManifestValidationIssue)
    case invalidActivity(String)
    case duplicateActivity(String)
    case invalidCapability(String)
    case duplicateCapability(String)
    case invalidPermission(String)
    case duplicatePermission(String)
    case invalidSDUI(String, SDUIValidationIssue)
}

public enum SDKManifestError: Error, Equatable, Sendable {
    case invalid([SDKManifestValidationIssue])
}

public enum ExtensionMessage {
    public static func handshake(
        instanceID: String,
        nonce: String,
        contracts: ContractSet = .v1
    ) throws -> IPCMessage {
        let schema = IPCHandshakeSchema(
            instanceID: instanceID,
            nonce: nonce,
            contracts: contracts
        )
        guard schema.isValid else { throw SDKMessageError.invalidHandshake }
        return IPCMessage(
            kind: .handshake,
            payload: try JSONEncoder().encode(schema),
            nonce: nonce
        )
    }

    public static func request(
        id: String,
        method: String,
        payload: Data? = nil,
        capability: String? = nil,
        deadline: UInt64? = nil
    ) throws -> IPCMessage {
        guard !id.isEmpty, !method.isEmpty else {
            throw SDKMessageError.invalidRequest
        }
        return IPCMessage(
            kind: .request,
            requestID: id,
            method: method,
            payload: payload,
            deadline: deadline,
            capability: capability
        )
    }

    public static func response(
        requestID: String,
        payload: Data? = nil,
        nonce: String? = nil
    ) throws -> IPCMessage {
        guard !requestID.isEmpty, nonce?.isEmpty == false else {
            throw SDKMessageError.invalidResponse
        }
        return IPCMessage(
            kind: .response,
            requestID: requestID,
            payload: payload,
            nonce: nonce
        )
    }

    public static func cancel(requestID: String) throws -> IPCMessage {
        guard !requestID.isEmpty else { throw SDKMessageError.invalidCancellation }
        return IPCMessage(kind: .cancel, requestID: requestID)
    }
}

public enum SDKMessageError: Error, Equatable, Sendable {
    case invalidHandshake
    case invalidRequest
    case invalidResponse
    case invalidCancellation
}

public enum ExtensionPackageBuilder {
    public static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func makePackage(
        artifactID: String,
        version: ContractVersion,
        publisherID: String,
        contracts: ContractSet = .v1,
        files: [String: Data],
        artifactBytes: Data,
        dependencies: [ArtifactDependency] = []
    ) throws -> ArtifactPackage {
        let hashes = files.keys.sorted().map { path in
            ArtifactFileHash(path: path, sha256: sha256(files[path]!))
        }
        let manifest = CanonicalArtifactManifest(
            artifactID: artifactID,
            version: version,
            publisherID: publisherID,
            contracts: contracts,
            files: hashes,
            dependencies: dependencies
        )
        guard manifest.isValid else {
            throw SDKPackageError.invalidManifest
        }
        return ArtifactPackage(
            manifest: manifest,
            files: files,
            artifactBytes: artifactBytes
        )
    }
}

public enum SDKPackageError: Error, Equatable, Sendable {
    case invalidManifest
}

public enum SpeedTestPhase: Codable, Equatable, Sendable {
    case ready
    case measuring(progress: Double)
    case completed
    case failed(message: String)
    case cancelled
}

public struct SpeedTestUpdate: Codable, Equatable, Sendable {
    public let phase: SpeedTestPhase
    public let tree: SDUITree

    public init(phase: SpeedTestPhase, tree: SDUITree) {
        self.phase = phase
        self.tree = tree
    }
}

public struct SpeedTestExtension: Sendable {
    public static let identifier = "com.archipelago.librespeed"
    public static let activityID = "network-speed-test"

    public let manifest: SDKManifest
    private(set) public var phase: SpeedTestPhase

    public init(
        dependency: ArtifactDependency,
        publisherID: String = "archipelago"
    ) {
        let manifest = ExtensionManifest(
            identifier: Self.identifier,
            displayName: "Network Speed Test",
            contracts: .v1,
            dependencies: [dependency]
        )
        let activity = ExtensionActivity(
            lifecycle: LifecycleSchema(
                activityID: Self.activityID,
                sourceID: Self.identifier,
                role: .primary,
                priority: 10,
                supportsPromotion: true
            ),
            initialTree: SDUITree.speedTest(
                title: "Network speed test",
                state: .measuring(progress: 0)
            )
        )
        self.manifest = SDKManifest(
            manifest: manifest,
            publisherID: publisherID,
            activities: [activity]
        )
        self.phase = .ready
    }

    public mutating func start() -> SpeedTestUpdate {
        phase = .measuring(progress: 0)
        return update()
    }

    public mutating func progress(_ value: Double) -> SpeedTestUpdate {
        guard case .measuring = phase else { return update() }
        phase = .measuring(progress: min(max(value, 0), 1))
        return update()
    }

    public mutating func complete() -> SpeedTestUpdate {
        phase = .completed
        return update()
    }

    public mutating func fail(message: String) -> SpeedTestUpdate {
        phase = .failed(message: message)
        return update()
    }

    public mutating func cancel() -> SpeedTestUpdate {
        phase = .cancelled
        return update()
    }

    public mutating func recover() -> SpeedTestUpdate {
        phase = .ready
        return update()
    }

    private func update() -> SpeedTestUpdate {
        SpeedTestUpdate(
            phase: phase,
            tree: SDUITree.speedTest(
                title: "Network speed test",
                state: phase.sduiState
            )
        )
    }
}

private extension SpeedTestPhase {
    var sduiState: SDUISpeedTestState {
        switch self {
        case .ready:
            return .ready
        case .measuring(let progress):
            return .measuring(progress: progress)
        case .completed:
            return .completed
        case .failed(let message):
            return .failed(message: message)
        case .cancelled:
            return .cancelled
        }
    }
}

public struct DependencyUpdateRequest: Codable, Equatable, Sendable {
    public let dependency: ArtifactDependency
    public let requestedAt: Date

    public init(dependency: ArtifactDependency, requestedAt: Date = Date()) {
        self.dependency = dependency
        self.requestedAt = requestedAt
    }
}

public enum DependencyUpdateState: Sendable {
    case current
    case checking(DependencyUpdateRequest)
    case staged(VerifiedArtifact)
    case activated(VerifiedArtifact)
    case rolledBack(VerifiedArtifact)
    case failed(String)
}

public struct DependencyUpdateCoordinator: Sendable {
    public private(set) var state: DependencyUpdateState = .current
    private var store: VerifiedArtifactStore
    private let verify: @Sendable (VerifiedArtifact) -> Result<Void, ArtifactVerificationFailure>

    public init(
        verify: @escaping @Sendable (VerifiedArtifact) -> Result<Void, ArtifactVerificationFailure>
    ) {
        self.verify = verify
        self.store = VerifiedArtifactStore(verify: verify)
    }

    public mutating func installInitial(
        _ artifact: VerifiedArtifact
    ) -> Result<Void, ArtifactUpdateFailure> {
        let result = store.installInitial(artifact)
        if case .failure(let error) = result {
            state = .failed(String(describing: error))
        }
        return result
    }

    public mutating func requestCheck(
        for dependency: ArtifactDependency,
        at date: Date = Date()
    ) -> DependencyUpdateRequest {
        let request = DependencyUpdateRequest(dependency: dependency, requestedAt: date)
        state = .checking(request)
        return request
    }

    public mutating func stage(_ artifact: VerifiedArtifact) -> Result<Void, ArtifactUpdateFailure> {
        let result = store.stage(artifact)
        switch result {
        case .success:
            state = .staged(artifact)
        case .failure(let error):
            state = .failed(String(describing: error))
        }
        return result
    }

    public mutating func activate() -> Result<Void, ArtifactUpdateFailure> {
        let result = store.activate()
        switch result {
        case .success:
            if let active = store.active {
                state = .activated(active)
            }
        case .failure(let error):
            state = .failed(String(describing: error))
        }
        return result
    }

    public mutating func rollback() -> Result<Void, ArtifactUpdateFailure> {
        let result = store.rollback()
        switch result {
        case .success:
            if let active = store.active {
                state = .rolledBack(active)
            }
        case .failure(let error):
            state = .failed(String(describing: error))
        }
        return result
    }
}
