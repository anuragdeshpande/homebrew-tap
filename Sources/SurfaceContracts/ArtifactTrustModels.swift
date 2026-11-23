import Foundation

public struct ArtifactFileHash: Codable, Equatable, Sendable {
    public let path: String
    public let sha256: String

    public init(path: String, sha256: String) {
        self.path = path
        self.sha256 = sha256.lowercased()
    }

    public var isValid: Bool {
        !path.isEmpty && !path.hasPrefix("/") &&
            !path.split(separator: "/").contains("..") &&
            sha256.isSHA256
    }
}

public struct CanonicalArtifactManifest: Codable, Equatable, Sendable {
    public let artifactID: String
    public let version: ContractVersion
    public let publisherID: String
    public let contracts: ContractSet
    public let files: [ArtifactFileHash]
    public let dependencies: [ArtifactDependency]

    public init(
        artifactID: String,
        version: ContractVersion,
        publisherID: String,
        contracts: ContractSet,
        files: [ArtifactFileHash],
        dependencies: [ArtifactDependency] = []
    ) {
        self.artifactID = artifactID
        self.version = version
        self.publisherID = publisherID
        self.contracts = contracts
        self.files = files
        self.dependencies = dependencies
    }

    public var isValid: Bool {
        !artifactID.isEmpty && !publisherID.isEmpty &&
            files.allSatisfy(\.isValid) &&
            Set(files.map(\.path)).count == files.count &&
            dependencies.allSatisfy { $0.identifier.isEmpty == false && $0.sha256.isSHA256 }
    }

    public func canonicalBytes() throws -> Data {
        guard isValid else { throw ArtifactVerificationFailure.invalidManifest }
        let canonical = CanonicalArtifactManifest(
            artifactID: artifactID,
            version: version,
            publisherID: publisherID,
            contracts: contracts,
            files: files.sorted { $0.path < $1.path },
            dependencies: dependencies.sorted { $0.identifier < $1.identifier }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(canonical)
    }
}

public struct ArtifactPackage: Sendable {
    public let manifest: CanonicalArtifactManifest
    public let files: [String: Data]
    public let artifactBytes: Data

    public init(
        manifest: CanonicalArtifactManifest,
        files: [String: Data],
        artifactBytes: Data
    ) {
        self.manifest = manifest
        self.files = files
        self.artifactBytes = artifactBytes
    }
}

public struct OperatorTrustAnchor: Codable, Equatable, Sendable {
    public let identifier: String
    public let fingerprint: String
    public let enabled: Bool

    public init(identifier: String, fingerprint: String, enabled: Bool = true) {
        self.identifier = identifier
        self.fingerprint = fingerprint.lowercased()
        self.enabled = enabled
    }

    public var isValid: Bool {
        !identifier.isEmpty && !fingerprint.isEmpty
    }
}

public enum OperatorApproval: String, Codable, Sendable {
    case approved
    case rejected
    case unavailable
}

public enum PublisherIntegrity: String, Codable, Sendable {
    case verified
    case unverified
    case invalid
}

public enum UserConsent: String, Codable, Sendable {
    case notRequired = "not-required"
    case accepted
    case declined
}

public struct OperatorAttestation: Codable, Equatable, Sendable {
    public let artifactSHA256: String
    public let publisherID: String
    public let operatorID: String
    public let policyVersion: String
    public let contracts: ContractVersionRange
    public let issuedAt: Date
    public let expiresAt: Date
    public let anchorID: String
    public let keyID: String
    public let approval: OperatorApproval
    public let signature: Data

    public init(
        artifactSHA256: String,
        publisherID: String,
        operatorID: String,
        policyVersion: String,
        contracts: ContractVersionRange,
        issuedAt: Date,
        expiresAt: Date,
        anchorID: String,
        keyID: String,
        approval: OperatorApproval = .approved,
        signature: Data
    ) {
        self.artifactSHA256 = artifactSHA256.lowercased()
        self.publisherID = publisherID
        self.operatorID = operatorID
        self.policyVersion = policyVersion
        self.contracts = contracts
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.anchorID = anchorID
        self.keyID = keyID
        self.approval = approval
        self.signature = signature
    }

