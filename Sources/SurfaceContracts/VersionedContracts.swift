import Foundation

public enum ContractFamily: String, CaseIterable, Codable, Sendable {
    case manifest
    case ipc
    case sdui
    case lifecycle
    case capability
    case trust
    case catalog
    case dependency
    case conformance
}

public struct ContractVersion: Hashable, Comparable, Codable, Sendable {
    public let major: UInt16
    public let minor: UInt16

    public init(major: UInt16, minor: UInt16) {
        self.major = major
        self.minor = minor
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.major, lhs.minor) < (rhs.major, rhs.minor)
    }
}

public struct ContractVersionRange: Equatable, Codable, Sendable {
    public let lowerBound: ContractVersion
    public let upperBound: ContractVersion

    public init(lowerBound: ContractVersion, upperBound: ContractVersion) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    public var isValid: Bool { lowerBound <= upperBound }

    public func contains(_ version: ContractVersion) -> Bool {
        lowerBound <= version && version <= upperBound
    }

    public func intersection(with other: Self) -> Self? {
        let lower = max(lowerBound, other.lowerBound)
        let upper = min(upperBound, other.upperBound)
        guard lower <= upper else { return nil }
        return Self(lowerBound: lower, upperBound: upper)
    }
}

public struct ContractSet: Equatable, Codable, Sendable {
    public let ranges: [ContractFamily: ContractVersionRange]

    public init(ranges: [ContractFamily: ContractVersionRange]) {
        self.ranges = ranges
    }

    public static let v1 = Self(
        ranges: Dictionary(
            uniqueKeysWithValues: ContractFamily.allCases.map {
                ($0, ContractVersionRange(
                    lowerBound: ContractVersion(major: 1, minor: 0),
                    upperBound: ContractVersion(major: 1, minor: 0)
                ))
            }
        )
    )
}

public enum ContractNegotiationFailure: Equatable, Sendable {
    case malformedRange(family: ContractFamily)
    case missingFamily(ContractFamily)
    case incompatibleRange(family: ContractFamily, host: ContractVersionRange, peer: ContractVersionRange)
}

public enum ContractActivationFailure: Error, Equatable, Sendable {
    case handshake(ContractNegotiationFailure)
    case unsupportedSchema(ContractFamily)
    case unsupportedRequiredPrimitive(SDUIPrimitive)
    case unavailableCapability(String)
    case untrustedArtifact(String)
    case invalidDependency(String)
}

public struct ContractDeprecation: Codable, Equatable, Sendable {
    public let family: ContractFamily
    public let version: ContractVersion
    public let supportedUntilMajor: UInt16
    public let message: String

    public init(
        family: ContractFamily,
        version: ContractVersion,
        supportedUntilMajor: UInt16,
        message: String
    ) {
        self.family = family
        self.version = version
        self.supportedUntilMajor = supportedUntilMajor
        self.message = message
    }

    public func diagnostic(for selected: ContractVersion) -> String? {
        guard selected == version else { return nil }
        return message
    }
}

public struct ContractMigrationAdapter: Codable, Equatable, Sendable {
    public let identifier: String
    public let family: ContractFamily
    public let from: ContractVersion
    public let to: ContractVersion
    public let deprecation: ContractDeprecation

    public init(
        identifier: String,
        family: ContractFamily,
        from: ContractVersion,
        to: ContractVersion,
        deprecation: ContractDeprecation
    ) {
        self.identifier = identifier
        self.family = family
        self.from = from
        self.to = to
        self.deprecation = deprecation
    }

    public var isOneMajorWindow: Bool {
        to.major >= from.major &&
            to.major - from.major <= 1 &&
            to.major <= deprecation.supportedUntilMajor &&
            deprecation.family == family &&
            deprecation.version == from
    }
}

public enum ContractMigrationDiagnostic: Equatable, Sendable {
    case deprecated(ContractDeprecation)
    case unsupportedMigration(family: ContractFamily, from: ContractVersion, to: ContractVersion)
}

public struct ContractHandshake: Equatable, Sendable {
    public let contracts: ContractSet

    public init(contracts: ContractSet) {
        self.contracts = contracts
    }
}

