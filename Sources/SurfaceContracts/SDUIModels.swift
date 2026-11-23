import Foundation

public enum SDUIPrimitive: String, CaseIterable, Hashable, Codable, Sendable {
    case text
    case progress
    case button
    case image
    case container
    case chart

    public static let approved: Set<SDUIPrimitive> = [
        .text,
        .progress,
        .button,
        .image,
        .container
    ]
}

public enum SDUIAccessibilityRole: String, Codable, Equatable, Sendable {
    case text
    case progressIndicator
    case button
    case image
    case group
}

public struct SDUIAccessibilityMetadata: Codable, Equatable, Sendable {
    public let role: SDUIAccessibilityRole
    public let label: String
    public let value: String?
    public let hint: String?
    public let isLiveRegion: Bool

    public init(
        role: SDUIAccessibilityRole,
        label: String,
        value: String? = nil,
        hint: String? = nil,
        isLiveRegion: Bool = false
    ) {
        self.role = role
        self.label = label
        self.value = value
        self.hint = hint
        self.isLiveRegion = isLiveRegion
    }

    public static func text(label: String, isLiveRegion: Bool = false) -> Self {
        Self(role: .text, label: label, isLiveRegion: isLiveRegion)
    }

    public static func progress(label: String, value: String) -> Self {
        Self(role: .progressIndicator, label: label, value: value, isLiveRegion: true)
    }

    public static func button(label: String, hint: String? = nil) -> Self {
        Self(role: .button, label: label, hint: hint)
    }
}

public enum SDUIActionIntent: String, Codable, Equatable, Sendable {
    case cancel
    case togglePlayback
}

public enum SDUISpeedTestState: Codable, Equatable, Sendable {
    case ready
    case measuring(progress: Double)
    case completed
    case failed(message: String)
    case cancelled
}

public indirect enum SDUIFallback: Codable, Equatable, Sendable {
    case node(SDUINode)
}

public struct SDUIAction: Codable, Equatable, Sendable {
    public let id: String
    public let intent: SDUIActionIntent
    public let accessibility: SDUIAccessibilityMetadata

    public init(
        id: String,
        intent: SDUIActionIntent,
        accessibility: SDUIAccessibilityMetadata
    ) {
        self.id = id
        self.intent = intent
        self.accessibility = accessibility
    }
}

public struct SDUINode: Codable, Equatable, Sendable {
    public let id: String
    public let primitive: SDUIPrimitive
    public let value: String?
    public let progress: Double?
    public let children: [SDUINode]
    public let action: SDUIAction?
    public let accessibility: SDUIAccessibilityMetadata?
    public let fallback: SDUIFallback?
    public let isRequired: Bool

    public init(
        id: String,
        primitive: SDUIPrimitive,
        value: String? = nil,
        progress: Double? = nil,
        children: [SDUINode] = [],
        action: SDUIAction? = nil,
        accessibility: SDUIAccessibilityMetadata? = nil,
        fallback: SDUIFallback? = nil,
        isRequired: Bool = false
    ) {
        self.id = id
        self.primitive = primitive
        self.value = value
        self.progress = progress
        self.children = children
        self.action = action
        self.accessibility = accessibility
        self.fallback = fallback
        self.isRequired = isRequired
    }

    public static func text(
        id: String,
        value: String,
        accessibility: SDUIAccessibilityMetadata
    ) -> Self {
        Self(
            id: id,
            primitive: .text,
            value: value,
            accessibility: accessibility
        )
    }

    public static func progress(
        id: String,
        value: Double,
        accessibility: SDUIAccessibilityMetadata
    ) -> Self {
        Self(
            id: id,
            primitive: .progress,
            progress: value,
            accessibility: accessibility
        )
    }

    public static func button(
        id: String,
        action: SDUIAction,
        accessibility: SDUIAccessibilityMetadata
    ) -> Self {
        Self(
            id: id,
            primitive: .button,
            action: action,
            accessibility: accessibility
        )
    }
}

