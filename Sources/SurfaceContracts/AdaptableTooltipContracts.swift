import Foundation

/// Semantic tint treatment for adaptable tooltip actions and primary-hero items.
public enum SurfaceActionTint: Codable, Equatable, Sendable {
    case none
    case accent
    case success
    case info
    case warning
    case error
    case customHex(String)
}

/// Visual emphasis for an action button inside an expanded tooltip card.
public enum TooltipActionButtonStyle: String, Codable, Equatable, Sendable {
    case primary
    case secondary
}

/// Inline text formatting span for `ExpandedTooltipContent` without UI-framework coupling.
public struct TooltipTextSpan: Codable, Equatable, Sendable {
    public var text: String
    public var isBold: Bool
    public var isItalic: Bool
    public var isMonospace: Bool
    public var tint: SurfaceActionTint

    public init(
        text: String,
        isBold: Bool = false,
        isItalic: Bool = false,
        isMonospace: Bool = false,
        tint: SurfaceActionTint = .none
    ) {
        self.text = text
        self.isBold = isBold
        self.isItalic = isItalic
        self.isMonospace = isMonospace
        self.tint = tint
    }
}

/// Platform-neutral action descriptor shared across Selection HUD, Radial Ring, Dock Widgets, and IPC extensions.
public struct SurfaceActionDescriptor: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var icon: String?
    public var actionId: String?
    public var kind: SelectionActionKind
    public var children: [SurfaceActionDescriptor]?
    public var tint: SurfaceActionTint
    public var ringCompatible: Bool
    public var isExpanding: Bool
    public var sourceExtensionId: String?

    public var isGroup: Bool {
        kind == .group || !(children ?? []).isEmpty
    }

    public init(
        id: String,
        title: String,
        icon: String? = nil,
        actionId: String? = nil,
        kind: SelectionActionKind = .action,
        children: [SurfaceActionDescriptor]? = nil,
        tint: SurfaceActionTint = .none,
        ringCompatible: Bool = true,
        isExpanding: Bool = false,
        sourceExtensionId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.actionId = actionId
        self.kind = (children?.isEmpty == false) ? .group : kind
        self.children = children?.map { $0.asLeafDescriptor() }
        self.tint = tint
        self.ringCompatible = ringCompatible
        self.isExpanding = isExpanding
        self.sourceExtensionId = sourceExtensionId
    }

    public func asLeafDescriptor() -> SurfaceActionDescriptor {
        SurfaceActionDescriptor(
            id: id,
            title: title,
            icon: icon,
            actionId: actionId,
            kind: .action,
            children: nil,
            tint: tint,
            ringCompatible: ringCompatible,
            isExpanding: isExpanding,
            sourceExtensionId: sourceExtensionId
        )
    }

    /// Projects this descriptor into a `SelectionAction` for the Selection HUD.
    public func toSelectionAction() -> SelectionAction {
        SelectionAction(
            id: id,
            title: title,
            icon: icon,
            actionId: actionId ?? id,
            kind: kind,
            children: children?.map { $0.toSelectionAction() }
        )
    }

    /// Projects this descriptor into a `RingItem` for the Radial Ring when `ringCompatible` is true.
    public func toRingItem(shortcut: String? = nil) -> RingItem {
        RingItem(
            id: id,
            title: title,
            icon: icon,
            shortcut: shortcut,
            actionId: actionId ?? id
        )
    }

    /// Creates a canonical descriptor from an existing `SelectionAction`.
    public static func from(
        _ action: SelectionAction,
        ringCompatible: Bool = true,
        isExpanding: Bool = false,
        sourceExtensionId: String? = nil
    ) -> SurfaceActionDescriptor {
        SurfaceActionDescriptor(
            id: action.id,
            title: action.title,
            icon: action.icon,
            actionId: action.actionId ?? action.id,
            kind: action.kind,
            children: action.children?.map {
                SurfaceActionDescriptor.from(
                    $0,
                    ringCompatible: ringCompatible,
                    isExpanding: false,
                    sourceExtensionId: sourceExtensionId
                )
            },
            tint: .none,
            ringCompatible: ringCompatible,
            isExpanding: isExpanding || action.isGroup,
            sourceExtensionId: sourceExtensionId
        )
    }
}