public enum ContractActivationValidator {
    public static func validateHandshake(
        host: ContractHandshake,
        peer: ContractHandshake
    ) -> Result<NegotiatedContracts, ContractActivationFailure> {
        switch ContractNegotiator.negotiate(host: host.contracts, peer: peer.contracts) {
        case .accepted(let result):
            return .success(result)
        case .rejected(let failure):
            return .failure(.handshake(failure))
        }
    }

    public static func validateRequiredPrimitive(
        _ primitive: SDUIPrimitive,
        supported: Set<SDUIPrimitive>
    ) -> Result<Void, ContractActivationFailure> {
        supported.contains(primitive)
            ? .success(())
            : .failure(.unsupportedRequiredPrimitive(primitive))
    }

    public static func validateCapability(
        _ capability: String,
        available: Set<String>
    ) -> Result<Void, ContractActivationFailure> {
        available.contains(capability)
            ? .success(())
            : .failure(.unavailableCapability(capability))
    }

    public static func validateTrust(
        artifactID: String,
        approved: Set<String>
    ) -> Result<Void, ContractActivationFailure> {
        approved.contains(artifactID)
            ? .success(())
            : .failure(.untrustedArtifact(artifactID))
    }

    public static func validateDependency(
        _ dependency: ArtifactDependency,
        approvedDigests: [String: String]
    ) -> Result<Void, ContractActivationFailure> {
        guard approvedDigests[dependency.identifier] == dependency.sha256 else {
            return .failure(.invalidDependency(dependency.identifier))
        }
        return .success(())
    }
}

public struct NegotiatedContracts: Codable, Equatable, Sendable {
    public let versions: [ContractFamily: ContractVersion]

    public init(versions: [ContractFamily: ContractVersion]) {
        self.versions = versions
    }
}

public enum ContractNegotiationResult: Equatable, Sendable {
    case accepted(NegotiatedContracts)
    case rejected(ContractNegotiationFailure)

    public var negotiated: NegotiatedContracts? {
        guard case .accepted(let value) = self else { return nil }
        return value
    }
}

public enum ContractNegotiator {
    /// The host selects the highest mutually supported version for every family.
    public static func negotiate(
        host: ContractSet,
        peer: ContractSet,
        requiredFamilies: Set<ContractFamily> = Set(ContractFamily.allCases)
    ) -> ContractNegotiationResult {
        var selected: [ContractFamily: ContractVersion] = [:]
        for family in ContractFamily.allCases where requiredFamilies.contains(family) {
            guard let hostRange = host.ranges[family] else {
                return .rejected(.missingFamily(family))
            }
            guard let peerRange = peer.ranges[family] else {
                return .rejected(.missingFamily(family))
            }
            guard hostRange.isValid else {
                return .rejected(.malformedRange(family: family))
            }
            guard peerRange.isValid else {
                return .rejected(.malformedRange(family: family))
            }
            guard let overlap = hostRange.intersection(with: peerRange) else {
                return .rejected(.incompatibleRange(
                    family: family,
                    host: hostRange,
                    peer: peerRange
                ))
            }
            selected[family] = overlap.upperBound
        }
        return .accepted(NegotiatedContracts(versions: selected))
    }
}

public struct ArtifactDependency: Equatable, Codable, Sendable {
    public let identifier: String
    public let source: String
    public let sha256: String
    public let required: Bool

    public init(identifier: String, source: String, sha256: String, required: Bool = true) {
        self.identifier = identifier
        self.source = source
        self.sha256 = sha256
        self.required = required
    }
}

public struct ExtensionManifest: Equatable, Codable, Sendable {
    public let identifier: String
    public let displayName: String
    public let contracts: ContractSet
    public let dependencies: [ArtifactDependency]

    public init(
        identifier: String,
        displayName: String,
        contracts: ContractSet,
        dependencies: [ArtifactDependency] = []
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.contracts = contracts
        self.dependencies = dependencies
    }

    public func validationIssues() -> [ManifestValidationIssue] {
        var issues: [ManifestValidationIssue] = []
        if identifier.isEmpty { issues.append(.emptyIdentifier) }
        if displayName.isEmpty { issues.append(.emptyDisplayName) }
        for family in ContractFamily.allCases {
            guard let range = contracts.ranges[family] else {
                issues.append(.missingContractFamily(family))
                continue
            }
            if !range.isValid { issues.append(.malformedContractRange(family)) }
        }
        var identifiers = Set<String>()
        for dependency in dependencies {
            if dependency.identifier.isEmpty || dependency.source.isEmpty || dependency.sha256.isEmpty {
                issues.append(.malformedDependency(dependency.identifier))
            }
            if !identifiers.insert(dependency.identifier).inserted {
                issues.append(.duplicateDependency(dependency.identifier))
            }
        }
        return issues
    }
}

