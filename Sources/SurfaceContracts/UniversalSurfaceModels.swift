import Foundation

public enum SurfaceKind: String, Codable, CaseIterable, Sendable {
    case island
    case notchWings
    case shelf
    case ring
    case selectionHUD
}

public enum ArchipelagoTheme: String, Codable, CaseIterable, Sendable {
    case dynamicGlass = "dynamicGlass"
    case black = "black"

    /// Canonical display alias for the unified Glass theme.
    public static let glass: ArchipelagoTheme = .dynamicGlass
    /// Backward-compatibility alias migrating legacy `.liquidGlass` callers to unified `Glass`.
    public static let liquidGlass: ArchipelagoTheme = .dynamicGlass

    public var title: String {
        switch self {
        case .dynamicGlass: return "Glass"
        case .black: return "Black"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "dynamicGlass", "glass", "liquidGlass":
            self = .dynamicGlass
        case "black":
            self = .black
        default:
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ArchipelagoTheme(rawValue: raw) ?? .dynamicGlass
    }
}

/// Identifies an individual Archipelago surface whose material theme can override the global theme.
public enum ArchipelagoSurfaceThemeTarget: String, Codable, CaseIterable, Sendable {
    case primary = "primary"
    case radialRing = "radialRing"
    case selectionHUD = "selectionHUD"
    case voiceTranscribe = "voiceTranscribe"
    case dockWidget = "dockWidget"
    case dockPreview = "dockPreview"

    public var title: String {
        switch self {
        case .primary: return "Primary Surface (Notch / Island / Pill)"
        case .radialRing: return "Radial Ring"
        case .selectionHUD: return "Text Selection Popover"
        case .voiceTranscribe: return "Voice Transcription Bubble"
        case .dockWidget: return "Dock Widget"
        case .dockPreview: return "Dock Preview"
        }
    }
}

public enum ArchipelagoAppIconLocation: String, Codable, CaseIterable, Sendable {
    case menuBar = "menuBar"
    case dock = "dock"

    public var title: String {
        switch self {
        case .menuBar: return "Menu Bar"
        case .dock: return "Dock"
        }
    }
}

public struct SurfacePoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct SurfaceSize: Codable, Equatable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct SurfaceRect: Codable, Equatable, Sendable {
    public let origin: SurfacePoint
    public let size: SurfaceSize

    public init(origin: SurfacePoint, size: SurfaceSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = SurfacePoint(x: x, y: y)
        self.size = SurfaceSize(width: width, height: height)
    }
}

/// Trigger that opened the surface's partial-expansion detail tier beneath the compact bar.
public enum SurfacePartialExpansionTrigger: String, Codable, Equatable, CaseIterable, Sendable {
    /// Opened by pointer hover over the surface cutout, wings, or island.
    case hover
    /// Opened automatically by an event presenting rich completion/info details (e.g. download complete, install complete).
    case eventPresentation
    /// Opened explicitly by a CLI command, keyboard action, or extension request.
    case programmatic
}

public enum SurfaceTransferPhase: String, Codable, Equatable, Sendable {
    case prompt
    case downloading
    case installing
    case restarting
    case trashPrompt
    case downloadCompleted
}

public struct SurfaceTransferState: Codable, Equatable, Sendable {
    public let phase: SurfaceTransferPhase
    public let progress: Double?
    public let hoverText: String
    public let actionId: String?
    public let downloads: [DownloadProgressSnapshot]?

    public init(
        phase: SurfaceTransferPhase,
        progress: Double? = nil,
        hoverText: String,
        actionId: String? = nil,
        downloads: [DownloadProgressSnapshot]? = nil
    ) {
        self.phase = phase
        self.progress = progress.map { min(1.0, max(0.0, $0)) }
        self.hoverText = hoverText
        self.actionId = actionId
        self.downloads = downloads
    }

    private enum CodingKeys: String, CodingKey {
        case phase
        case progress
        case hoverText
        case actionId
        case downloads
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.phase = try container.decode(SurfaceTransferPhase.self, forKey: .phase)
        let rawProgress = try container.decodeIfPresent(Double.self, forKey: .progress)
        self.progress = rawProgress.map { min(1.0, max(0.0, $0)) }
        self.hoverText = try container.decode(String.self, forKey: .hoverText)
        self.actionId = try container.decodeIfPresent(String.self, forKey: .actionId)
        self.downloads = try container.decodeIfPresent([DownloadProgressSnapshot].self, forKey: .downloads)
    }
}

public struct NotchWingsContent: Codable, Equatable, Sendable {
    public var isVisible: Bool
    public var leadingText: String?
    public var leadingIcon: String?
    public var trailingText: String?
    public var trailingIcon: String?
    public var hoverAnimationEnabled: Bool
    /// Growth level on hover: `0.0` = haptic only (no growth), `1.0` = Default (current), up to `4.0` (`+3`).
    public var hoverGrowthLevel: Double
    /// Enables tactile trackpad haptic pulses on notch hover, shelf toggle, and wing toggle.
    public var hapticFeedbackEnabled: Bool

    public init(
        isVisible: Bool = true,
        leadingText: String? = nil,
        leadingIcon: String? = nil,
        trailingText: String? = nil,
        trailingIcon: String? = nil,
        hoverAnimationEnabled: Bool = true,
        hoverGrowthLevel: Double = 1.0,
        hapticFeedbackEnabled: Bool = true
    ) {
        self.isVisible = isVisible
        self.leadingText = leadingText
        self.leadingIcon = leadingIcon
        self.trailingText = trailingText
        self.trailingIcon = trailingIcon
        self.hoverAnimationEnabled = hoverAnimationEnabled
        self.hoverGrowthLevel = min(4.0, max(0.0, hoverGrowthLevel))
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
        self.leadingText = try container.decodeIfPresent(String.self, forKey: .leadingText)
        self.leadingIcon = try container.decodeIfPresent(String.self, forKey: .leadingIcon)
        self.trailingText = try container.decodeIfPresent(String.self, forKey: .trailingText)
        self.trailingIcon = try container.decodeIfPresent(String.self, forKey: .trailingIcon)
        self.hoverAnimationEnabled = try container.decodeIfPresent(Bool.self, forKey: .hoverAnimationEnabled) ?? true
        self.hoverGrowthLevel = try container.decodeIfPresent(Double.self, forKey: .hoverGrowthLevel) ?? 1.0
        self.hapticFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticFeedbackEnabled) ?? true
    }
}