/// Input context provided to `PrimaryTooltipProviding` evaluators.
public struct SelectionMatchContext: Codable, Equatable, Sendable {
    public var selectedText: String
    public var targetRect: SurfaceRect?
    public var isEditableTarget: Bool
    public var supportsRichText: Bool
    public var sourceAppBundleId: String?

    public init(
        selectedText: String,
        targetRect: SurfaceRect? = nil,
        isEditableTarget: Bool = false,
        supportsRichText: Bool = false,
        sourceAppBundleId: String? = nil
    ) {
        self.selectedText = selectedText
        self.targetRect = targetRect
        self.isEditableTarget = isEditableTarget
        self.supportsRichText = supportsRichText
        self.sourceAppBundleId = sourceAppBundleId
    }
}

/// Input context provided to `SelectionActionProviding.execute` and `ExpandingSelectionActionProviding.expand`.
public struct SelectionActionContext: Codable, Equatable, Sendable {
    public var selectedText: String
    public var targetRect: SurfaceRect?
    public var isEditableTarget: Bool
    public var supportsRichText: Bool
    public var actionId: String
    public var parameters: [String: String]

    public init(
        selectedText: String,
        targetRect: SurfaceRect? = nil,
        isEditableTarget: Bool = false,
        supportsRichText: Bool = false,
        actionId: String,
        parameters: [String: String] = [:]
    ) {
        self.selectedText = selectedText
        self.targetRect = targetRect
        self.isEditableTarget = isEditableTarget
        self.supportsRichText = supportsRichText
        self.actionId = actionId
        self.parameters = parameters
    }
}

/// Display mode for a matched primary hero item in the adaptable tooltip.
public enum PrimaryTooltipMode: Codable, Equatable, Sendable {
    case inlineValue(displayText: String, copyValue: String?)
    case expandingAction(actionId: String, badgeText: String?)
}

/// Compile-time-enforced result returned by `PrimaryTooltipProviding`.
/// Returning a non-nil instance guarantees all required rendering fields are present.
public struct PrimaryTooltipMatch: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let icon: String
    public let tint: SurfaceActionTint
    public let priority: Int
    public let mode: PrimaryTooltipMode
    public let descriptor: SurfaceActionDescriptor

    public init(
        id: String,
        title: String,
        icon: String,
        tint: SurfaceActionTint = .accent,
        priority: Int = 100,
        mode: PrimaryTooltipMode,
        descriptor: SurfaceActionDescriptor
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.tint = tint
        self.priority = priority
        self.mode = mode
        self.descriptor = descriptor
    }
}

/// Action button displayed inside an expanded tooltip card.
public struct ExpandedTooltipActionButton: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var icon: String?
    public var actionId: String
    public var style: TooltipActionButtonStyle
    public var replacementText: String?
    public var copyText: String?

    public init(
        id: String,
        title: String,
        icon: String? = nil,
        actionId: String,
        style: TooltipActionButtonStyle = .secondary,
        replacementText: String? = nil,
        copyText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.actionId = actionId
        self.style = style
        self.replacementText = replacementText
        self.copyText = copyText
    }
}

/// Formatted content returned by `ExpandingSelectionActionProviding.expand`.
public struct ExpandedTooltipContent: Codable, Equatable, Sendable {
    public var parentId: String
    public var title: String
    public var icon: String?
    public var body: String
    public var formattedSpans: [TooltipTextSpan]
    public var actions: [ExpandedTooltipActionButton]
    public var canCopy: Bool

    public init(
        parentId: String,
        title: String,
        icon: String? = nil,
        body: String,
        formattedSpans: [TooltipTextSpan] = [],
        actions: [ExpandedTooltipActionButton] = [],
        canCopy: Bool = true
    ) {
        self.parentId = parentId
        self.title = title
        self.icon = icon
        self.body = body
        self.formattedSpans = formattedSpans
        self.actions = actions
        self.canCopy = canCopy
    }
}

