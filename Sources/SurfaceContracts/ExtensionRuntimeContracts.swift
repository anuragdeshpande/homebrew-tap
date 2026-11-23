import Foundation

/// Host-mediated input/focus subscription categories that extensions can opt into.
public enum ExtensionHostEventKind: String, Codable, Hashable, CaseIterable, Sendable {
    case modifierFlags = "modifier_flags"
    case focusedTextInput = "focused_text_input"
    case keyShortcut = "key_shortcut"

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "modifier_flags", "modifierFlags":
            self = .modifierFlags
        case "focused_text_input", "focusedTextInput":
            self = .focusedTextInput
        case "key_shortcut", "keyShortcut":
            self = .keyShortcut
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown host event kind: \(raw)")
            )
        }
    }
}

/// Global keyboard shortcut registered with `HostInputAndFocusBridge` by an extension.
public struct ExtensionRegisteredShortcut: Codable, Equatable, Sendable {
    public let actionId: String
    public let keyCode: UInt16
    public let modifiersRawValue: UInt

    enum CodingKeys: String, CodingKey {
        case actionId = "action_id"
        case camelActionId = "actionId"
        case keyCode = "key_code"
        case camelKeyCode = "keyCode"
        case modifiersRawValue = "modifiers_raw_value"
        case camelModifiersRawValue = "modifiersRawValue"
    }

    public init(actionId: String, keyCode: UInt16, modifiersRawValue: UInt) {
        self.actionId = actionId
        self.keyCode = keyCode
        self.modifiersRawValue = modifiersRawValue
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.actionId = try c.decodeIfPresent(String.self, forKey: .actionId)
            ?? c.decode(String.self, forKey: .camelActionId)
        self.keyCode = try c.decodeIfPresent(UInt16.self, forKey: .keyCode)
            ?? c.decodeIfPresent(UInt16.self, forKey: .camelKeyCode)
            ?? 0
        self.modifiersRawValue = try c.decodeIfPresent(UInt.self, forKey: .modifiersRawValue)
            ?? c.decodeIfPresent(UInt.self, forKey: .camelModifiersRawValue)
            ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(actionId, forKey: .actionId)
        try c.encode(keyCode, forKey: .keyCode)
        try c.encode(modifiersRawValue, forKey: .modifiersRawValue)
    }
}

/// Visual stroke/fill style for screen-space text annotations.
public enum ExtensionTextAnnotationStyle: String, Codable, Equatable, Sendable {
    case squiggle
    case underline
    case highlight

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ExtensionTextAnnotationStyle(rawValue: raw) ?? .squiggle
    }
}

