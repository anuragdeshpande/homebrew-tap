import Foundation

/// Platform-neutral JSON value used by the control protocol for command
/// arguments and results. Every host (macOS, future Windows) exchanges these
/// over the same REST + SSE contract.
public indirect enum ControlValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([ControlValue])
    case object([String: ControlValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([ControlValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: ControlValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported control value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    /// Converts any `Encodable` model into a `ControlValue` tree.
    public static func from<T: Encodable>(_ value: T) -> ControlValue {
        guard let data = try? JSONEncoder().encode(value),
              let decoded = try? JSONDecoder().decode(ControlValue.self, from: data) else {
            return .null
        }
        return decoded
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var numberValue: Double? {
        if case .number(let value) = self { return value }
        if case .string(let value) = self { return Double(value) }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        if case .string(let value) = self {
            if value.lowercased() == "true" { return true }
            if value.lowercased() == "false" { return false }
        }
        return nil
    }
}
