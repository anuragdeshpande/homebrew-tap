import Foundation

public struct RevocationBundle: Codable, Equatable, Sendable {
    public let revision: UInt64
    public let signerKeyID: String
    public let anchorID: String
    public let revokedArtifactIDs: Set<String>
    public let revokedDigests: Set<String>
    public let revokedPublisherIDs: Set<String>
    public let revokedOperatorKeyIDs: Set<String>
    public let revokedAnchorIDs: Set<String>
    public let signature: Data

    public init(
        revision: UInt64,
        signerKeyID: String,
        anchorID: String,
        revokedArtifactIDs: Set<String> = [],
        revokedDigests: Set<String> = [],
        revokedPublisherIDs: Set<String> = [],
        revokedOperatorKeyIDs: Set<String> = [],
        revokedAnchorIDs: Set<String> = [],
        signature: Data
    ) {
        self.revision = revision
        self.signerKeyID = signerKeyID
        self.anchorID = anchorID
        self.revokedArtifactIDs = revokedArtifactIDs
        self.revokedDigests = revokedDigests
        self.revokedPublisherIDs = revokedPublisherIDs
        self.revokedOperatorKeyIDs = revokedOperatorKeyIDs
        self.revokedAnchorIDs = revokedAnchorIDs
        self.signature = signature
    }

    public var allRevocations: Set<String> {
        revokedArtifactIDs
            .union(revokedDigests)
            .union(revokedPublisherIDs)
            .union(revokedOperatorKeyIDs)
            .union(revokedAnchorIDs)
    }

    public func canonicalBytes() throws -> Data {
        try ArtifactTrustCanonical.encode(
            RevocationBundle(
                revision: revision,
                signerKeyID: signerKeyID,
                anchorID: anchorID,
                revokedArtifactIDs: revokedArtifactIDs,
                revokedDigests: revokedDigests,
                revokedPublisherIDs: revokedPublisherIDs,
                revokedOperatorKeyIDs: revokedOperatorKeyIDs,
                revokedAnchorIDs: revokedAnchorIDs,
                signature: Data()
            )
        )
    }

    public func verifySignature(
        using trustAnchors: [OperatorTrustAnchor],
        verifyCMS: ArtifactVerifier.CMSVerifier
    ) -> Bool {
        guard let anchor = trustAnchors.first(where: {
            $0.identifier == anchorID && $0.enabled && $0.isValid
        }), let payload = try? canonicalBytes() else {
            return false
        }
        return verifyCMS(signature, payload, anchor, signerKeyID)
    }
}

public struct SignedCatalog: Codable, Equatable, Sendable {
    public let revision: UInt64
    public let channel: CatalogChannel
    public let signerKeyID: String
    public let anchorID: String
    public let entries: [CatalogEntrySchema]
    public let signature: Data

    public init(
        revision: UInt64,
        channel: CatalogChannel,
        signerKeyID: String,
        anchorID: String,
        entries: [CatalogEntrySchema],
        signature: Data
    ) {
        self.revision = revision
        self.channel = channel
        self.signerKeyID = signerKeyID
        self.anchorID = anchorID
        self.entries = entries
        self.signature = signature
    }

    public func canonicalBytes() throws -> Data {
        try ArtifactTrustCanonical.encode(
            SignedCatalog(
                revision: revision,
                channel: channel,
                signerKeyID: signerKeyID,
                anchorID: anchorID,
                entries: entries.sorted {
                    ($0.artifactID, $0.version, $0.channel.rawValue) <
                        ($1.artifactID, $1.version, $1.channel.rawValue)
                },
                signature: Data()
            )
        )
    }

    public func verifySignature(
        using trustAnchors: [OperatorTrustAnchor],
        verifyCMS: ArtifactVerifier.CMSVerifier
    ) -> Bool {
        guard let anchor = trustAnchors.first(where: {
            $0.identifier == anchorID && $0.enabled && $0.isValid
        }), let payload = try? canonicalBytes() else {
            return false
        }
        return verifyCMS(signature, payload, anchor, signerKeyID)
    }
}

public struct VerifiedCatalogStore: Sendable {
    public typealias SignatureVerifier = @Sendable (Data, Data) -> Bool

    public private(set) var catalog: SignedCatalog?
    public private(set) var revocations: RevocationBundle?

    public init(
        catalog: SignedCatalog? = nil,
        revocations: RevocationBundle? = nil
    ) {
        self.catalog = catalog
        self.revocations = revocations
    }

    public mutating func replaceCatalog(
        _ candidate: SignedCatalog,
        verify: SignatureVerifier
    ) -> Result<Void, CatalogUpdateFailure> {
        guard !candidate.signerKeyID.isEmpty && !candidate.anchorID.isEmpty else {
            return .failure(.invalidSignature)
        }
        guard let payload = try? candidate.canonicalBytes(),
              verify(payload, candidate.signature) else {
            return .failure(.invalidSignature)
        }
        guard candidate.revision > (catalog?.revision ?? 0) else {
            return .failure(.staleRevision)
        }
        let revoked = revocations?.allRevocations ?? []
        for entry in candidate.entries {
            guard entry.isValid else { return .failure(.invalidEntry(entry.artifactID)) }
            guard !revoked.contains(entry.artifactID) &&
                !revoked.contains(entry.artifactSHA256) &&
                !revoked.contains(entry.trust.publisherID) &&
                !(entry.trust.operatorKeyID.map(revoked.contains) ?? false) &&
                !(entry.trust.trustAnchorID.map(revoked.contains) ?? false) else {
                return .failure(.revokedEntry(entry.artifactID))
            }
        }
        catalog = candidate
        return .success(())
    }