public enum ShelfEdge: String, Codable, Sendable {
    case bottom
    case top
    case left
    case right
}

public struct ShelfItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var subtitle: String?
    public var icon: String?
    public var badge: String?
    public var actionId: String?

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        badge: String? = nil,
        actionId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.actionId = actionId
    }
}

public struct ShelfContent: Codable, Equatable, Sendable {
    public var isOpen: Bool
    public var edge: ShelfEdge
    public var items: [ShelfItem]

    public init(
        isOpen: Bool = false,
        edge: ShelfEdge = .bottom,
        items: [ShelfItem] = []
    ) {
        self.isOpen = isOpen
        self.edge = edge
        self.items = items
    }
}

public struct RingItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var icon: String?
    public var shortcut: String?
    public var actionId: String?

    public init(
        id: String,
        title: String,
        icon: String? = nil,
        shortcut: String? = nil,
        actionId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.shortcut = shortcut
        self.actionId = actionId
    }
}

public struct RingContent: Codable, Equatable, Sendable {
    public var isOpen: Bool
    public var center: SurfacePoint?
    public var ringCount: Int
    public var leafWidth: Double
    public var showsCenterSelectorValue: Bool
    public var items: [RingItem]
    public var middleItems: [RingItem]?
    public var innerItems: [RingItem]?

    public init(
        isOpen: Bool = false,
        center: SurfacePoint? = nil,
        ringCount: Int = 1,
        leafWidth: Double = 104.0,
        showsCenterSelectorValue: Bool = true,
        items: [RingItem] = [],
        middleItems: [RingItem]? = nil,
        innerItems: [RingItem]? = nil
    ) {
        self.isOpen = isOpen
        self.center = center
        self.ringCount = min(3, max(1, ringCount))
        self.leafWidth = min(140.0, max(68.0, leafWidth))
        self.showsCenterSelectorValue = showsCenterSelectorValue
        self.items = items
        self.middleItems = middleItems
        self.innerItems = innerItems
    }
}

public enum SelectionActionKind: String, Codable, Equatable, Sendable {
    case action
    case group
}

public struct SelectionAction: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var icon: String?
    public var actionId: String?
    public var kind: SelectionActionKind
    public var children: [SelectionAction]?

    public var isGroup: Bool {
        kind == .group || !(children ?? []).isEmpty
    }

    public init(
        id: String,
        title: String,
        icon: String? = nil,
        actionId: String? = nil,
        kind: SelectionActionKind = .action,
        children: [SelectionAction]? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.actionId = actionId
        self.kind = (children?.isEmpty == false) ? .group : kind
        self.children = children?.map { $0.asLeafAction() }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case icon
        case actionId
        case kind
        case children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
        self.actionId = try container.decodeIfPresent(String.self, forKey: .actionId)
        let decodedChildren = try container.decodeIfPresent([SelectionAction].self, forKey: .children)
        let decodedKind = try container.decodeIfPresent(SelectionActionKind.self, forKey: .kind) ?? .action
        self.kind = (decodedChildren?.isEmpty == false) ? .group : decodedKind
        self.children = decodedChildren?.map { $0.asLeafAction() }
    }

    /// Returns a leaf-only copy, stripping any nested children to enforce max 1 level of group nesting.
    public func asLeafAction() -> SelectionAction {
        SelectionAction(
            id: id,
            title: title,
            icon: icon,
            actionId: actionId,
            kind: .action,
            children: nil
        )
    }

    /// Sanitizes an action list so action groups contain only leaf actions (max 1 level deep).
    public static func sanitizeGroupHierarchy(_ actions: [SelectionAction]) -> [SelectionAction] {
        actions.map { action in
            guard let children = action.children, !children.isEmpty else {
                return action
            }
            return SelectionAction(
                id: action.id,
                title: action.title,
                icon: action.icon,
                actionId: action.actionId,
                kind: .group,
                children: children.map { $0.asLeafAction() }
            )
        }
    }
}

public enum SelectionHUDNavigationLevel: Codable, Equatable, Sendable {
    case rootPill
    case subOptions(
        parentId: String,
        title: String,
        icon: String?,
        actions: [SelectionAction],
        allowsCustomPrompt: Bool
    )
    case resultCard(
        parentId: String,
        title: String,
        icon: String?,
        body: String,
        canCopy: Bool
    )
    case aiRewriteResult(
        parentId: String,
        title: String,
        originalText: String,
        rewrittenText: String
    )
}

