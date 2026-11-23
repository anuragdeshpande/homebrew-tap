import Foundation

/// Pricing tier for a curated Store extension. `.pro` is reserved for Phase 2 monetization.
public enum StorePricingTier: String, Codable, Equatable, Sendable {
    case free
    case pro
}

/// Qualitative resource impact level declared in a curated extension's Usage Facts.
public enum StoreCuratedImpactLevel: String, Codable, Equatable, Sendable {
    case insignificant = "Insignificant"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

/// Icon-paired metadata item in a curated extension manifest.
public struct StoreCuratedIconFact: Codable, Equatable, Sendable {
    public let id: String
    public let iconName: String
    public let title: String
    public let detail: String

    public init(id: String, iconName: String, title: String, detail: String) {
        self.id = id
        self.iconName = iconName
        self.title = title
        self.detail = detail
    }
}

/// Qualitative Usage Facts declared in the remote curated index.
public struct StoreCuratedUsageFacts: Codable, Equatable, Sendable {
    public let cpu: StoreCuratedImpactLevel
    public let ram: StoreCuratedImpactLevel
    public let gpu: StoreCuratedImpactLevel
    public let externalDownloads: [StoreCuratedIconFact]

    public init(
        cpu: StoreCuratedImpactLevel,
        ram: StoreCuratedImpactLevel,
        gpu: StoreCuratedImpactLevel,
        externalDownloads: [StoreCuratedIconFact] = []
    ) {
        self.cpu = cpu
        self.ram = ram
        self.gpu = gpu
        self.externalDownloads = externalDownloads
    }
}

/// Host capability and attribution disclosures declared in the remote curated index.
public struct StoreCuratedPrivacyAndAttributions: Codable, Equatable, Sendable {
    public let hostCapabilities: [StoreCuratedIconFact]
    public let attributions: [StoreCuratedIconFact]

    public init(
        hostCapabilities: [StoreCuratedIconFact] = [],
        attributions: [StoreCuratedIconFact] = []
    ) {
        self.hostCapabilities = hostCapabilities
        self.attributions = attributions
    }
}

/// Changelog entry in a curated extension's version history.
public struct StoreCuratedVersionEntry: Codable, Equatable, Sendable {
    public let version: String
    public let dateLabel: String
    public let changes: [String]

    public init(version: String, dateLabel: String, changes: [String]) {
        self.version = version
        self.dateLabel = dateLabel
        self.changes = changes
    }
}

/// Declarative PreviewKit scene or developer-bundled media item for Storefront listings.
public struct StoreCuratedPreviewScene: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let leadingIcon: String
    public let leadingText: String
    public let trailingText: String
    public let trailingIcon: String
    public let hoverDetailValue: String
    public let sliderProgress: Double?
    public let customMediaURL: String?
    public let isVideo: Bool

    public init(
        id: String,
        title: String,
        subtitle: String,
        leadingIcon: String = "sparkles",
        leadingText: String = "",
        trailingText: String = "",
        trailingIcon: String = "",
        hoverDetailValue: String = "",
        sliderProgress: Double? = nil,
        customMediaURL: String? = nil,
        isVideo: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.leadingText = leadingText
        self.trailingText = trailingText
        self.trailingIcon = trailingIcon
        self.hoverDetailValue = hoverDetailValue
        self.sliderProgress = sliderProgress
        self.customMediaURL = customMediaURL
        self.isVideo = isVideo
    }
}

/// Per-platform downloadable artifact descriptor (e.g. `macos-universal`, `windows-x64`, `windows-arm64`).
public struct StorePlatformArtifact: Codable, Equatable, Sendable {
    public let url: String
    public let sizeBytes: UInt64
    public let sha256: String

    public init(url: String, sizeBytes: UInt64, sha256: String) {
        self.url = url
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
    }
}

/// Full curated Storefront listing paired with its signed `CatalogEntrySchema` trust record.
public struct StoreCuratedExtensionEntry: Codable, Equatable, Sendable {
    #if os(macOS)
    public static let currentPlatformKey = "macos-universal"
    #elseif os(Windows)
    public static let currentPlatformKey = "windows-x64"
    #else
    public static let currentPlatformKey = "linux-x64"
    #endif

