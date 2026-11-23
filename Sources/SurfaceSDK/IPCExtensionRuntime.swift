import Foundation
import SurfaceContracts

/// Typed permission declaration sent during `register_extension` handshake.
public struct ExtensionPermissionDeclaration: Codable, Equatable, Sendable {
    public let name: String
    public let title: String?
    public let kind: String
    public let justification: String
    public let systemPermission: String?

    enum CodingKeys: String, CodingKey {
        case name
        case title
        case kind
        case justification
        case systemPermission = "system_permission"
    }

    public init(
        name: String,
        title: String? = nil,
        kind: String = "host_delegated",
        justification: String,
        systemPermission: String? = nil
    ) {
        self.name = name
        self.title = title
        self.kind = kind
        self.justification = justification
        self.systemPermission = systemPermission
    }

    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "kind": kind,
            "justification": justification
        ]
        if let title {
            dict["title"] = title
        }
        if let systemPermission {
            dict["system_permission"] = systemPermission
        }
        return dict
    }
}

/// Errors thrown while decoding 4-byte big-endian length-prefixed JSON IPC frames.
public enum ExtensionIPCError: Error, Equatable, Sendable, LocalizedError {
    case truncatedLengthHeader
    case truncatedPayload(expected: Int, actual: Int)
    case invalidJSONObject

    public var errorDescription: String? {
        switch self {
        case .truncatedLengthHeader:
            return "Truncated 4-byte IPC frame length header."
        case .truncatedPayload(let expected, let actual):
            return "Truncated IPC frame payload (expected \(expected) bytes, got \(actual))."
        case .invalidJSONObject:
            return "IPC frame body is not a valid JSON object."
        }
    }
}

/// Decoded inbound IPC frame received from `ExtensionHostManager` over `stdin`.
public struct ExtensionIPCFrame: Equatable, Sendable {
    public let kind: String
    public let requestID: String?
    public let method: String?
    public let nonce: String?
    public let payloadData: Data?

    public init(
        kind: String,
        requestID: String? = nil,
        method: String? = nil,
        nonce: String? = nil,
        payloadData: Data? = nil
    ) {
        self.kind = kind
        self.requestID = requestID
        self.method = method
        self.nonce = nonce
        self.payloadData = payloadData
    }

    /// Parses `payloadData` as a JSON dictionary when the payload is an object.
    public func payloadDictionary() -> [String: Any]? {
        guard let payloadData else { return nil }
        return (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any]
    }

    /// Decodes `payloadData` into a strongly typed `Decodable` value.
    public func decodePayload<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T? {
        guard let payloadData else { return nil }
        return try decoder.decode(type, from: payloadData)
    }

    /// Decodes `payloadData` as a UTF-8 string.
    public func payloadString() -> String? {
        payloadData.flatMap { String(data: $0, encoding: .utf8) }
    }
}

/// Pure wire-framing helpers for 4-byte big-endian length-prefixed JSON IPC.
public enum ExtensionIPCFraming {
    public static func encodeFrame(_ body: Data) -> Data {
        var length = UInt32(body.count).bigEndian
        var frame = Data(bytes: &length, count: 4)
        frame.append(body)
        return frame
    }

    public static func parseFrameBody(_ bodyData: Data) throws -> ExtensionIPCFrame {
        guard let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
            throw ExtensionIPCError.invalidJSONObject
        }

        let kind = json["kind"] as? String ?? ""
        let requestID = (json["requestID"] as? String) ?? (json["request_id"] as? String)
        let method = json["method"] as? String
        let nonce = json["nonce"] as? String
        let rawPayload = json["payload"]

        let payloadData: Data?
        if let base64OrString = rawPayload as? String {
            payloadData = Data(base64Encoded: base64OrString) ?? base64OrString.data(using: .utf8)
        } else if let obj = rawPayload as? [String: Any] {
            payloadData = try? JSONSerialization.data(withJSONObject: obj)
        } else if let arr = rawPayload as? [Any] {
            payloadData = try? JSONSerialization.data(withJSONObject: arr)
        } else {
            payloadData = nil
        }