public struct SelectionHUDContent: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var aiRewriteEnabled: Bool
    public var favoriteRewriteStyle: AIRewriteStyle
    public var isOpen: Bool
    public var selectedText: String?
    public var targetRect: SurfaceRect?
    public var isEditableTarget: Bool
    public var supportsRichText: Bool
    public var autoFocusFirstOption: Bool
    public var rimBlurEnabled: Bool
    public var actions: [SelectionAction]
    public var navigationStack: [SelectionHUDNavigationLevel]
    public var customPromptText: String
    public var isProcessingAI: Bool
    public var autoDetectEnabled: Bool
    public var disabledDetectorIds: [String]
    public var customTriggers: [SelectionMatchTrigger]
    public var primaryTooltip: PrimaryTooltipMatch?
    public var activeLifecyclePolicy: TooltipLifecyclePolicy

    public var currentLevel: SelectionHUDNavigationLevel {
        navigationStack.last ?? .rootPill
    }

    public var isAtRoot: Bool {
        navigationStack.isEmpty
    }

    public var stackDepth: Int {
        navigationStack.count
    }

    public init(
        isEnabled: Bool = true,
        aiRewriteEnabled: Bool = false,
        favoriteRewriteStyle: AIRewriteStyle = .rewrite,
        isOpen: Bool = false,
        selectedText: String? = nil,
        targetRect: SurfaceRect? = nil,
        isEditableTarget: Bool = false,
        supportsRichText: Bool = false,
        autoFocusFirstOption: Bool = false,
        rimBlurEnabled: Bool = true,
        actions: [SelectionAction] = [],
        navigationStack: [SelectionHUDNavigationLevel] = [],
        customPromptText: String = "",
        isProcessingAI: Bool = false,
        autoDetectEnabled: Bool = true,
        disabledDetectorIds: [String] = [],
        customTriggers: [SelectionMatchTrigger] = [],
        primaryTooltip: PrimaryTooltipMatch? = nil,
        activeLifecyclePolicy: TooltipLifecyclePolicy = .defaultSelection
    ) {
        self.isEnabled = isEnabled
        self.aiRewriteEnabled = aiRewriteEnabled
        self.favoriteRewriteStyle = favoriteRewriteStyle
        self.isOpen = isOpen
        self.selectedText = selectedText
        self.targetRect = targetRect
        self.isEditableTarget = isEditableTarget
        self.supportsRichText = supportsRichText
        self.autoFocusFirstOption = autoFocusFirstOption
        self.rimBlurEnabled = rimBlurEnabled
        self.actions = SelectionAction.sanitizeGroupHierarchy(actions)
        self.navigationStack = navigationStack
        self.customPromptText = customPromptText
        self.isProcessingAI = isProcessingAI
        self.autoDetectEnabled = autoDetectEnabled
        self.disabledDetectorIds = disabledDetectorIds
        self.customTriggers = customTriggers
        self.primaryTooltip = primaryTooltip
        self.activeLifecyclePolicy = activeLifecyclePolicy
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case aiRewriteEnabled
        case favoriteRewriteStyle
        case isOpen
        case selectedText
        case targetRect
        case isEditableTarget
        case supportsRichText
        case autoFocusFirstOption
        case rimBlurEnabled
        case actions
        case navigationStack
        case customPromptText
        case isProcessingAI
        case autoDetectEnabled
        case disabledDetectorIds
        case customTriggers
        case primaryTooltip
        case activeLifecyclePolicy
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        self.aiRewriteEnabled = try container.decodeIfPresent(Bool.self, forKey: .aiRewriteEnabled) ?? false
        self.favoriteRewriteStyle = try container.decodeIfPresent(AIRewriteStyle.self, forKey: .favoriteRewriteStyle) ?? .rewrite
        self.isOpen = try container.decodeIfPresent(Bool.self, forKey: .isOpen) ?? false
        self.selectedText = try container.decodeIfPresent(String.self, forKey: .selectedText)
        self.targetRect = try container.decodeIfPresent(SurfaceRect.self, forKey: .targetRect)
        self.isEditableTarget = try container.decodeIfPresent(Bool.self, forKey: .isEditableTarget) ?? false
        self.supportsRichText = try container.decodeIfPresent(Bool.self, forKey: .supportsRichText) ?? false
        self.autoFocusFirstOption = try container.decodeIfPresent(Bool.self, forKey: .autoFocusFirstOption) ?? false
        self.rimBlurEnabled = try container.decodeIfPresent(Bool.self, forKey: .rimBlurEnabled) ?? true
        let decodedActions = try container.decodeIfPresent([SelectionAction].self, forKey: .actions) ?? []
        self.actions = SelectionAction.sanitizeGroupHierarchy(decodedActions)
        self.navigationStack = try container.decodeIfPresent([SelectionHUDNavigationLevel].self, forKey: .navigationStack) ?? []
        self.customPromptText = try container.decodeIfPresent(String.self, forKey: .customPromptText) ?? ""
        self.isProcessingAI = try container.decodeIfPresent(Bool.self, forKey: .isProcessingAI) ?? false
        self.autoDetectEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoDetectEnabled) ?? true
        self.disabledDetectorIds = try container.decodeIfPresent([String].self, forKey: .disabledDetectorIds) ?? []
        self.customTriggers = try container.decodeIfPresent([SelectionMatchTrigger].self, forKey: .customTriggers) ?? []
        self.primaryTooltip = try container.decodeIfPresent(PrimaryTooltipMatch.self, forKey: .primaryTooltip)
        self.activeLifecyclePolicy = try container.decodeIfPresent(TooltipLifecyclePolicy.self, forKey: .activeLifecyclePolicy) ?? .defaultSelection
    }
}

public enum ArchipelagoSurfaceStyle: String, Codable, CaseIterable, Sendable {
    case island
    case notch
    case pill

    public var title: String {
        switch self {
        case .island: return "Dynamic Island"
        case .notch: return "Notch"
        case .pill: return "Pill (Punch Hole)"
        }
    }

    public var subtitle: String {
        switch self {
        case .island: return "Floating island capsule centered on the display."
        case .notch: return "Bezel notch with interactive wings and physical hugger."
        case .pill: return "Floating punch hole cutout with bilateral wings and customizable dimensions."
        }
    }
}

public enum SurfaceDisplayTargetMode: String, Codable, CaseIterable, Sendable {
    case followPointer
    case allDisplays
    case mainDisplayOnly

    public var title: String {
        switch self {
        case .followPointer: return "Follow Pointer"
        case .allDisplays: return "All Displays"
        case .mainDisplayOnly: return "Main Display"
        }
    }

    public var subtitle: String {
        switch self {
        case .followPointer: return "Surface moves dynamically to whichever display contains the pointer."
        case .allDisplays: return "Renders resting surfaces on every connected display. Clicking a surface activates it while others stay at rest."
        case .mainDisplayOnly: return "Renders surface strictly on the primary display."
        }
    }
}

public enum WingGlassFinish: String, Codable, CaseIterable, Sendable {
    case horizontalGradient
    case verticalGradient
    case solidBlack

    public var title: String {
        switch self {
        case .horizontalGradient: return "Horizontal"
        case .verticalGradient: return "Vertical"
        case .solidBlack: return "Solid Black"
        }
    }

    public var subtitle: String {
        switch self {
        case .horizontalGradient: return "Smooth horizontal gradient blending from outer glass into dead zone black."
        case .verticalGradient: return "Vertical glass gradient starting below the top display edge."
        case .solidBlack: return "Solid matte black finish across the wings and dead zone."
        }
    }
}

public struct PillCutoutContent: Codable, Equatable, Sendable {
    public var topOffset: Double
    public var deadZoneWidth: Double
    public var deadZoneHeight: Double

    public init(
        topOffset: Double = 12.0,
        deadZoneWidth: Double = 80.0,
        deadZoneHeight: Double = 32.0
    ) {
        self.topOffset = topOffset
        self.deadZoneWidth = deadZoneWidth
        self.deadZoneHeight = deadZoneHeight
    }
}

