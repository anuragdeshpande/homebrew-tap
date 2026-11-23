import Foundation

/// A single rendered content node in the surface hierarchy (text, symbol, slider, button, badge).
public struct SurfaceContentNode: Codable, Equatable, Sendable {
    public let id: String
    /// Semantic role: `text`, `image`, `button`, `slider`, `badge`, `container`
    public let role: String
    /// Displayed text string, SF symbol name, percentage string, etc.
    public let value: String
    /// Hex color code or semantic tone name (e.g. "#33E085", "#26D1F2", "accent")
    public let toneColor: String?
    /// Accessibility label string for ScreenReader / VoiceOver audit
    public let accessibilityLabel: String?
    /// Sub-nodes in the container hierarchy
    public let children: [SurfaceContentNode]

    public init(
        id: String,
        role: String,
        value: String,
        toneColor: String? = nil,
        accessibilityLabel: String? = nil,
        children: [SurfaceContentNode] = []
    ) {
        self.id = id
        self.role = role
        self.value = value
        self.toneColor = toneColor
        self.accessibilityLabel = accessibilityLabel
        self.children = children
    }
}

/// The complete content tree of all active surface areas.
public struct SurfaceContentTree: Codable, Equatable, Sendable {
    /// Active surface style: `island`, `notch`, `pill`
    public let surfaceStyle: String
    /// Active lifecycle state: `idle`, `hover`, `expanded`, `liveActivity`
    public let lifecycleState: String
    /// Active visual theme: `matteBlack`, `liquidGlass`, `dynamicGlass`, etc.
    public let theme: String
    /// Whether the dropdown shelf window is open
    public let isShelfOpen: Bool
    /// Whether notch wings are visible
    public let wingsVisible: Bool
    /// Active live activity ID if any
    public let activeLiveActivityId: String?
    /// All discovered content nodes across active surfaces
    public let nodes: [SurfaceContentNode]

    public init(
        surfaceStyle: String,
        lifecycleState: String,
        theme: String,
        isShelfOpen: Bool,
        wingsVisible: Bool,
        activeLiveActivityId: String? = nil,
        nodes: [SurfaceContentNode]
    ) {
        self.surfaceStyle = surfaceStyle
        self.lifecycleState = lifecycleState
        self.theme = theme
        self.isShelfOpen = isShelfOpen
        self.wingsVisible = wingsVisible
        self.activeLiveActivityId = activeLiveActivityId
        self.nodes = nodes
    }
}