        return ExtensionIPCFrame(
            kind: kind,
            requestID: requestID,
            method: method,
            nonce: nonce,
            payloadData: payloadData
        )
    }

    /// Reads the next length-prefixed JSON frame from `handle`, returning `nil` on clean EOF.
    public static func readFrame(from handle: FileHandle = .standardInput) throws -> ExtensionIPCFrame? {
        let lengthData = try handle.read(upToCount: 4) ?? Data()
        if lengthData.isEmpty {
            return nil
        }
        guard lengthData.count == 4 else {
            throw ExtensionIPCError.truncatedLengthHeader
        }
        let length = Int(lengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
        let bodyData = try handle.read(upToCount: length) ?? Data()
        guard bodyData.count == length else {
            throw ExtensionIPCError.truncatedPayload(expected: length, actual: bodyData.count)
        }
        return try parseFrameBody(bodyData)
    }
}

/// Thread-safe length-prefixed JSON IPC writer for Swift Archipelago extensions.
public final class ExtensionIPCWriter: @unchecked Sendable {
    private let handle: FileHandle
    private let lock = NSLock()

    public init(handle: FileHandle = .standardOutput) {
        self.handle = handle
    }

    public func writeFrameData(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        let frame = ExtensionIPCFraming.encodeFrame(data)
        try? handle.write(contentsOf: frame)
    }

    public func writeJSONObject(_ object: Any) throws {
        let data = try JSONSerialization.data(withJSONObject: object)
        writeFrameData(data)
    }

    public func writeEncodable<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) throws {
        let data = try encoder.encode(value)
        writeFrameData(data)
    }

    public func sendHandshake(
        name: String,
        icon: String? = nil,
        surfaces: [String] = [],
        permissions: [ExtensionPermissionDeclaration] = []
    ) throws {
        var payload: [String: Any] = [
            "name": name,
            "permissions": permissions.map { $0.toDictionary() }
        ]
        if let icon {
            payload["icon"] = icon
        }
        if !surfaces.isEmpty {
            payload["surfaces"] = surfaces
        }
        try writeJSONObject([
            "kind": "handshake",
            "method": "register_extension",
            "payload": payload
        ])
    }

    public func sendHeartbeatAck(nonce: String?) throws {
        var envelope: [String: Any] = ["kind": "heartbeatAck"]
        if let nonce {
            envelope["nonce"] = nonce
        }
        try writeJSONObject(envelope)
    }

    public func sendEvent(method: String, payload: Any) throws {
        try writeJSONObject([
            "kind": "event",
            "method": method,
            "payload": payload
        ])
    }

    /// Publishes declarative menu bar items for this extension into the host menu bar.
    public func setMenuBarItems(_ spec: ExtensionMenuBarSpec, encoder: JSONEncoder = JSONEncoder()) throws {
        let specData = try encoder.encode(spec)
        let specObject = try JSONSerialization.jsonObject(with: specData)
        try sendEvent(method: "set_menu_bar_items", payload: specObject)
    }

    /// Removes this extension's menu bar submenu from the host menu bar.
    public func clearMenuBarItems() throws {
        try sendEvent(method: "clear_menu_bar_items", payload: [String: Any]())
    }

    public func sendResponse(requestID: String, payload: Data, nonce: String? = nil) throws {
        var envelope: [String: Any] = [
            "kind": "response",
            "requestID": requestID,
            "payload": payload.base64EncodedString()
        ]
        if let nonce {
            envelope["nonce"] = nonce
        }
        try writeJSONObject(envelope)
    }

    public func sendError(requestID: String?, message: String, nonce: String? = nil) throws {
        var envelope: [String: Any] = [
            "kind": "error",
            "error": message
        ]
        if let requestID {
            envelope["requestID"] = requestID
        }
        if let nonce {
            envelope["nonce"] = nonce
        }
        try writeJSONObject(envelope)
    }
}