public enum ManifestValidationIssue: Equatable, Sendable {
    case emptyIdentifier
    case emptyDisplayName
    case missingContractFamily(ContractFamily)
    case malformedContractRange(ContractFamily)
    case malformedDependency(String)
    case duplicateDependency(String)
}

public enum IPCFrameError: Error, Equatable, Sendable {
    case emptyPayload
    case payloadTooLarge
    case invalidLengthPrefix
    case lengthMismatch
}

public struct IPCFrame: Equatable, Sendable {
    public static let maximumPayloadLength = 1_048_576
    public let payload: [UInt8]

    public init(payload: [UInt8]) {
        self.payload = payload
    }

    public var isValid: Bool { !payload.isEmpty && payload.count <= Self.maximumPayloadLength }

    public func encoded() -> [UInt8] {
        let length = UInt32(payload.count)
        return [
            UInt8((length >> 24) & 0xff), UInt8((length >> 16) & 0xff),
            UInt8((length >> 8) & 0xff), UInt8(length & 0xff)
        ] + payload
    }

    public static func decode(_ bytes: [UInt8]) -> Result<Self, IPCFrameError> {
        guard bytes.count >= 4 else { return .failure(.invalidLengthPrefix) }
        let length = (UInt32(bytes[0]) << 24)
            | (UInt32(bytes[1]) << 16)
            | (UInt32(bytes[2]) << 8)
            | UInt32(bytes[3])
        guard length > 0 else { return .failure(.emptyPayload) }
        guard length <= maximumPayloadLength else { return .failure(.payloadTooLarge) }
        guard Int(length) == bytes.count - 4 else { return .failure(.lengthMismatch) }
        return .success(Self(payload: Array(bytes.dropFirst(4))))
    }
}

public enum ConformanceFixtureResult: Equatable, Sendable {
    case passed
    case failed(String)
}

public struct ConformanceFixture: Sendable {
    public let name: String
    public let run: @Sendable () -> ConformanceFixtureResult

    public init(name: String, run: @escaping @Sendable () -> ConformanceFixtureResult) {
        self.name = name
        self.run = run
    }
}

public enum ContractConformance {
    public static let sharedFixtures: [SharedConformanceFixture] = [
        fixture("valid-v1-negotiation", .validNegotiation, .pass),
        fixture("incompatible-schema", .incompatibleSchema, .reject),
        fixture("typed-activation-failures", .typedActivationFailures, .reject),
        fixture("version-boundary", .versionBoundary, .pass),
        fixture("malformed-manifest", .malformedManifest, .reject),
        fixture("stale-sdui-update", .staleSDUI, .reject),
        fixture("unsupported-required-primitive", .unsupportedRequiredPrimitive, .reject),
        fixture("ipc-boundary-frame", .validIPC, .pass),
        fixture("ipc-invalid-frame", .invalidIPC, .reject)
    ]

    private static func fixture(
        _ identifier: String,
        _ scenario: SharedFixtureScenario,
        _ expectation: SharedFixtureExpectation
    ) -> SharedConformanceFixture {
        SharedConformanceFixture(
            identifier: identifier,
            scenario: scenario,
            expectation: expectation,
            payload: Data(scenario.rawValue.utf8)
        )
    }

    public static func encodedSharedFixtures() throws -> Data {
        try JSONEncoder().encode(sharedFixtures)
    }

