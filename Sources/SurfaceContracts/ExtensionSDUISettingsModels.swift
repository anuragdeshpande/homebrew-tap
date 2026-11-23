import Foundation

/// Semantic tone used across settings cards, callouts, badges, and rating scales.
public enum ExtensionSDUITone: String, Codable, Equatable, Sendable {
    case neutral
    case accent
    case success
    case warning
    case destructive
}

/// Control sizing hint mapped onto native macOS control sizes.
public enum ExtensionSDUIControlSize: String, Codable, Equatable, Sendable {
    case mini
    case small
    case regular
    case large
}

/// Horizontal divider presentation style inside SDUI settings sections and popovers.
public enum ExtensionSDUIDividerStyle: String, Codable, Equatable, Sendable {
    case fullWidth = "full_width"
    case centeredPartial = "centered_partial"

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "centered_partial", "centeredPartial":
            self = .centeredPartial
        default:
            self = .fullWidth
        }
    }
}

/// Picker presentation style supported by `.picker` SDUI nodes.
public enum ExtensionSDUIPickerStyle: String, Codable, Equatable, Sendable {
    case menu
    case radio
    case inline
}

/// AI provider domain scope for declarative host-bound `aiProviderPicker` slots.
public enum ExtensionSDUIProviderScope: String, Codable, Equatable, Sendable {
    case chat
    case speech

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = raw == "speech" ? .speech : .chat
    }
}

/// Declarative permission descriptor used inside `.extensionHeader`.
public struct ExtensionSDUIPermissionItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String { kind }
    public let kind: String
    public let reason: String?

    enum CodingKeys: String, CodingKey {
        case kind
        case reason
    }

    public init(kind: String, reason: String? = nil) {
        self.kind = kind
        self.reason = reason
    }
}

/// Option descriptor for `.segmentedControl`, including optional hover `"i"` popover card content.
public struct ExtensionSDUISegmentedOption: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let subtitle: String?
    public let badge: String?
    public let icon: String?
    public let tone: ExtensionSDUITone?
    public let popoverTitle: String?
    public let popoverBody: String?
    public let popoverFooter: String?
    public let popoverNodes: [ExtensionSDUINode]?

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case title
        case subtitle
        case badge
        case icon
        case tone
        case popoverTitle = "popover_title"
        case popoverBody = "popover_body"
        case popoverFooter = "popover_footer"
        case popoverNodes = "popover_nodes"
    }

    public init(
        id: String,
        label: String,
        subtitle: String? = nil,
        badge: String? = nil,
        icon: String? = nil,
        tone: ExtensionSDUITone? = nil,
        popoverTitle: String? = nil,
        popoverBody: String? = nil,
        popoverFooter: String? = nil,
        popoverNodes: [ExtensionSDUINode]? = nil
    ) {
        self.id = id
        self.label = label
        self.subtitle = subtitle
        self.badge = badge
        self.icon = icon
        self.tone = tone
        self.popoverTitle = popoverTitle
        self.popoverBody = popoverBody
        self.popoverFooter = popoverFooter
        self.popoverNodes = popoverNodes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        if let label = try container.decodeIfPresent(String.self, forKey: .label) {
            self.label = label
        } else {
            self.label = try container.decodeIfPresent(String.self, forKey: .title) ?? id
        }
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.badge = try container.decodeIfPresent(String.self, forKey: .badge)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
        self.tone = try container.decodeIfPresent(ExtensionSDUITone.self, forKey: .tone)
        self.popoverTitle = try container.decodeIfPresent(String.self, forKey: .popoverTitle)
        self.popoverBody = try container.decodeIfPresent(String.self, forKey: .popoverBody)
        self.popoverFooter = try container.decodeIfPresent(String.self, forKey: .popoverFooter)
        self.popoverNodes = try container.decodeIfPresent([ExtensionSDUINode].self, forKey: .popoverNodes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(badge, forKey: .badge)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(tone, forKey: .tone)
        try container.encodeIfPresent(popoverTitle, forKey: .popoverTitle)
        try container.encodeIfPresent(popoverBody, forKey: .popoverBody)
        try container.encodeIfPresent(popoverFooter, forKey: .popoverFooter)
        try container.encodeIfPresent(popoverNodes, forKey: .popoverNodes)
    }
}

/// Selectable chip metadata used by `.chipSelector`.
public struct ExtensionSDUIChipOption: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let icon: String?

    public init(id: String, label: String, icon: String? = nil) {
        self.id = id
        self.label = label
        self.icon = icon
    }
}

/// Serializable keyboard shortcut state for `.shortcutRecorder`.
public struct ExtensionSDUIShortcutValue: Codable, Equatable, Sendable {
    public let keyCode: UInt16
    public let modifiersRawValue: UInt
    public let displayString: String
    public let isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case keyCode = "key_code"
        case camelKeyCode = "keyCode"
        case modifiersRawValue = "modifiers_raw_value"
        case camelModifiersRawValue = "modifiersRawValue"
        case displayString = "display_string"
        case camelDisplayString = "displayString"
        case isEnabled = "is_enabled"
        case camelIsEnabled = "isEnabled"
    }

    public init(
        keyCode: UInt16,
        modifiersRawValue: UInt,
        displayString: String,
        isEnabled: Bool = true
    ) {
        self.keyCode = keyCode
        self.modifiersRawValue = modifiersRawValue
        self.displayString = displayString
        self.isEnabled = isEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let code = try container.decodeIfPresent(UInt16.self, forKey: .keyCode) {
            self.keyCode = code
        } else {
            self.keyCode = try container.decodeIfPresent(UInt16.self, forKey: .camelKeyCode) ?? 0
        }
        if let mods = try container.decodeIfPresent(UInt.self, forKey: .modifiersRawValue) {
            self.modifiersRawValue = mods
        } else {
            self.modifiersRawValue = try container.decodeIfPresent(UInt.self, forKey: .camelModifiersRawValue) ?? 0
        }
        if let display = try container.decodeIfPresent(String.self, forKey: .displayString) {
            self.displayString = display
        } else {
            self.displayString = try container.decodeIfPresent(String.self, forKey: .camelDisplayString) ?? ""
        }
        if let enabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) {
            self.isEnabled = enabled
        } else {
            self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .camelIsEnabled) ?? true
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifiersRawValue, forKey: .modifiersRawValue)
        try container.encode(displayString, forKey: .displayString)
        try container.encode(isEnabled, forKey: .isEnabled)
    }
}

/// Button item descriptor used inside `.buttonGroup`.
public struct ExtensionSDUIButtonItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String?
    public let icon: String?
    public let actionId: String
    public let style: ExtensionSDUIButtonStyle
    public let isDisabled: Bool
    public let tooltip: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case icon
        case actionId = "action_id"
        case style
        case isDisabled = "is_disabled"
        case tooltip
    }

    public init(
        id: String,
        title: String? = nil,
        icon: String? = nil,
        actionId: String,
        style: ExtensionSDUIButtonStyle = .default,
        isDisabled: Bool = false,
        tooltip: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.actionId = actionId
        self.style = style
        self.isDisabled = isDisabled
        self.tooltip = tooltip
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
        self.actionId = try container.decodeIfPresent(String.self, forKey: .actionId) ?? self.id
        self.style = try container.decodeIfPresent(ExtensionSDUIButtonStyle.self, forKey: .style) ?? .default
        self.isDisabled = try container.decodeIfPresent(Bool.self, forKey: .isDisabled) ?? false
        self.tooltip = try container.decodeIfPresent(String.self, forKey: .tooltip)
    }
}
