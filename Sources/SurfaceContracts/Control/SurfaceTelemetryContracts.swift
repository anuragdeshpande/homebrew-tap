import Foundation

/// Event types streamed on `GET /api/v1/telemetry/stream` (Server-Sent Events).
public enum SurfaceTelemetryEventType: String, Codable, CaseIterable, Sendable {
    case hello
    case state
    case geometry
    case screens
    case command
    case haptic
}

/// Record of an emitted tactile haptic event on trackpads or native haptic devices.
public struct HapticEventRecord: Codable, Equatable, Sendable {
    public let id: String
    public let pattern: String
    public let source: String
    public let timestamp: Double

    public init(
        id: String = UUID().uuidString,
        pattern: String,
        source: String,
        timestamp: Double = Date().timeIntervalSince1970 * 1000.0
    ) {
        self.id = id
        self.pattern = pattern
        self.source = source
        self.timestamp = timestamp
    }
}

public struct HapticsStatusResponse: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let count: Int
    public let events: [HapticEventRecord]

    public init(enabled: Bool, count: Int, events: [HapticEventRecord]) {
        self.enabled = enabled
        self.count = count
        self.events = events
    }
}

/// Rectangle in global, bottom-left-origin points (the host's native space,
/// documented per platform in the `hello` event).
public struct TelemetryRect: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct TelemetryPoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct TelemetryScreen: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let frame: TelemetryRect
    public let visibleFrame: TelemetryRect
    public let backingScale: Double
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let hasPhysicalNotch: Bool
    public let isMain: Bool

    public init(
        id: String,
        name: String,
        frame: TelemetryRect,
        visibleFrame: TelemetryRect,
        backingScale: Double,
        pixelWidth: Int,
        pixelHeight: Int,
        hasPhysicalNotch: Bool,
        isMain: Bool
    ) {
        self.id = id
        self.name = name
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.backingScale = backingScale
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.hasPhysicalNotch = hasPhysicalNotch
        self.isMain = isMain
    }
}

/// One drawn element (a host window or a probed shape inside it).
public struct TelemetrySurfaceGeometry: Codable, Equatable, Sendable {
    /// Stable identifier, e.g. `island.window` or `island.shape.shell`.
    public let id: String
    /// Element kind: `window` or `shape`.
    public let kind: String
    public let screenId: String?
    public let isVisible: Bool
    public let alpha: Double
    /// Frame in global points.
    public let frame: TelemetryRect
    /// Frame relative to the owning screen's origin.
    public let frameInScreen: TelemetryRect?
    /// Center normalized to the owning screen (0...1 on each axis).
    public let normalizedCenter: TelemetryPoint?

    public init(
        id: String,
        kind: String,
        screenId: String?,
        isVisible: Bool,
        alpha: Double,
        frame: TelemetryRect,
        frameInScreen: TelemetryRect?,
        normalizedCenter: TelemetryPoint?
    ) {
        self.id = id
        self.kind = kind
        self.screenId = screenId
        self.isVisible = isVisible
        self.alpha = alpha
        self.frame = frame
        self.frameInScreen = frameInScreen
        self.normalizedCenter = normalizedCenter
    }
}

public struct TelemetryGeometryFrame: Codable, Equatable, Sendable {
    /// True while any element changed since the previous sample.
    public let isAnimating: Bool
    public let surfaces: [TelemetrySurfaceGeometry]

    public init(isAnimating: Bool, surfaces: [TelemetrySurfaceGeometry]) {
        self.isAnimating = isAnimating
        self.surfaces = surfaces
    }
}

/// Envelope written as the `data:` line of every SSE event.
public struct SurfaceTelemetryEnvelope<Payload: Encodable & Sendable>: Encodable, Sendable {
    public let seq: UInt64
    /// Milliseconds since the Unix epoch.
    public let timestamp: Double
    public let type: SurfaceTelemetryEventType
    public let data: Payload

    public init(seq: UInt64, timestamp: Double, type: SurfaceTelemetryEventType, data: Payload) {
        self.seq = seq
        self.timestamp = timestamp
        self.type = type
        self.data = data
    }
}

public struct SurfaceTelemetryStatus: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let hz: Double?
    public let listeners: Int

    public init(enabled: Bool, hz: Double?, listeners: Int) {
        self.enabled = enabled
        self.hz = hz
        self.listeners = listeners
    }
}
