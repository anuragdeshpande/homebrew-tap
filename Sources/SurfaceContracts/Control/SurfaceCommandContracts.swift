import Foundation

/// Versioned, platform-neutral control protocol shared by every host and the CLI.
public enum SurfaceControlProtocol {
    public static let version = "1.0"
    public static let defaultHost = "127.0.0.1"
    public static let defaultPort: UInt16 = 4848
}

/// How a command affects the system. Lets agents tell persistent settings
/// apart from transient state changes, simulated events, and read-only queries.
public enum SurfaceCommandCategory: String, Codable, CaseIterable, Sendable {
    case setting
    case state
    case event
    case query
}

public enum SurfaceCommandParamKind: String, Codable, Sendable {
    case string
    case number
    case bool
    case enumeration
}

/// Typed description of one command parameter, so clients can validate and
/// render help without hardcoding anything.
public struct SurfaceCommandParam: Codable, Equatable, Sendable {
    public let name: String
    public let kind: SurfaceCommandParamKind
    public let summary: String
    public let required: Bool
    public let allowedValues: [String]?
    public let minimum: Double?
    public let maximum: Double?

    public init(
        name: String,
        kind: SurfaceCommandParamKind,
        summary: String,
        required: Bool = true,
        allowedValues: [String]? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil
    ) {
        self.name = name
        self.kind = kind
        self.summary = summary
        self.required = required
        self.allowedValues = allowedValues
        self.minimum = minimum
        self.maximum = maximum
    }

    public static func string(_ name: String, _ summary: String, required: Bool = true) -> Self {
        Self(name: name, kind: .string, summary: summary, required: required)
    }

    public static func bool(_ name: String, _ summary: String, required: Bool = true) -> Self {
        Self(name: name, kind: .bool, summary: summary, required: required)
    }

    public static func number(
        _ name: String,
        _ summary: String,
        range: ClosedRange<Double>? = nil,
        required: Bool = true
    ) -> Self {
        Self(
            name: name,
            kind: .number,
            summary: summary,
            required: required,
            minimum: range?.lowerBound,
            maximum: range?.upperBound
        )
    }

    public static func choice<E: CaseIterable & RawRepresentable>(
        _ name: String,
        _ summary: String,
        _ type: E.Type,
        required: Bool = true
    ) -> Self where E.RawValue == String {
        Self(
            name: name,
            kind: .enumeration,
            summary: summary,
            required: required,
            allowedValues: type.allCases.map(\.rawValue)
        )
    }

    public static func choice(
        _ name: String,
        _ summary: String,
        values: [String],
        required: Bool = true
    ) -> Self {
        Self(name: name, kind: .enumeration, summary: summary, required: required, allowedValues: values)
    }
}

/// Discoverable command definition served at `GET /api/v1/commands`.
public struct SurfaceCommandDescriptor: Codable, Equatable, Sendable {
    public let name: String
    public let category: SurfaceCommandCategory
    public let summary: String
    public let params: [SurfaceCommandParam]
    /// Persisted settings key this command controls, if any.
    public let settingKey: String?

    public init(
        name: String,
        category: SurfaceCommandCategory,
        summary: String,
        params: [SurfaceCommandParam] = [],
        settingKey: String? = nil
    ) {
        self.name = name
        self.category = category
        self.summary = summary
        self.params = params
        self.settingKey = settingKey
    }
}

public struct SurfaceCommandCatalog: Codable, Equatable, Sendable {
    public let protocolVersion: String
    public let platform: String
    public let commands: [SurfaceCommandDescriptor]

    public init(protocolVersion: String, platform: String, commands: [SurfaceCommandDescriptor]) {
        self.protocolVersion = protocolVersion
        self.platform = platform
        self.commands = commands
    }
}

/// Response body for `POST /api/v1/commands/{name}`.
public struct SurfaceCommandResult: Codable, Equatable, Sendable {
    public let command: String
    public let ok: Bool
    public let message: String?
    public let result: ControlValue

    public init(command: String, ok: Bool, message: String? = nil, result: ControlValue = .null) {
        self.command = command
        self.ok = ok
        self.message = message
        self.result = result
    }
}