    public static func loadCanonicalFixtures() throws -> [SharedConformanceFixture] {
        guard let url = Bundle.module.url(
            forResource: "conformance-v1",
            withExtension: "json"
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(
            [SharedConformanceFixture].self,
            from: Data(contentsOf: url)
        )
    }

    public static func runSharedFixtures(
        _ encoded: Data? = nil
    ) throws -> [String] {
        let fixtures = try encoded.map { try JSONDecoder().decode(
            [SharedConformanceFixture].self,
            from: $0
        ) } ?? sharedFixtures
        let canonical = try loadCanonicalFixtures()
        guard fixtures == canonical else {
            return ["fixture set differs from canonical conformance vectors"]
        }
        return fixtures.flatMap { fixture in
            guard Data(fixture.scenario.rawValue.utf8) == fixture.payload else {
                return ["\(fixture.identifier): payload does not match scenario"]
            }
            return evaluateSharedFixture(fixture)
        }
    }

    private static func evaluateSharedFixture(
        _ fixture: SharedConformanceFixture
    ) -> [String] {
        let accepted: Bool
        switch fixture.scenario {
        case .validNegotiation:
            accepted = ContractNegotiator.negotiate(host: .v1, peer: .v1).negotiated != nil
        case .incompatibleSchema:
            accepted = ContractNegotiator.negotiate(
                host: ContractSet(ranges: [.sdui: ContractVersionRange(
                    lowerBound: ContractVersion(major: 2, minor: 0),
                    upperBound: ContractVersion(major: 2, minor: 0)
                )]),
                peer: ContractSet(ranges: [.sdui: ContractVersionRange(
                    lowerBound: ContractVersion(major: 1, minor: 0),
                    upperBound: ContractVersion(major: 1, minor: 0)
                )]),
                requiredFamilies: [.sdui]
            ).negotiated != nil
        case .typedActivationFailures:
            let handshake = ContractActivationValidator.validateHandshake(
                host: ContractHandshake(contracts: .v1),
                peer: ContractHandshake(contracts: ContractSet(ranges: [:]))
            )
            let capability = ContractActivationValidator.validateCapability(
                "clipboard.read-write",
                available: []
            )
            let trust = ContractActivationValidator.validateTrust(
                artifactID: "unsigned",
                approved: []
            )
            let dependency = ContractActivationValidator.validateDependency(
                ArtifactDependency(identifier: "librespeed", source: "source", sha256: "actual"),
                approvedDigests: ["librespeed": "expected"]
            )
            accepted = !(isExpectedFailure(handshake) &&
                isExpectedFailure(capability) &&
                isExpectedFailure(trust) &&
                isExpectedFailure(dependency))
        case .versionBoundary:
            let version = ContractVersion(major: 1, minor: 1)
            let range = ContractVersionRange(lowerBound: .init(major: 1, minor: 0), upperBound: version)
            accepted = ContractNegotiator.negotiate(
                host: ContractSet(ranges: Dictionary(uniqueKeysWithValues: ContractFamily.allCases.map { ($0, range) })),
                peer: ContractSet(ranges: Dictionary(uniqueKeysWithValues: ContractFamily.allCases.map { ($0, range) }))
            ).negotiated?.versions.values.allSatisfy { $0 == version } ?? false
        case .malformedManifest:
            accepted = ExtensionManifest(identifier: "", displayName: "", contracts: .v1)
                .validationIssues().isEmpty
        case .staleSDUI:
            let tree = SDUITree.speedTest(title: "Network test", progress: 0, status: "Starting")
            var state = SDUIState(tree: tree, revision: 1)
            accepted = state.apply(.snapshot(SDUISnapshot(revision: 1, tree: tree))).accepted
        case .unsupportedRequiredPrimitive:
            accepted = SDUIPrimitive.approved.contains(.chart)
        case .validIPC:
            if case .success = IPCFrame.decode(IPCFrame(payload: [1]).encoded()) {
                accepted = true
            } else {
                accepted = false
            }
        case .invalidIPC:
            if case .success = IPCFrame.decode([0, 0, 0, 2, 1]) {
                accepted = true
            } else {
                accepted = false
            }
        }
        let expectedAcceptance = fixture.expectation == .pass
        return accepted == expectedAcceptance ? [] : ["\(fixture.identifier): unexpected result"]
    }

    private static func isExpectedFailure<T>(
        _ result: Result<T, ContractActivationFailure>
    ) -> Bool {
        if case .failure = result { return true }
        return false
    }

    public static let fixtures: [ConformanceFixture] = sharedFixtures.map { fixture in
        ConformanceFixture(name: fixture.identifier) {
            let failures = evaluateSharedFixture(fixture)
            return failures.isEmpty ? .passed : .failed(failures.joined(separator: "; "))
        }
    }

    @discardableResult
    public static func run() -> [String] {
        fixtures.compactMap { fixture in
            switch fixture.run() {
            case .passed: return nil
            case .failed(let message): return "\(fixture.name): \(message)"
            }
        }
    }
}
