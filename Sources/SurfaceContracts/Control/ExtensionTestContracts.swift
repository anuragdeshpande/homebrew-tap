import Foundation

/// Canonical descriptor for an Archipelago extension discovered on the system.
public struct ExtensionDescriptor: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let version: String
    public let summary: String
    public let author: String
    public let category: String
    public let runtime: String
    public let binaryPath: String
    public let status: String
    public let capabilities: [String]
    public let surfaces: [String]

    public init(
        id: String,
        name: String,
        version: String,
        summary: String,
        author: String,
        category: String,
        runtime: String,
        binaryPath: String,
        status: String,
        capabilities: [String],
        surfaces: [String]
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.summary = summary
        self.author = author
        self.category = category
        self.runtime = runtime
        self.binaryPath = binaryPath
        self.status = status
        self.capabilities = capabilities
        self.surfaces = surfaces
    }
}

/// A single assertion check within an extension verification test run.
public struct ExtensionAssertionResult: Codable, Equatable, Sendable {
    public let name: String
    public let passed: Bool
    public let latencyMs: Double
    public let details: String

    public init(name: String, passed: Bool, latencyMs: Double, details: String) {
        self.name = name
        self.passed = passed
        self.latencyMs = latencyMs
        self.details = details
    }
}

/// The aggregated test result for an extension.
public struct ExtensionTestResult: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let status: String
    public let assertions: [ExtensionAssertionResult]
    public let totalAssertions: Int
    public let passedAssertions: Int
    public let durationMs: Double
    public let exitCode: Int32
    public let sduiTreeValid: Bool

    public init(
        id: String,
        name: String,
        status: String,
        assertions: [ExtensionAssertionResult],
        totalAssertions: Int,
        passedAssertions: Int,
        durationMs: Double,
        exitCode: Int32,
        sduiTreeValid: Bool
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.assertions = assertions
        self.totalAssertions = totalAssertions
        self.passedAssertions = passedAssertions
        self.durationMs = durationMs
        self.exitCode = exitCode
        self.sduiTreeValid = sduiTreeValid
    }
}

/// Complete extension test suite summary exported to CLI and JSON reports.
public struct ExtensionTestSuiteSummary: Codable, Equatable, Sendable {
    public let totalExtensions: Int
    public let passedExtensions: Int
    public let failedExtensions: Int
    public let passRate: Double
    public let totalDurationMs: Double
    public let results: [ExtensionTestResult]

    public init(
        totalExtensions: Int,
        passedExtensions: Int,
        failedExtensions: Int,
        passRate: Double,
        totalDurationMs: Double,
        results: [ExtensionTestResult]
    ) {
        self.totalExtensions = totalExtensions
        self.passedExtensions = passedExtensions
        self.failedExtensions = failedExtensions
        self.passRate = passRate
        self.totalDurationMs = totalDurationMs
        self.results = results
    }
}