    public func isValid(at date: Date) -> Bool {
        artifactSHA256.isSHA256 && !publisherID.isEmpty && !operatorID.isEmpty &&
            !policyVersion.isEmpty && !anchorID.isEmpty && !keyID.isEmpty &&
            contracts.isValid && issuedAt <= date && date < expiresAt &&
            approval == .approved && !signature.isEmpty
    }
}

public struct TrustStatus: Codable, Equatable, Sendable {
    public let artifactID: String
    public let artifactSHA256: String
    public let publisherID: String
    public let operatorID: String?
    public let trustAnchorID: String?
    public let operatorKeyID: String?
    public let publisherIntegrity: PublisherIntegrity
    public let operatorApproval: OperatorApproval
    public let userConsent: UserConsent
    public let trustTier: TrustTier
    public let validFrom: Date?
    public let validUntil: Date?
    public let revocationReference: String?
    public let revoked: Bool
    public let verificationMessage: String?

    public init(
        artifactID: String,
        artifactSHA256: String,
        publisherID: String,
        operatorID: String? = nil,
        trustAnchorID: String? = nil,
        operatorKeyID: String? = nil,
        publisherIntegrity: PublisherIntegrity,
        operatorApproval: OperatorApproval,
        userConsent: UserConsent,
        trustTier: TrustTier = .approved,
        validFrom: Date? = nil,
        validUntil: Date? = nil,
        revocationReference: String? = nil,
        revoked: Bool = false,
        verificationMessage: String? = nil
    ) {
        self.artifactID = artifactID
        self.artifactSHA256 = artifactSHA256.lowercased()
        self.publisherID = publisherID
        self.operatorID = operatorID
        self.trustAnchorID = trustAnchorID
        self.operatorKeyID = operatorKeyID
        self.publisherIntegrity = publisherIntegrity
        self.operatorApproval = operatorApproval
        self.userConsent = userConsent
        self.trustTier = trustTier
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.revocationReference = revocationReference
        self.revoked = revoked
        self.verificationMessage = verificationMessage
    }

    public var isApproved: Bool {
        publisherIntegrity == .verified && operatorApproval == .approved &&
            trustTier == .approved && userConsent != .declined && !revoked
    }
}

public enum ArtifactVerificationFailure: Error, Equatable, Sendable {
    case invalidManifest
    case missingFile(String)
    case unexpectedFile(String)
    case fileHashMismatch(String)
    case artifactHashMismatch
    case publisherIntegrityFailed
    case missingTrustAnchor(String)
    case invalidAttestation
    case attestationSignatureInvalid
    case revoked(String)
}

public struct OperatorKeyRotationStatement: Codable, Equatable, Sendable {
    public let oldKeyID: String
    public let newKeyID: String
    public let activationDate: Date
    public let retirementDate: Date?
    public let oldKeySignature: Data
    public let newKeySignature: Data

    public init(
        oldKeyID: String,
        newKeyID: String,
        activationDate: Date,
        retirementDate: Date? = nil,
        oldKeySignature: Data,
        newKeySignature: Data
    ) {
        self.oldKeyID = oldKeyID
        self.newKeyID = newKeyID
        self.activationDate = activationDate
        self.retirementDate = retirementDate
        self.oldKeySignature = oldKeySignature
        self.newKeySignature = newKeySignature
    }

    public var isValid: Bool {
        !oldKeyID.isEmpty && !newKeyID.isEmpty && oldKeyID != newKeyID &&
            retirementDate.map { activationDate < $0 } ?? true &&
            !oldKeySignature.isEmpty && !newKeySignature.isEmpty
    }

    public func canonicalBytes() throws -> Data {
        guard isValid else { throw ArtifactVerificationFailure.invalidAttestation }
        return try ArtifactTrustCanonical.encode(
            OperatorKeyRotationStatement(
                oldKeyID: oldKeyID,
                newKeyID: newKeyID,
                activationDate: activationDate,
                retirementDate: retirementDate,
                oldKeySignature: Data(),
                newKeySignature: Data()
            )
        )
    }

    public func accepts(keyID: String, at date: Date) -> Bool {
        guard isValid else { return false }
        if date < activationDate { return keyID == oldKeyID }
        if let retirementDate, date >= retirementDate {
            return keyID == newKeyID
        }
        return keyID == oldKeyID || keyID == newKeyID
    }
}

public struct VerifiedArtifact: Sendable {
    public let package: ArtifactPackage
    public let trust: TrustStatus

    public init(package: ArtifactPackage, trust: TrustStatus) {
        self.package = package
        self.trust = trust
    }
}

public enum CatalogUpdateFailure: Error, Equatable, Sendable {
    case invalidSignature
    case staleRevision
    case invalidEntry(String)
    case revokedEntry(String)
}

public enum ArtifactUpdateFailure: Error, Equatable, Sendable {
    case verification(ArtifactVerificationFailure)
    case noStagedArtifact
    case noRollbackArtifact
}

public extension String {
    var isSHA256: Bool {
        count == 64 && allSatisfy(\.isHexDigit)
    }
}