/// Generic screen-space annotation rendered over focused text ranges with optional hover fix action.
public struct ExtensionTextAnnotation: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let rangeLocation: Int?
    public let rangeLength: Int?
    public var rect: SurfaceRect?
    public let style: ExtensionTextAnnotationStyle
    public let color: String
    public let tooltipTitle: String?
    public let tooltipBody: String?
    public let actionTitle: String?
    public let actionId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case rangeLocation = "range_location"
        case camelRangeLocation = "rangeLocation"
        case rangeLength = "range_length"
        case camelRangeLength = "rangeLength"
        case rect
        case style
        case color
        case tooltipTitle = "tooltip_title"
        case camelTooltipTitle = "tooltipTitle"
        case tooltipBody = "tooltip_body"
        case camelTooltipBody = "tooltipBody"
        case actionTitle = "action_title"
        case camelActionTitle = "actionTitle"
        case actionId = "action_id"
        case camelActionId = "actionId"
    }

    public init(
        id: String,
        rangeLocation: Int? = nil,
        rangeLength: Int? = nil,
        rect: SurfaceRect? = nil,
        style: ExtensionTextAnnotationStyle = .squiggle,
        color: String = "#FF3B30",
        tooltipTitle: String? = nil,
        tooltipBody: String? = nil,
        actionTitle: String? = nil,
        actionId: String? = nil
    ) {
        self.id = id
        self.rangeLocation = rangeLocation
        self.rangeLength = rangeLength
        self.rect = rect
        self.style = style
        self.color = color
        self.tooltipTitle = tooltipTitle
        self.tooltipBody = tooltipBody
        self.actionTitle = actionTitle
        self.actionId = actionId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.rangeLocation = try c.decodeIfPresent(Int.self, forKey: .rangeLocation)
            ?? c.decodeIfPresent(Int.self, forKey: .camelRangeLocation)
        self.rangeLength = try c.decodeIfPresent(Int.self, forKey: .rangeLength)
            ?? c.decodeIfPresent(Int.self, forKey: .camelRangeLength)
        self.rect = try c.decodeIfPresent(SurfaceRect.self, forKey: .rect)
        self.style = try c.decodeIfPresent(ExtensionTextAnnotationStyle.self, forKey: .style) ?? .squiggle
        self.color = try c.decodeIfPresent(String.self, forKey: .color) ?? "#FF3B30"
        self.tooltipTitle = try c.decodeIfPresent(String.self, forKey: .tooltipTitle)
            ?? c.decodeIfPresent(String.self, forKey: .camelTooltipTitle)
        self.tooltipBody = try c.decodeIfPresent(String.self, forKey: .tooltipBody)
            ?? c.decodeIfPresent(String.self, forKey: .camelTooltipBody)
        self.actionTitle = try c.decodeIfPresent(String.self, forKey: .actionTitle)
            ?? c.decodeIfPresent(String.self, forKey: .camelActionTitle)
        self.actionId = try c.decodeIfPresent(String.self, forKey: .actionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelActionId)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(rangeLocation, forKey: .rangeLocation)
        try c.encodeIfPresent(rangeLength, forKey: .rangeLength)
        try c.encodeIfPresent(rect, forKey: .rect)
        try c.encode(style, forKey: .style)
        try c.encode(color, forKey: .color)
        try c.encodeIfPresent(tooltipTitle, forKey: .tooltipTitle)
        try c.encodeIfPresent(tooltipBody, forKey: .tooltipBody)
        try c.encodeIfPresent(actionTitle, forKey: .actionTitle)
        try c.encodeIfPresent(actionId, forKey: .actionId)
    }
}

/// Relative anchor placement for floating `set_anchored_pill` overlays.
public enum ExtensionAnchoredPillPlacement: String, Codable, Equatable, Sendable {
    case topRight = "top_right"
    case topCenter = "top_center"
    case aboveCaret = "above_caret"
    case bottomRight = "bottom_right"

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "top_right", "topRight":
            self = .topRight
        case "top_center", "topCenter":
            self = .topCenter
        case "above_caret", "aboveCaret":
            self = .aboveCaret
        case "bottom_right", "bottomRight":
            self = .bottomRight
        default:
            self = .topRight
        }
    }
}