public struct SDUITree: Codable, Equatable, Sendable {
    public let version: UInt16
    public let root: SDUINode

    public init(version: UInt16, root: SDUINode) {
        self.version = version
        self.root = root
    }

    public static func speedTest(
        title: String,
        progress: Double,
        status: String
    ) -> Self {
        makeSpeedTest(
            title: title,
            progress: progress,
            status: status
        )
    }

    public static func speedTest(
        title: String,
        state: SDUISpeedTestState
    ) -> Self {
        switch state {
        case .ready:
            return makeSpeedTest(
                title: title,
                progress: 0,
                status: "Ready to start"
            )
        case .measuring(let progress):
            return makeSpeedTest(
                title: title,
                progress: progress,
                status: "Testing network speed"
            )
        case .completed:
            return makeSpeedTest(
                title: title,
                progress: 1,
                status: "Network test complete"
            )
        case .failed(let message):
            return makeSpeedTest(
                title: title,
                progress: 1,
                status: message
            )
        case .cancelled:
            return makeSpeedTest(
                title: title,
                progress: 0,
                status: "Network test cancelled"
            )
        }
    }

    private static func makeSpeedTest(
        title: String,
        progress: Double,
        status: String
    ) -> Self {
        let cancelAccessibility = SDUIAccessibilityMetadata.button(
            label: "Cancel network test",
            hint: "Stops the current network test"
        )
        return Self(
            version: 1,
            root: SDUINode(
                id: "root",
                primitive: .container,
                children: [
                    .text(
                        id: "title",
                        value: title,
                        accessibility: .text(label: title)
                    ),
                    SDUINode(
                        id: "network-icon",
                        primitive: .image,
                        value: "network",
                        accessibility: .init(
                            role: .image,
                            label: "Network speed test"
                        )
                    ),
                    .progress(
                        id: "progress",
                        value: progress,
                        accessibility: .progress(
                            label: "Network test progress",
                            value: "\(Int(progress * 100)) percent"
                        )
                    ),
                    .text(
                        id: "status",
                        value: status,
                        accessibility: .text(
                            label: "Network test status",
                            isLiveRegion: true
                        )
                    ),
                    .button(
                        id: "cancel",
                        action: SDUIAction(
                            id: "cancel",
                            intent: .cancel,
                            accessibility: cancelAccessibility
                        ),
                        accessibility: cancelAccessibility
                    )
                ],
                accessibility: .init(role: .group, label: "Network test")
            )
        )
    }

    public static func musicPlayer(title: String, isPlaying: Bool) -> Self {
        let label = isPlaying ? "Pause" : "Play"
        let accessibility = SDUIAccessibilityMetadata.button(
            label: label,
            hint: "Toggles playback"
        )
        return Self(
            version: 1,
            root: SDUINode(
                id: "root",
                primitive: .container,
                children: [
                    .text(
                        id: "title",
                        value: title,
                        accessibility: .text(label: title)
                    ),
                    .button(
                        id: "play-pause",
                        action: SDUIAction(
                            id: "play-pause",
                            intent: .togglePlayback,
                            accessibility: accessibility
                        ),
                        accessibility: accessibility
                    )
                ],
                accessibility: .init(role: .group, label: "Music player")
            )
        )
    }

    public func contains(primitive: SDUIPrimitive) -> Bool {
        node(where: { $0.primitive == primitive }) != nil
    }

    public func node(id: String) -> SDUINode? {
        node(where: { $0.id == id })
    }

    public func action(id: String) -> SDUIAction? {
        node(id: id)?.action
    }

    public func node(where predicate: (SDUINode) -> Bool) -> SDUINode? {
        if predicate(root) {
            return root
        }
        return root.allNodes().first(where: predicate)
    }

    public func allNodes() -> [SDUINode] {
        [root] + root.children.flatMap { [$0] + $0.allNodes() }
    }
}

public extension SDUINode {
    func allNodes() -> [SDUINode] {
        children.flatMap { [$0] + $0.allNodes() }
    }
}