public enum DockPreviewSize: String, Codable, CaseIterable, Sendable {
    case small
    case medium
    case large

    public var title: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    public var subtitle: String {
        switch self {
        case .small: return "Compact preview card (50% smaller than medium)."
        case .medium: return "Balanced default window preview card."
        case .large: return "Expanded high-detail preview card (50% larger than medium)."
        }
    }

    public var scaleFactor: Double {
        switch self {
        case .small: return 0.5
        case .medium: return 1.0
        case .large: return 1.5
        }
    }

    /// Returns the effective preview size after stepping down one level for every 6 windows
    /// above the first 6 (clamped at `.small`), without mutating the user's configured default.
    public func effectiveSize(forWindowCount windowCount: Int) -> DockPreviewSize {
        guard windowCount > 6 else { return self }
        let stepsDown = (windowCount - 1) / 6
        let ordered: [DockPreviewSize] = [.large, .medium, .small]
        guard let startIndex = ordered.firstIndex(of: self) else { return .small }
        let targetIndex = min(ordered.count - 1, startIndex + stepsDown)
        return ordered[targetIndex]
    }

    /// Scales the visible window budget proportionally when the card size steps down, so the
    /// popover retains its footprint and fits more windows on screen without extra scrolling.
    public static func effectiveMaxVisibleWindows(
        configuredSize: DockPreviewSize,
        configuredMaxVisible: Int,
        windowCount: Int
    ) -> Int {
        let baseMax = max(1, configuredMaxVisible)
        let effective = configuredSize.effectiveSize(forWindowCount: windowCount)
        guard effective != configuredSize else { return baseMax }
        let ratio = configuredSize.scaleFactor / effective.scaleFactor
        return max(baseMax, Int((Double(baseMax) * ratio).rounded(.down)))
    }

    /// Computes vertical-grid column and row limits that scale proportionally with `effectiveSize`.
    public static func effectiveGridLimits(
        configuredSize: DockPreviewSize,
        configuredMaxVisible: Int,
        windowCount: Int
    ) -> (maxColumns: Int, maxVisibleRows: Int) {
        let baseMax = max(1, configuredMaxVisible)
        let effective = configuredSize.effectiveSize(forWindowCount: windowCount)
        let ratio = configuredSize.scaleFactor / effective.scaleFactor
        let baseCols = max(1, min(3, baseMax))
        let baseRows = max(1, Int(ceil(Double(baseMax) / Double(baseCols))))
        let maxCols = max(baseCols, Int((Double(baseCols) * ratio).rounded(.down)))
        let maxRows = max(baseRows, Int((Double(baseRows) * ratio).rounded(.down)))
        return (maxCols, maxRows)
    }
}

public enum DockPreviewScrollDirection: String, Codable, CaseIterable, Sendable {
    case horizontal
    case vertical

    public var title: String {
        switch self {
        case .horizontal: return "Horizontal Scroll"
        case .vertical: return "Vertical Grid"
        }
    }

    public var subtitle: String {
        switch self {
        case .horizontal: return "Displays windows in a single horizontal scrolling strip."
        case .vertical: return "Arranges windows in a multi-column vertical scrolling grid."
        }
    }
}

public struct DockPreviewContent: Codable, Equatable, Sendable {
    public static let hoverDelayRange = 0...1000
    public static let dismissDelayRange = 0...1000
    public static let animationDurationRange = 0...500
    public static let defaultHoverDelayMilliseconds = 120
    public static let defaultDismissDelayMilliseconds = 80
    public static let defaultAnimationDurationMilliseconds = 280

    public var isEnabled: Bool
    public var previewSize: DockPreviewSize
    public var maxVisibleWindows: Int
    public var scrollDirection: DockPreviewScrollDirection
    public var titleMarqueeEnabled: Bool
    public var hoverDelayMilliseconds: Int
    public var dismissDelayMilliseconds: Int
    public var animationDurationMilliseconds: Int
    public var isPresented: Bool
    public var activeAppName: String?
    public var activeBundleIdentifier: String?
    public var windowCount: Int
    public var isLabelHovered: Bool
    public var boundWidgetId: String?
    public var activeContentMode: DockPreviewContentMode
    public var activeDynamicTintHex: String?