/// Generic native audio-capture waveform pill specification driven by `HostAudioCaptureBridge.shared`.
public struct ExtensionAudioPillState: Codable, Equatable, Sendable {
    public enum Phase: String, Codable, Equatable, Sendable {
        case recording
        case transcribing
        case loading
        case readyCountdown = "ready_countdown"
        case paused

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            switch raw {
            case "recording": self = .recording
            case "transcribing": self = .transcribing
            case "loading": self = .loading
            case "ready_countdown", "readyCountdown": self = .readyCountdown
            case "paused": self = .paused
            default: self = .recording
            }
        }
    }

    public let phase: Phase
    public let isPersistent: Bool
    public let statusLabel: String?
    public let startedAtEpoch: Double?
    public let pausedElapsedSeconds: Int?
    public let accentColor: String
    public let processingColor: String
    public let caretRect: SurfaceRect?
    public let pauseActionId: String?
    public let cancelActionId: String?
    public let doneActionId: String?

    enum CodingKeys: String, CodingKey {
        case phase
        case isPersistent = "is_persistent"
        case camelIsPersistent = "isPersistent"
        case statusLabel = "status_label"
        case camelStatusLabel = "statusLabel"
        case startedAtEpoch = "started_at_epoch"
        case camelStartedAtEpoch = "startedAtEpoch"
        case pausedElapsedSeconds = "paused_elapsed_seconds"
        case camelPausedElapsedSeconds = "pausedElapsedSeconds"
        case accentColor = "accent_color"
        case camelAccentColor = "accentColor"
        case processingColor = "processing_color"
        case camelProcessingColor = "processingColor"
        case caretRect = "caret_rect"
        case camelCaretRect = "caretRect"
        case pauseActionId = "pause_action_id"
        case camelPauseActionId = "pauseActionId"
        case cancelActionId = "cancel_action_id"
        case camelCancelActionId = "cancelActionId"
        case doneActionId = "done_action_id"
        case camelDoneActionId = "doneActionId"
    }

    public init(
        phase: Phase,
        isPersistent: Bool = false,
        statusLabel: String? = nil,
        startedAtEpoch: Double? = nil,
        pausedElapsedSeconds: Int? = nil,
        accentColor: String = "#34C759",
        processingColor: String = "#0A84FF",
        caretRect: SurfaceRect? = nil,
        pauseActionId: String? = nil,
        cancelActionId: String? = nil,
        doneActionId: String? = nil
    ) {
        self.phase = phase
        self.isPersistent = isPersistent
        self.statusLabel = statusLabel
        self.startedAtEpoch = startedAtEpoch
        self.pausedElapsedSeconds = pausedElapsedSeconds
        self.accentColor = accentColor
        self.processingColor = processingColor
        self.caretRect = caretRect
        self.pauseActionId = pauseActionId
        self.cancelActionId = cancelActionId
        self.doneActionId = doneActionId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.phase = try c.decodeIfPresent(Phase.self, forKey: .phase) ?? .recording
        self.isPersistent = try c.decodeIfPresent(Bool.self, forKey: .isPersistent)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelIsPersistent)
            ?? false
        self.statusLabel = try c.decodeIfPresent(String.self, forKey: .statusLabel)
            ?? c.decodeIfPresent(String.self, forKey: .camelStatusLabel)
        self.startedAtEpoch = try c.decodeIfPresent(Double.self, forKey: .startedAtEpoch)
            ?? c.decodeIfPresent(Double.self, forKey: .camelStartedAtEpoch)
        self.pausedElapsedSeconds = try c.decodeIfPresent(Int.self, forKey: .pausedElapsedSeconds)
            ?? c.decodeIfPresent(Int.self, forKey: .camelPausedElapsedSeconds)
        self.accentColor = try c.decodeIfPresent(String.self, forKey: .accentColor)
            ?? c.decodeIfPresent(String.self, forKey: .camelAccentColor)
            ?? "#34C759"
        self.processingColor = try c.decodeIfPresent(String.self, forKey: .processingColor)
            ?? c.decodeIfPresent(String.self, forKey: .camelProcessingColor)
            ?? "#0A84FF"
        self.caretRect = try c.decodeIfPresent(SurfaceRect.self, forKey: .caretRect)
            ?? c.decodeIfPresent(SurfaceRect.self, forKey: .camelCaretRect)
        self.pauseActionId = try c.decodeIfPresent(String.self, forKey: .pauseActionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelPauseActionId)
        self.cancelActionId = try c.decodeIfPresent(String.self, forKey: .cancelActionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelCancelActionId)
        self.doneActionId = try c.decodeIfPresent(String.self, forKey: .doneActionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelDoneActionId)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(phase, forKey: .phase)
        try c.encode(isPersistent, forKey: .isPersistent)
        try c.encodeIfPresent(statusLabel, forKey: .statusLabel)
        try c.encodeIfPresent(startedAtEpoch, forKey: .startedAtEpoch)
        try c.encodeIfPresent(pausedElapsedSeconds, forKey: .pausedElapsedSeconds)
        try c.encode(accentColor, forKey: .accentColor)
        try c.encode(processingColor, forKey: .processingColor)
        try c.encodeIfPresent(caretRect, forKey: .caretRect)
        try c.encodeIfPresent(pauseActionId, forKey: .pauseActionId)
        try c.encodeIfPresent(cancelActionId, forKey: .cancelActionId)
        try c.encodeIfPresent(doneActionId, forKey: .doneActionId)
    }
}

