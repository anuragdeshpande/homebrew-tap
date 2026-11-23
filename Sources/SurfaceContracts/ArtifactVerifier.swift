import CryptoKit
import Foundation

public struct ArtifactVerifier: Sendable {
    public typealias PublisherVerifier = @Sendable (CanonicalArtifactManifest, Data) -> Bool
    public typealias CMSVerifier = @Sendable (Data, Data, OperatorTrustAnchor, String) -> Bool

    private let verifyPublisher: PublisherVerifier
    private let verifyCMS: CMSVerifier

    public init(
        verifyPublisher: @escaping PublisherVerifier,
        verifyCMS: @escaping CMSVerifier
    ) {
        self.verifyPublisher = verifyPublisher
        self.verifyCMS = verifyCMS
    }

    public func verify(
        package: ArtifactPackage,
        attestation: OperatorAttestation,
        trustAnchors: [OperatorTrustAnchor],
        revoked: Set<String> = [],
        rotations: [OperatorKeyRotationStatement] = [],
        userConsent: UserConsent = .notRequired,
        at date: Date = Date()
    ) -> Result<TrustStatus, ArtifactVerificationFailure> {
        let manifest = package.manifest
        guard manifest.isValid else { return .failure(.invalidManifest) }
        guard !revoked.contains(manifest.artifactID),
              !revoked.contains(attestation.artifactSHA256),
              !revoked.contains(attestation.publisherID),
              !revoked.contains(attestation.keyID),
              !revoked.contains(attestation.anchorID) else {
            return .failure(.revoked(manifest.artifactID))
        }
        guard let canonicalManifest = try? manifest.canonicalBytes() else {
            return .failure(.invalidManifest)
        }
        let expectedFiles = Dictionary(uniqueKeysWithValues: manifest.files.map { ($0.path, $0.sha256) })
        guard Set(package.files.keys) == Set(expectedFiles.keys) else {
            let missing = expectedFiles.keys.first { package.files[$0] == nil }
            return .failure(.missingFile(missing ?? package.files.keys.first ?? ""))
        }
        for (path, data) in package.files {
            guard let expected = expectedFiles[path] else {
                return .failure(.unexpectedFile(path))
            }
            guard Self.sha256(data) == expected else {
                return .failure(.fileHashMismatch(path))
            }
        }
        guard Self.sha256(package.artifactBytes) == attestation.artifactSHA256 else {
            return .failure(.artifactHashMismatch)
        }
        guard verifyPublisher(manifest, package.artifactBytes) else {
            return .failure(.publisherIntegrityFailed)
        }
        guard attestation.isValid(at: date),
              attestation.artifactSHA256 == Self.sha256(package.artifactBytes),
              attestation.publisherID == manifest.publisherID else {
            return .failure(.invalidAttestation)
        }
        guard let anchor = trustAnchors.first(where: {
            $0.identifier == attestation.anchorID && $0.enabled && $0.isValid
        }) else {
            return .failure(.missingTrustAnchor(attestation.anchorID))
        }
        guard verifyCMS(attestation.signature, canonicalManifest, anchor, attestation.keyID) else {
            return .failure(.attestationSignatureInvalid)
        }
        let applicableRotations = rotations.filter {
            $0.oldKeyID == attestation.keyID || $0.newKeyID == attestation.keyID
        }
        if !applicableRotations.isEmpty {
            guard applicableRotations.contains(where: { rotation in
                guard rotation.accepts(keyID: attestation.keyID, at: date),
                      let payload = try? rotation.canonicalBytes() else {
                    return false
                }
                return verifyCMS(rotation.oldKeySignature, payload, anchor, rotation.oldKeyID) &&
                    verifyCMS(rotation.newKeySignature, payload, anchor, rotation.newKeyID)
            }) else {
                return .failure(.invalidAttestation)
            }
        }
        return .success(TrustStatus(
            artifactID: manifest.artifactID,
            artifactSHA256: attestation.artifactSHA256,
            publisherID: manifest.publisherID,
            operatorID: attestation.operatorID,
            trustAnchorID: attestation.anchorID,
            operatorKeyID: attestation.keyID,
            publisherIntegrity: .verified,
            operatorApproval: attestation.approval,
            userConsent: userConsent,
            trustTier: .approved,
            validFrom: attestation.issuedAt,
            validUntil: attestation.expiresAt
        ))
    }

    public static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

public enum ArtifactTrustCanonical {
    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }
}