    public let id: String
    public let name: String
    public let subtitle: String
    public let description: String
    public let developer: String
    public let category: String
    public let licenseSPDX: String
    public let pricingTier: StorePricingTier
    public let platforms: [String]
    public let supportedSurfaces: [String]
    public let sizeBytes: UInt64
    public let artifactURL: String
    public let platformArtifacts: [String: StorePlatformArtifact]
    public let dependencies: [ArtifactDependency]
    public let catalogEntry: CatalogEntrySchema
    public let usageFacts: StoreCuratedUsageFacts
    public let privacyAndAttributions: StoreCuratedPrivacyAndAttributions
    public let versionHistory: [StoreCuratedVersionEntry]
    public let previewScenes: [StoreCuratedPreviewScene]

    public init(
        id: String,
        name: String,
        subtitle: String,
        description: String,
        developer: String,
        category: String,
        licenseSPDX: String,
        pricingTier: StorePricingTier = .free,
        platforms: [String] = ["macOS 26+ (Win/Linux planned)"],
        supportedSurfaces: [String] = ["Notch", "Island", "Pill"],
        sizeBytes: UInt64,
        artifactURL: String,
        platformArtifacts: [String: StorePlatformArtifact] = [:],
        dependencies: [ArtifactDependency] = [],
        catalogEntry: CatalogEntrySchema,
        usageFacts: StoreCuratedUsageFacts,
        privacyAndAttributions: StoreCuratedPrivacyAndAttributions,
        versionHistory: [StoreCuratedVersionEntry] = [],
        previewScenes: [StoreCuratedPreviewScene] = []
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.description = description
        self.developer = developer
        self.category = category
        self.licenseSPDX = licenseSPDX
        self.pricingTier = pricingTier
        self.platforms = platforms
        self.supportedSurfaces = supportedSurfaces
        self.sizeBytes = sizeBytes
        self.artifactURL = artifactURL
        self.platformArtifacts = platformArtifacts
        self.dependencies = dependencies
        self.catalogEntry = catalogEntry
        self.usageFacts = usageFacts
        self.privacyAndAttributions = privacyAndAttributions
        self.versionHistory = versionHistory
        self.previewScenes = previewScenes
    }

    public var isValid: Bool {
        !id.isEmpty && !name.isEmpty && !licenseSPDX.isEmpty && !artifactURL.isEmpty && catalogEntry.isValid
    }

    /// Resolves the artifact descriptor for `platformKey`, falling back to legacy single-platform fields.
    public func resolvedArtifact(for platformKey: String = StoreCuratedExtensionEntry.currentPlatformKey) -> StorePlatformArtifact {
        if let specific = platformArtifacts[platformKey] {
            return specific
        }
        return StorePlatformArtifact(
            url: artifactURL,
            sizeBytes: sizeBytes,
            sha256: catalogEntry.artifactSHA256
        )
    }

    /// Indicates whether this listing declares a compatible artifact for `platformKey` (or uses legacy single-platform fields).
    public func supportsPlatform(_ platformKey: String = StoreCuratedExtensionEntry.currentPlatformKey) -> Bool {
        if platformArtifacts.isEmpty {
            return true
        }
        return platformArtifacts[platformKey] != nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        description = try container.decode(String.self, forKey: .description)
        developer = try container.decode(String.self, forKey: .developer)
        category = try container.decode(String.self, forKey: .category)
        licenseSPDX = try container.decode(String.self, forKey: .licenseSPDX)
        pricingTier = try container.decodeIfPresent(StorePricingTier.self, forKey: .pricingTier) ?? .free
        platforms = try container.decodeIfPresent([String].self, forKey: .platforms) ?? ["macOS 26+ (Win/Linux planned)"]
        supportedSurfaces = try container.decodeIfPresent([String].self, forKey: .supportedSurfaces) ?? ["Notch", "Island", "Pill"]
        sizeBytes = try container.decode(UInt64.self, forKey: .sizeBytes)
        artifactURL = try container.decode(String.self, forKey: .artifactURL)
        platformArtifacts = try container.decodeIfPresent([String: StorePlatformArtifact].self, forKey: .platformArtifacts) ?? [:]
        dependencies = try container.decodeIfPresent([ArtifactDependency].self, forKey: .dependencies) ?? []
        catalogEntry = try container.decode(CatalogEntrySchema.self, forKey: .catalogEntry)
        usageFacts = try container.decode(StoreCuratedUsageFacts.self, forKey: .usageFacts)
        privacyAndAttributions = try container.decode(StoreCuratedPrivacyAndAttributions.self, forKey: .privacyAndAttributions)
        versionHistory = try container.decodeIfPresent([StoreCuratedVersionEntry].self, forKey: .versionHistory) ?? []
        previewScenes = try container.decodeIfPresent([StoreCuratedPreviewScene].self, forKey: .previewScenes) ?? []
    }
}