    public mutating func replaceCatalog(
        _ candidate: SignedCatalog,
        trustAnchors: [OperatorTrustAnchor],
        verifyCMS: ArtifactVerifier.CMSVerifier
    ) -> Result<Void, CatalogUpdateFailure> {
        guard candidate.verifySignature(using: trustAnchors, verifyCMS: verifyCMS) else {
            return .failure(.invalidSignature)
        }
        return replaceCatalog(candidate, verify: { _, _ in true })
    }

    public mutating func replaceRevocations(
        _ candidate: RevocationBundle,
        verify: SignatureVerifier
    ) -> Result<Void, CatalogUpdateFailure> {
        guard !candidate.signerKeyID.isEmpty && !candidate.anchorID.isEmpty else {
            return .failure(.invalidSignature)
        }
        guard let payload = try? candidate.canonicalBytes(),
              verify(payload, candidate.signature) else {
            return .failure(.invalidSignature)
        }
        guard candidate.revision > (revocations?.revision ?? 0) else {
            return .failure(.staleRevision)
        }
        revocations = candidate
        return .success(())
    }

    public mutating func replaceRevocations(
        _ candidate: RevocationBundle,
        trustAnchors: [OperatorTrustAnchor],
        verifyCMS: ArtifactVerifier.CMSVerifier
    ) -> Result<Void, CatalogUpdateFailure> {
        guard candidate.verifySignature(using: trustAnchors, verifyCMS: verifyCMS) else {
            return .failure(.invalidSignature)
        }
        return replaceRevocations(candidate, verify: { _, _ in true })
    }

    public func isRevoked(_ value: String) -> Bool {
        revocations?.allRevocations.contains(value) == true
    }

    public var availableEntries: [CatalogEntrySchema] {
        catalog?.entries.filter {
            !isRevoked($0.artifactID) &&
                !isRevoked($0.artifactSHA256) &&
                !isRevoked($0.trust.publisherID) &&
                !($0.trust.operatorKeyID.map(isRevoked) ?? false) &&
                !($0.trust.trustAnchorID.map(isRevoked) ?? false)
        } ?? []
    }
}

public struct VerifiedArtifactStore: Sendable {
    public typealias Verifier = @Sendable (VerifiedArtifact) -> Result<Void, ArtifactVerificationFailure>

    public private(set) var active: VerifiedArtifact?
    public private(set) var staged: VerifiedArtifact?
    public private(set) var lastVerified: VerifiedArtifact?
    private let verify: Verifier

    public init(verify: @escaping Verifier) {
        self.verify = verify
    }

    public mutating func installInitial(
        _ candidate: VerifiedArtifact
    ) -> Result<Void, ArtifactUpdateFailure> {
        switch verify(candidate) {
        case .success:
            active = candidate
            return .success(())
        case .failure(let failure):
            return .failure(.verification(failure))
        }
    }

    public mutating func stage(
        _ candidate: VerifiedArtifact
    ) -> Result<Void, ArtifactUpdateFailure> {
        switch verify(candidate) {
        case .success:
            staged = candidate
            return .success(())
        case .failure(let failure):
            return .failure(.verification(failure))
        }
    }

    public mutating func activate() -> Result<Void, ArtifactUpdateFailure> {
        guard let staged else { return .failure(.noStagedArtifact) }
        switch verify(staged) {
        case .success:
            break
        case .failure(let failure):
            return .failure(.verification(failure))
        }
        lastVerified = active
        active = staged
        self.staged = nil
        return .success(())
    }

    public mutating func rollback() -> Result<Void, ArtifactUpdateFailure> {
        guard let rollback = lastVerified else {
            return .failure(.noRollbackArtifact)
        }
        switch verify(rollback) {
        case .success:
            break
        case .failure(let failure):
            return .failure(.verification(failure))
        }
        staged = active
        active = rollback
        lastVerified = staged
        staged = nil
        return .success(())
    }

    public mutating func applyRevocations(_ bundle: RevocationBundle) {
        let revoked = bundle.allRevocations
        if let staged, isRevoked(staged, by: revoked) {
            self.staged = nil
        }
        if let lastVerified, isRevoked(lastVerified, by: revoked) {
            self.lastVerified = nil
        }
        if let active, isRevoked(active, by: revoked) {
            self.active = lastVerified
            self.lastVerified = nil
        }
    }

    private func isRevoked(_ artifact: VerifiedArtifact, by values: Set<String>) -> Bool {
        values.contains(artifact.trust.artifactID) ||
            values.contains(artifact.trust.artifactSHA256) ||
            values.contains(artifact.trust.publisherID) ||
            artifact.trust.operatorKeyID.map(values.contains) == true ||
            artifact.trust.trustAnchorID.map(values.contains) == true
    }
}