/// Generic anchored floating Liquid Glass pill + optional hover popover rendered from SDUI nodes.
public struct ExtensionAnchoredPillSpec: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let anchorRect: SurfaceRect
    public let placement: ExtensionAnchoredPillPlacement
    public let compactNode: ExtensionSDUINode
    public let popoverNode: ExtensionSDUINode?
    public let openPopoverOnHover: Bool
    public let leadingDotColor: String?
    public let audioPill: ExtensionAudioPillState?

    enum CodingKeys: String, CodingKey {
        case id
        case anchorRect = "anchor_rect"
        case camelAnchorRect = "anchorRect"
        case placement
        case compactNode = "compact_node"
        case camelCompactNode = "compactNode"
        case popoverNode = "popover_node"
        case camelPopoverNode = "popoverNode"
        case openPopoverOnHover = "open_popover_on_hover"
        case camelOpenPopoverOnHover = "openPopoverOnHover"
        case leadingDotColor = "leading_dot_color"
        case camelLeadingDotColor = "leadingDotColor"
        case audioPill = "audio_pill"
        case camelAudioPill = "audioPill"
    }

    public init(
        id: String,
        anchorRect: SurfaceRect,
        placement: ExtensionAnchoredPillPlacement = .topRight,
        compactNode: ExtensionSDUINode = .container(id: "empty", axis: .horizontal, alignment: .center, spacing: 0, children: []),
        popoverNode: ExtensionSDUINode? = nil,
        openPopoverOnHover: Bool = true,
        leadingDotColor: String? = nil,
        audioPill: ExtensionAudioPillState? = nil
    ) {
        self.id = id
        self.anchorRect = anchorRect
        self.placement = placement
        self.compactNode = compactNode
        self.popoverNode = popoverNode
        self.openPopoverOnHover = openPopoverOnHover
        self.leadingDotColor = leadingDotColor
        self.audioPill = audioPill
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedId = try c.decode(String.self, forKey: .id)
        self.id = decodedId
        if let rect = try c.decodeIfPresent(SurfaceRect.self, forKey: .anchorRect) {
            self.anchorRect = rect
        } else {
            self.anchorRect = try c.decode(SurfaceRect.self, forKey: .camelAnchorRect)
        }
        self.placement = try c.decodeIfPresent(ExtensionAnchoredPillPlacement.self, forKey: .placement) ?? .topRight
        if let compact = try c.decodeIfPresent(ExtensionSDUINode.self, forKey: .compactNode) {
            self.compactNode = compact
        } else if let compactCamel = try c.decodeIfPresent(ExtensionSDUINode.self, forKey: .camelCompactNode) {
            self.compactNode = compactCamel
        } else {
            self.compactNode = .container(id: "\(decodedId)_empty", axis: .horizontal, alignment: .center, spacing: 0, children: [])
        }
        self.popoverNode = try c.decodeIfPresent(ExtensionSDUINode.self, forKey: .popoverNode)
            ?? c.decodeIfPresent(ExtensionSDUINode.self, forKey: .camelPopoverNode)
        self.openPopoverOnHover = try c.decodeIfPresent(Bool.self, forKey: .openPopoverOnHover)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelOpenPopoverOnHover)
            ?? true
        self.leadingDotColor = try c.decodeIfPresent(String.self, forKey: .leadingDotColor)
            ?? c.decodeIfPresent(String.self, forKey: .camelLeadingDotColor)
        self.audioPill = try c.decodeIfPresent(ExtensionAudioPillState.self, forKey: .audioPill)
            ?? c.decodeIfPresent(ExtensionAudioPillState.self, forKey: .camelAudioPill)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(anchorRect, forKey: .anchorRect)
        try c.encode(placement, forKey: .placement)
        try c.encode(compactNode, forKey: .compactNode)
        try c.encodeIfPresent(popoverNode, forKey: .popoverNode)
        try c.encode(openPopoverOnHover, forKey: .openPopoverOnHover)
        try c.encodeIfPresent(leadingDotColor, forKey: .leadingDotColor)
        try c.encodeIfPresent(audioPill, forKey: .audioPill)
    }
}

/// Action chip displayed in the shared Selection HUD near the typing caret (`show_caret_actions`).
public struct ExtensionCaretActionItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let icon: String?
    public let actionId: String
    public let isHighlighted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case icon
        case actionId = "action_id"
        case camelActionId = "actionId"
        case isHighlighted = "is_highlighted"
        case camelIsHighlighted = "isHighlighted"
    }

    public init(
        id: String,
        title: String,
        icon: String? = nil,
        actionId: String,
        isHighlighted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.actionId = actionId
        self.isHighlighted = isHighlighted
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.title = try c.decode(String.self, forKey: .title)
        self.icon = try c.decodeIfPresent(String.self, forKey: .icon)
        self.actionId = try c.decodeIfPresent(String.self, forKey: .actionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelActionId)
            ?? self.id
        self.isHighlighted = try c.decodeIfPresent(Bool.self, forKey: .isHighlighted)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelIsHighlighted)
            ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(icon, forKey: .icon)
        try c.encode(actionId, forKey: .actionId)
        if isHighlighted {
            try c.encode(isHighlighted, forKey: .isHighlighted)
        }
    }
}