    public init(
        isEnabled: Bool = true,
        previewSize: DockPreviewSize = .medium,
        maxVisibleWindows: Int = 4,
        scrollDirection: DockPreviewScrollDirection = .horizontal,
        titleMarqueeEnabled: Bool = false,
        hoverDelayMilliseconds: Int = Self.defaultHoverDelayMilliseconds,
        dismissDelayMilliseconds: Int = Self.defaultDismissDelayMilliseconds,
        animationDurationMilliseconds: Int = Self.defaultAnimationDurationMilliseconds,
        isPresented: Bool = false,
        activeAppName: String? = nil,
        activeBundleIdentifier: String? = nil,
        windowCount: Int = 0,
        isLabelHovered: Bool = false,
        boundWidgetId: String? = nil,
        activeContentMode: DockPreviewContentMode = .windows,
        activeDynamicTintHex: String? = nil
    ) {
        self.isEnabled = isEnabled
        self.previewSize = previewSize
        self.maxVisibleWindows = min(6, max(1, maxVisibleWindows))
        self.scrollDirection = scrollDirection
        self.titleMarqueeEnabled = titleMarqueeEnabled
        self.hoverDelayMilliseconds = min(Self.hoverDelayRange.upperBound, max(Self.hoverDelayRange.lowerBound, hoverDelayMilliseconds))
        self.dismissDelayMilliseconds = min(Self.dismissDelayRange.upperBound, max(Self.dismissDelayRange.lowerBound, dismissDelayMilliseconds))
        self.animationDurationMilliseconds = min(Self.animationDurationRange.upperBound, max(Self.animationDurationRange.lowerBound, animationDurationMilliseconds))
        self.isPresented = isPresented
        self.activeAppName = activeAppName
        self.activeBundleIdentifier = activeBundleIdentifier
        self.windowCount = max(0, windowCount)
        self.isLabelHovered = isLabelHovered
        self.boundWidgetId = boundWidgetId
        self.activeContentMode = activeContentMode
        self.activeDynamicTintHex = activeDynamicTintHex
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled, previewSize, maxVisibleWindows, scrollDirection, titleMarqueeEnabled
        case hoverDelayMilliseconds, dismissDelayMilliseconds, animationDurationMilliseconds
        case isPresented, activeAppName, activeBundleIdentifier, windowCount, isLabelHovered
        case boundWidgetId, activeContentMode, activeDynamicTintHex
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            isEnabled: try values.decode(Bool.self, forKey: .isEnabled),
            previewSize: try values.decode(DockPreviewSize.self, forKey: .previewSize),
            maxVisibleWindows: try values.decode(Int.self, forKey: .maxVisibleWindows),
            scrollDirection: try values.decode(DockPreviewScrollDirection.self, forKey: .scrollDirection),
            titleMarqueeEnabled: try values.decode(Bool.self, forKey: .titleMarqueeEnabled),
            hoverDelayMilliseconds: try values.decodeIfPresent(Int.self, forKey: .hoverDelayMilliseconds)
                ?? Self.defaultHoverDelayMilliseconds,
            dismissDelayMilliseconds: try values.decodeIfPresent(Int.self, forKey: .dismissDelayMilliseconds)
                ?? Self.defaultDismissDelayMilliseconds,
            animationDurationMilliseconds: try values.decodeIfPresent(Int.self, forKey: .animationDurationMilliseconds)
                ?? Self.defaultAnimationDurationMilliseconds,
            isPresented: try values.decode(Bool.self, forKey: .isPresented),
            activeAppName: try values.decodeIfPresent(String.self, forKey: .activeAppName),
            activeBundleIdentifier: try values.decodeIfPresent(String.self, forKey: .activeBundleIdentifier),
            windowCount: try values.decode(Int.self, forKey: .windowCount),
            isLabelHovered: try values.decode(Bool.self, forKey: .isLabelHovered),
            boundWidgetId: try values.decodeIfPresent(String.self, forKey: .boundWidgetId),
            activeContentMode: try values.decodeIfPresent(DockPreviewContentMode.self, forKey: .activeContentMode) ?? .windows,
            activeDynamicTintHex: try values.decodeIfPresent(String.self, forKey: .activeDynamicTintHex)
        )
    }
}

public enum DockPosition: String, Codable, CaseIterable, Sendable {
    case bottom
    case left
    case right