/// Standardized outcome returned by `SelectionActionProviding.execute`.
/// The core surface executes UI side effects (pasteboard, replacement, morphing, dismissal) consistently.
public enum SelectionActionOutcome: Codable, Equatable, Sendable {
    case none
    case dismiss
    case copyToPasteboard(String)
    case replaceSelection(String)
    case expand(ExpandedTooltipContent)
    case subOptions(
        title: String,
        icon: String?,
        actions: [SurfaceActionDescriptor],
        allowsCustomPrompt: Bool
    )
}

/// Placement direction for an expanded popover anchored to a Radial Ring slot.
public enum RingPopoverAnchorDirection: String, Codable, Equatable, Sendable {
    case above
    case below
    case leading
    case trailing
}

/// Resolved frame and tail direction for an expanded Ring popover.
public struct RingPopoverPlacement: Codable, Equatable, Sendable {
    public var direction: RingPopoverAnchorDirection
    public var anchorPoint: SurfacePoint
    public var popoverOrigin: SurfacePoint
    public var popoverSize: SurfaceSize

    public init(
        direction: RingPopoverAnchorDirection,
        anchorPoint: SurfacePoint,
        popoverOrigin: SurfacePoint,
        popoverSize: SurfaceSize
    ) {
        self.direction = direction
        self.anchorPoint = anchorPoint
        self.popoverOrigin = popoverOrigin
        self.popoverSize = popoverSize
    }
}

/// Cross-language JSON IPC request envelope for out-of-process tooltip extensions (QuickJS, Raycast, Windows).
public enum TooltipExtensionIPCRequest: Codable, Equatable, Sendable {
    case registerDescriptors(extensionId: String, descriptors: [SurfaceActionDescriptor])
    case evaluatePrimaryTooltip(extensionId: String, context: SelectionMatchContext)
    case executeAction(extensionId: String, context: SelectionActionContext)
    case expandAction(extensionId: String, context: SelectionActionContext)
}

/// Cross-language JSON IPC response envelope for out-of-process tooltip extensions.
public enum TooltipExtensionIPCResponse: Codable, Equatable, Sendable {
    case registered(count: Int)
    case primaryMatch(PrimaryTooltipMatch?)
    case outcome(SelectionActionOutcome)
    case expanded(ExpandedTooltipContent)
    case error(String)
}

/// Core-managed events that can automatically dismiss an active Adaptable Tooltip session.
public enum TooltipDismissalTrigger: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case outsideClick
    case escapeKey
    case selectionChanged
    case typingStopped
    case focusLost
    case spaceCommitted
}

/// Declarative lifecycle policy returned by tooltip providers so the core system
/// automatically manages dismissal and resets the tooltip surface for the next action.
public struct TooltipLifecyclePolicy: Codable, Equatable, Sendable {
    public var dismissalTriggers: Set<TooltipDismissalTrigger>
    public var typingIdleTimeoutSeconds: Double?
    public var isTransientSession: Bool

    public init(
        dismissalTriggers: Set<TooltipDismissalTrigger> = [.outsideClick, .escapeKey, .selectionChanged],
        typingIdleTimeoutSeconds: Double? = nil,
        isTransientSession: Bool = false
    ) {
        self.dismissalTriggers = dismissalTriggers
        self.typingIdleTimeoutSeconds = typingIdleTimeoutSeconds
        self.isTransientSession = isTransientSession
    }

    public func shouldDismiss(on trigger: TooltipDismissalTrigger) -> Bool {
        dismissalTriggers.contains(trigger)
    }

    /// Standard policy for persistent selection popovers (dismissed on outside click, Escape, or new selection).
    public static let defaultSelection = TooltipLifecyclePolicy(
        dismissalTriggers: [.outsideClick, .escapeKey, .selectionChanged],
        typingIdleTimeoutSeconds: nil,
        isTransientSession: false
    )

    /// Transient policy for active-typing suggestions (dismissed when typing stops, Escape, outside click,
    /// focus loss, space commit, or selection change; clears custom actions on dismiss).
    public static func activeTyping(idleTimeoutSeconds: Double = 1.5) -> TooltipLifecyclePolicy {
        TooltipLifecyclePolicy(
            dismissalTriggers: [
                .outsideClick,
                .escapeKey,
                .selectionChanged,
                .typingStopped,
                .focusLost,
                .spaceCommitted
            ],
            typingIdleTimeoutSeconds: idleTimeoutSeconds,
            isTransientSession: true
        )
    }
}