/// Versioned, signed remote curated index document consumed by `StoreCatalogService`.
public struct StoreCuratedIndexDocument: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let revision: UInt64
    public let channel: CatalogChannel
    public let signerKeyID: String
    public let anchorID: String
    public let entries: [StoreCuratedExtensionEntry]
    public let revocations: RevocationBundle?
    public let signature: Data

    public init(
        schemaVersion: Int = StoreCuratedIndexDocument.currentSchemaVersion,
        revision: UInt64,
        channel: CatalogChannel = .stable,
        signerKeyID: String,
        anchorID: String,
        entries: [StoreCuratedExtensionEntry],
        revocations: RevocationBundle? = nil,
        signature: Data
    ) {
        self.schemaVersion = schemaVersion
        self.revision = revision
        self.channel = channel
        self.signerKeyID = signerKeyID
        self.anchorID = anchorID
        self.entries = entries
        self.revocations = revocations
        self.signature = signature
    }

    public func canonicalBytes() throws -> Data {
        try ArtifactTrustCanonical.encode(
            StoreCuratedIndexDocument(
                schemaVersion: schemaVersion,
                revision: revision,
                channel: channel,
                signerKeyID: signerKeyID,
                anchorID: anchorID,
                entries: entries.sorted { $0.id < $1.id },
                revocations: revocations,
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

/// Persistent record of an extension installed via the Storefront pipeline.
public struct StoreInstalledExtensionRecord: Codable, Equatable, Sendable {
    public let id: String
    public let version: String
    public let artifactSHA256: String
    public let installPath: String
    public let installedAt: Date
    public let verifiedDependencies: [ArtifactDependency]

    public init(
        id: String,
        version: String,
        artifactSHA256: String,
        installPath: String,
        installedAt: Date = Date(),
        verifiedDependencies: [ArtifactDependency] = []
    ) {
        self.id = id
        self.version = version
        self.artifactSHA256 = artifactSHA256
        self.installPath = installPath
        self.installedAt = installedAt
        self.verifiedDependencies = verifiedDependencies
    }
}

/// Errors surfaced by `StoreCatalogService` during index refresh, verification, or install.
public enum StoreCatalogError: Error, Equatable, Sendable, LocalizedError {
    case unsupportedSchemaVersion(Int)
    case invalidIndexSignature
    case staleIndexRevision(current: UInt64, candidate: UInt64)
    case invalidExtensionEntry(String)
    case extensionNotFound(String)
    case proEntitlementRequired(String)
    case artifactRevoked(String)
    case artifactHashMismatch(expected: String, actual: String)
    case downloadFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Unsupported curated index schema version \(version)."
        case .invalidIndexSignature:
            return "Curated index signature verification failed."
        case .staleIndexRevision(let current, let candidate):
            return "Stale curated index revision \(candidate) (current is \(current))."
        case .invalidExtensionEntry(let id):
            return "Invalid curated extension entry '\(id)'."
        case .extensionNotFound(let id):
            return "Extension '\(id)' was not found in the curated index."
        case .proEntitlementRequired(let id):
            return "Extension '\(id)' requires a Pro entitlement (not enabled in Phase 1)."
        case .artifactRevoked(let id):
            return "Extension '\(id)' is revoked and blocked from installation."
        case .artifactHashMismatch(let expected, let actual):
            return "Artifact SHA-256 mismatch (expected \(expected), got \(actual))."
        case .downloadFailed(let message):
            return "Artifact download failed: \(message)"
        }
    }
}