    public var title: String {
        switch self {
        case .bottom: return "Bottom"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

public enum DockAnimationDelay: String, Codable, CaseIterable, Sendable {
    case none
    case little
    case `default`
    case aLot

    public var delaySeconds: Double {
        switch self {
        case .none: return 0.0
        case .little: return 0.15
        case .default: return 0.5
        case .aLot: return 1.0
        }
    }

    public static func from(seconds: Double) -> DockAnimationDelay {
        if seconds <= 0.05 { return .none }
        if seconds <= 0.25 { return .little }
        if seconds <= 0.75 { return .default }
        return .aLot
    }
}

public enum DockAnimationSpeed: String, Codable, CaseIterable, Sendable {
    case instant
    case fast
    case `default`
    case slow

    public var speedModifier: Double {
        switch self {
        case .instant: return 0.0
        case .fast: return 0.15
        case .default: return 0.5
        case .slow: return 1.0
        }
    }

    public static func from(modifier: Double) -> DockAnimationSpeed {
        if modifier <= 0.05 { return .instant }
        if modifier <= 0.25 { return .fast }
        if modifier <= 0.75 { return .default }
        return .slow
    }
}

public struct DockPreferences: Codable, Equatable, Sendable {
    public var autohide: Bool
    public var position: DockPosition
    public var animationDelay: DockAnimationDelay
    public var animationSpeed: DockAnimationSpeed

    public init(
        autohide: Bool = true,
        position: DockPosition = .bottom,
        animationDelay: DockAnimationDelay = .none,
        animationSpeed: DockAnimationSpeed = .instant
    ) {
        self.autohide = autohide
        self.position = position
        self.animationDelay = animationDelay
        self.animationSpeed = animationSpeed
    }
}

public struct MenuBarContent: Codable, Equatable, Sendable {
    public var isAdaptiveEnabled: Bool
    public var isVerticalFlipEnabled: Bool
    public var isTransparencyAllowed: Bool
    public var opacity: Double
    public var isWingsEnabled: Bool
    public var wingOverlap: Double
    public var topEdgeTolerance: Double
    public var seamBleed: Double
    public var isScreenCornersRounded: Bool
    public var screenCornerRadius: Double
    public var isColorCalibrationEnabled: Bool
    public var teamsMaterial: String

    public init(
        isAdaptiveEnabled: Bool = true,
        isVerticalFlipEnabled: Bool = false,
        isTransparencyAllowed: Bool = false,
        opacity: Double = 1.0,
        isWingsEnabled: Bool = true,
        wingOverlap: Double = 3.5,
        topEdgeTolerance: Double = 6.0,
        seamBleed: Double = 2.0,
        isScreenCornersRounded: Bool = false,
        screenCornerRadius: Double = 16.0,
        isColorCalibrationEnabled: Bool = true,
        teamsMaterial: String = "underWindowBackground"
    ) {
        self.isAdaptiveEnabled = isAdaptiveEnabled
        self.isVerticalFlipEnabled = isVerticalFlipEnabled
        self.isTransparencyAllowed = isTransparencyAllowed
        self.opacity = max(0.0, min(1.0, opacity))
        self.isWingsEnabled = isWingsEnabled
        self.wingOverlap = max(-1.5, min(8.5, wingOverlap))
        self.topEdgeTolerance = max(1.0, min(20.0, topEdgeTolerance))
        self.seamBleed = max(0.0, min(5.0, seamBleed))
        self.isScreenCornersRounded = isScreenCornersRounded
        self.screenCornerRadius = max(6.0, min(32.0, screenCornerRadius))
        self.isColorCalibrationEnabled = isColorCalibrationEnabled
        self.teamsMaterial = teamsMaterial.isEmpty ? "underWindowBackground" : teamsMaterial
    }

    private enum CodingKeys: String, CodingKey {
        case isAdaptiveEnabled
        case isVerticalFlipEnabled
        case isTransparencyAllowed
        case opacity
        case isWingsEnabled
        case wingOverlap
        case topEdgeTolerance
        case seamBleed
        case isScreenCornersRounded
        case screenCornerRadius
        case isColorCalibrationEnabled
        case teamsMaterial
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isAdaptiveEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAdaptiveEnabled) ?? true
        self.isVerticalFlipEnabled = try container.decodeIfPresent(Bool.self, forKey: .isVerticalFlipEnabled) ?? false
        self.isTransparencyAllowed = try container.decodeIfPresent(Bool.self, forKey: .isTransparencyAllowed) ?? false
        let rawOpacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        self.opacity = max(0.0, min(1.0, rawOpacity))
        self.isWingsEnabled = try container.decodeIfPresent(Bool.self, forKey: .isWingsEnabled) ?? true
        let rawWingOverlap = try container.decodeIfPresent(Double.self, forKey: .wingOverlap) ?? 3.5
        self.wingOverlap = max(-1.5, min(8.5, rawWingOverlap))
        let rawTolerance = try container.decodeIfPresent(Double.self, forKey: .topEdgeTolerance) ?? 6.0
        self.topEdgeTolerance = max(1.0, min(20.0, rawTolerance))
        let rawBleed = try container.decodeIfPresent(Double.self, forKey: .seamBleed) ?? 2.0
        self.seamBleed = max(0.0, min(5.0, rawBleed))
        self.isScreenCornersRounded = try container.decodeIfPresent(Bool.self, forKey: .isScreenCornersRounded) ?? false
        let rawRadius = try container.decodeIfPresent(Double.self, forKey: .screenCornerRadius) ?? 16.0
        self.screenCornerRadius = max(6.0, min(32.0, rawRadius))
        self.isColorCalibrationEnabled = try container.decodeIfPresent(Bool.self, forKey: .isColorCalibrationEnabled) ?? true
        self.teamsMaterial = try container.decodeIfPresent(String.self, forKey: .teamsMaterial) ?? "underWindowBackground"
    }
}

public enum ArchipelagoFrostMode: String, Codable, CaseIterable, Sendable {
    case systemDefault
    case custom

    public var title: String {
        switch self {
        case .systemDefault: return "System Default"
        case .custom: return "Custom"
        }
    }
}

public enum ArchipelagoLiquidGlassTintMode: String, Codable, CaseIterable, Sendable {
    case systemDefault
    case custom

    public var title: String {
        switch self {
        case .systemDefault: return "Default"
        case .custom: return "Custom"
        }
    }
}

public enum ArchipelagoGlassColorTintPreset: String, Codable, CaseIterable, Sendable {
    case none
    case accent
    case indigo
    case blue
    case cyan
    case emerald
    case amber
    case rose
    case violet
    case custom

    public var title: String {
        switch self {
        case .none: return "None"
        case .accent: return "Accent"
        case .indigo: return "Indigo"
        case .blue: return "Blue"
        case .cyan: return "Cyan"
        case .emerald: return "Emerald"
        case .amber: return "Amber"
        case .rose: return "Rose"
        case .violet: return "Violet"
        case .custom: return "Custom"
        }
    }

    public var presetHex: String? {
        switch self {
        case .none, .accent, .custom: return nil
        case .indigo: return "#5856D6"
        case .blue: return "#0A84FF"
        case .cyan: return "#32ADE6"
        case .emerald: return "#30D158"
        case .amber: return "#FF9F0A"
        case .rose: return "#FF375F"
        case .violet: return "#BF5AF2"
        }
    }
}

public struct UniversalSurfaceSnapshot: Codable, Equatable, Sendable {
    public var theme: ArchipelagoTheme
    public var globalGlassProfile: SurfaceGlassProfile
    public var surfaceThemeOverrides: [String: ArchipelagoTheme]
    public var surfaceGlassProfiles: [String: SurfaceGlassProfile]
    public var dockWidgetGlassOverrides: [String: SurfaceGlassProfile]
    public var frostMode: ArchipelagoFrostMode
    public var frostLevel: Double
    public var dynamicGlassLevel: Double
    public var dynamicGlassTintDepth: Double
    public var glassColorTintPreset: ArchipelagoGlassColorTintPreset
    public var glassColorTintHex: String
    public var liquidGlassWallpaperBleed: Bool
    public var liquidGlassTintMode: ArchipelagoLiquidGlassTintMode
    public var liquidGlassCustomTintAmount: Double
    public var liquidGlassActiveTintEnabled: Bool
    public var liquidGlassAtRestTintAmount: Double
    public var hideWhenInactive: Bool
    public var inactiveDismissDelay: Double
    public var appIconLocation: ArchipelagoAppIconLocation
    public var surfaceStyle: ArchipelagoSurfaceStyle
    public var displayTargetMode: SurfaceDisplayTargetMode
    public var wingGlassFinish: WingGlassFinish
    public var notchWings: NotchWingsContent
    public var pillCutout: PillCutoutContent
    public var dockPreview: DockPreviewContent
    public var dockPreferences: DockPreferences
    public var menuBar: MenuBarContent
    public var shelf: ShelfContent
    public var ring: RingContent
    public var selectionHUD: SelectionHUDContent
    public var revision: UInt64

    public init(
        theme: ArchipelagoTheme = .dynamicGlass,
        globalGlassProfile: SurfaceGlassProfile? = nil,
        surfaceThemeOverrides: [String: ArchipelagoTheme] = [:],
        surfaceGlassProfiles: [String: SurfaceGlassProfile] = [:],
        dockWidgetGlassOverrides: [String: SurfaceGlassProfile] = [:],
        frostMode: ArchipelagoFrostMode = .systemDefault,
        frostLevel: Double = 0.0,
        dynamicGlassLevel: Double = 0.5,
        dynamicGlassTintDepth: Double = 0.22,
        glassColorTintPreset: ArchipelagoGlassColorTintPreset = .none,
        glassColorTintHex: String = "",
        liquidGlassWallpaperBleed: Bool = true,
        liquidGlassTintMode: ArchipelagoLiquidGlassTintMode = .systemDefault,
        liquidGlassCustomTintAmount: Double = 0.65,
        liquidGlassActiveTintEnabled: Bool = false,
        liquidGlassAtRestTintAmount: Double = 0.40,
        hideWhenInactive: Bool = false,
        inactiveDismissDelay: Double = 1.0,
        appIconLocation: ArchipelagoAppIconLocation = .menuBar,
        surfaceStyle: ArchipelagoSurfaceStyle = .island,
        displayTargetMode: SurfaceDisplayTargetMode = .followPointer,
        wingGlassFinish: WingGlassFinish = .horizontalGradient,
        notchWings: NotchWingsContent = NotchWingsContent(isVisible: false),
        pillCutout: PillCutoutContent = PillCutoutContent(),
        dockPreview: DockPreviewContent = DockPreviewContent(),
        dockPreferences: DockPreferences = DockPreferences(),
        menuBar: MenuBarContent = MenuBarContent(),
        shelf: ShelfContent = ShelfContent(),
        ring: RingContent = RingContent(),
        selectionHUD: SelectionHUDContent = SelectionHUDContent(),
        revision: UInt64 = 0
    ) {
        let clampedFrost = min(1.0, max(0.0, frostLevel))
        let clampedDynamicLevel = min(1.0, max(0.0, dynamicGlassLevel))
        let clampedDynamicTint = min(1.0, max(0.0, dynamicGlassTintDepth))
        let clampedCustomTint = min(1.0, max(0.0, liquidGlassCustomTintAmount))
        let clampedAtRestTint = min(1.0, max(0.0, liquidGlassAtRestTintAmount))

        self.theme = globalGlassProfile?.theme ?? theme
        self.globalGlassProfile = globalGlassProfile ?? SurfaceGlassProfile(
            theme: theme,
            frostMode: frostMode,
            frostLevel: clampedFrost,
            dynamicGlassLevel: clampedDynamicLevel,
            dynamicGlassTintDepth: clampedDynamicTint,
            glassColorTintPreset: glassColorTintPreset,
            glassColorTintHex: glassColorTintHex,
            liquidGlassWallpaperBleed: liquidGlassWallpaperBleed,
            liquidGlassTintMode: liquidGlassTintMode,
            liquidGlassCustomTintAmount: clampedCustomTint,
            liquidGlassActiveTintEnabled: liquidGlassActiveTintEnabled,
            liquidGlassAtRestTintAmount: clampedAtRestTint
        )
        self.surfaceThemeOverrides = surfaceThemeOverrides
        self.surfaceGlassProfiles = surfaceGlassProfiles
        self.dockWidgetGlassOverrides = dockWidgetGlassOverrides
        self.frostMode = self.globalGlassProfile.frostMode
        self.frostLevel = self.globalGlassProfile.frostLevel
        self.dynamicGlassLevel = self.globalGlassProfile.dynamicGlassLevel
        self.dynamicGlassTintDepth = self.globalGlassProfile.dynamicGlassTintDepth
        self.glassColorTintPreset = self.globalGlassProfile.glassColorTintPreset
        self.glassColorTintHex = self.globalGlassProfile.glassColorTintHex
        self.liquidGlassWallpaperBleed = self.globalGlassProfile.liquidGlassWallpaperBleed
        self.liquidGlassTintMode = self.globalGlassProfile.liquidGlassTintMode
        self.liquidGlassCustomTintAmount = self.globalGlassProfile.liquidGlassCustomTintAmount
        self.liquidGlassActiveTintEnabled = self.globalGlassProfile.liquidGlassActiveTintEnabled
        self.liquidGlassAtRestTintAmount = self.globalGlassProfile.liquidGlassAtRestTintAmount
        self.hideWhenInactive = hideWhenInactive
        self.inactiveDismissDelay = min(5.0, max(0.1, inactiveDismissDelay))
        self.appIconLocation = appIconLocation
        self.surfaceStyle = surfaceStyle
        self.displayTargetMode = displayTargetMode
        self.wingGlassFinish = wingGlassFinish
        self.notchWings = notchWings
        self.pillCutout = pillCutout
        self.dockPreview = dockPreview
        self.dockPreferences = dockPreferences
        self.menuBar = menuBar
        self.shelf = shelf
        self.ring = ring
        self.selectionHUD = selectionHUD
        self.revision = revision
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTheme = try container.decodeIfPresent(ArchipelagoTheme.self, forKey: .theme) ?? .dynamicGlass
        self.surfaceThemeOverrides = try container.decodeIfPresent([String: ArchipelagoTheme].self, forKey: .surfaceThemeOverrides) ?? [:]
        self.surfaceGlassProfiles = try container.decodeIfPresent([String: SurfaceGlassProfile].self, forKey: .surfaceGlassProfiles) ?? [:]
        self.dockWidgetGlassOverrides = try container.decodeIfPresent([String: SurfaceGlassProfile].self, forKey: .dockWidgetGlassOverrides) ?? [:]
        let decodedFrostMode = try container.decodeIfPresent(ArchipelagoFrostMode.self, forKey: .frostMode) ?? .systemDefault
        let decodedFrostLevel = try container.decodeIfPresent(Double.self, forKey: .frostLevel) ?? 0.0
        let decodedDynamicGlassLevel = try container.decodeIfPresent(Double.self, forKey: .dynamicGlassLevel) ?? 0.5
        let decodedDynamicGlassTintDepth = try container.decodeIfPresent(Double.self, forKey: .dynamicGlassTintDepth) ?? 0.22
        let decodedGlassColorTintPreset = try container.decodeIfPresent(ArchipelagoGlassColorTintPreset.self, forKey: .glassColorTintPreset) ?? .none
        let decodedGlassColorTintHex = try container.decodeIfPresent(String.self, forKey: .glassColorTintHex) ?? ""
        let decodedLiquidGlassWallpaperBleed = try container.decodeIfPresent(Bool.self, forKey: .liquidGlassWallpaperBleed) ?? true
        let decodedLiquidGlassTintMode = try container.decodeIfPresent(ArchipelagoLiquidGlassTintMode.self, forKey: .liquidGlassTintMode) ?? .systemDefault
        let decodedLiquidGlassCustomTintAmount = try container.decodeIfPresent(Double.self, forKey: .liquidGlassCustomTintAmount) ?? 0.65
        let decodedLiquidGlassActiveTintEnabled = try container.decodeIfPresent(Bool.self, forKey: .liquidGlassActiveTintEnabled) ?? false
        let decodedLiquidGlassAtRestTintAmount = try container.decodeIfPresent(Double.self, forKey: .liquidGlassAtRestTintAmount) ?? 0.40

        let resolvedGlobal = try container.decodeIfPresent(SurfaceGlassProfile.self, forKey: .globalGlassProfile) ?? SurfaceGlassProfile(
            theme: decodedTheme,
            frostMode: decodedFrostMode,
            frostLevel: decodedFrostLevel,
            dynamicGlassLevel: decodedDynamicGlassLevel,
            dynamicGlassTintDepth: decodedDynamicGlassTintDepth,
            glassColorTintPreset: decodedGlassColorTintPreset,
            glassColorTintHex: decodedGlassColorTintHex,
            liquidGlassWallpaperBleed: decodedLiquidGlassWallpaperBleed,
            liquidGlassTintMode: decodedLiquidGlassTintMode,
            liquidGlassCustomTintAmount: decodedLiquidGlassCustomTintAmount,
            liquidGlassActiveTintEnabled: decodedLiquidGlassActiveTintEnabled,
            liquidGlassAtRestTintAmount: decodedLiquidGlassAtRestTintAmount
        )
        self.globalGlassProfile = resolvedGlobal
        self.theme = decodedTheme
        self.frostMode = decodedFrostMode
        self.frostLevel = decodedFrostLevel
        self.dynamicGlassLevel = decodedDynamicGlassLevel
        self.dynamicGlassTintDepth = decodedDynamicGlassTintDepth
        self.glassColorTintPreset = decodedGlassColorTintPreset
        self.glassColorTintHex = decodedGlassColorTintHex
        self.liquidGlassWallpaperBleed = decodedLiquidGlassWallpaperBleed
        self.liquidGlassTintMode = decodedLiquidGlassTintMode
        self.liquidGlassCustomTintAmount = decodedLiquidGlassCustomTintAmount
        self.liquidGlassActiveTintEnabled = decodedLiquidGlassActiveTintEnabled
        self.liquidGlassAtRestTintAmount = decodedLiquidGlassAtRestTintAmount
        self.hideWhenInactive = try container.decodeIfPresent(Bool.self, forKey: .hideWhenInactive) ?? false
        self.inactiveDismissDelay = try container.decodeIfPresent(Double.self, forKey: .inactiveDismissDelay) ?? 1.0
        self.appIconLocation = try container.decodeIfPresent(ArchipelagoAppIconLocation.self, forKey: .appIconLocation) ?? .menuBar
        self.surfaceStyle = try container.decodeIfPresent(ArchipelagoSurfaceStyle.self, forKey: .surfaceStyle) ?? .island
        self.displayTargetMode = try container.decodeIfPresent(SurfaceDisplayTargetMode.self, forKey: .displayTargetMode) ?? .followPointer
        self.wingGlassFinish = try container.decodeIfPresent(WingGlassFinish.self, forKey: .wingGlassFinish) ?? .horizontalGradient
        self.notchWings = try container.decodeIfPresent(NotchWingsContent.self, forKey: .notchWings) ?? NotchWingsContent(isVisible: false)
        self.pillCutout = try container.decodeIfPresent(PillCutoutContent.self, forKey: .pillCutout) ?? PillCutoutContent()
        self.dockPreview = try container.decodeIfPresent(DockPreviewContent.self, forKey: .dockPreview) ?? DockPreviewContent()
        self.dockPreferences = try container.decodeIfPresent(DockPreferences.self, forKey: .dockPreferences) ?? DockPreferences()
        self.menuBar = try container.decodeIfPresent(MenuBarContent.self, forKey: .menuBar) ?? MenuBarContent()
        self.shelf = try container.decodeIfPresent(ShelfContent.self, forKey: .shelf) ?? ShelfContent()
        self.ring = try container.decodeIfPresent(RingContent.self, forKey: .ring) ?? RingContent()
        self.selectionHUD = try container.decodeIfPresent(SelectionHUDContent.self, forKey: .selectionHUD) ?? SelectionHUDContent()
        self.revision = try container.decodeIfPresent(UInt64.self, forKey: .revision) ?? 0
    }

    /// Returns the explicit override for `target`, or `nil` when following the baseline theme.
    public func themeOverride(for target: ArchipelagoSurfaceThemeTarget) -> ArchipelagoTheme? {
        surfaceGlassProfiles[target.rawValue]?.theme ?? surfaceThemeOverrides[target.rawValue]
    }

    /// Resolves the effective Theme + Dynamic & Liquid Glass profile for `target` (or a specific
    /// Dock Widget when `widgetId` is provided, inheriting the global `.dockWidget` profile when unset).
    public func effectiveGlassProfile(
        for target: ArchipelagoSurfaceThemeTarget,
        widgetId: String? = nil,
        surfaceStyle: ArchipelagoSurfaceStyle? = nil,
        hasPhysicalNotch: Bool = false
    ) -> SurfaceGlassProfile {
        let resolvedStyle = surfaceStyle ?? self.surfaceStyle
        if target == .dockWidget, let widgetId, !widgetId.isEmpty,
           let widgetProfile = dockWidgetGlassOverrides[widgetId] {
            return widgetProfile
        }
        if let profile = surfaceGlassProfiles[target.rawValue] {
            return profile.enforcingNotchRestriction(
                target: target,
                surfaceStyle: resolvedStyle,
                hasPhysicalNotch: hasPhysicalNotch
            )
        }
        var baseline = globalGlassProfile
        if let legacyThemeOverride = surfaceThemeOverrides[target.rawValue] {
            baseline.theme = legacyThemeOverride
        }
        return baseline.enforcingNotchRestriction(
            target: target,
            surfaceStyle: resolvedStyle,
            hasPhysicalNotch: hasPhysicalNotch
        )
    }

    /// Resolves the effective theme for `target`, checking per-surface / per-widget glass profiles first
    /// and enforcing the physical-notch restriction on `.primary`.
    public func effectiveTheme(
        for target: ArchipelagoSurfaceThemeTarget,
        widgetId: String? = nil,
        surfaceStyle: ArchipelagoSurfaceStyle? = nil,
        hasPhysicalNotch: Bool = false
    ) -> ArchipelagoTheme {
        effectiveGlassProfile(
            for: target,
            widgetId: widgetId,
            surfaceStyle: surfaceStyle,
            hasPhysicalNotch: hasPhysicalNotch
        ).theme
    }
}
