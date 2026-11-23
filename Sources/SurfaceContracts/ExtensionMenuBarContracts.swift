import Foundation

/// A single declarative menu bar item published by an out-of-process extension.
public struct ExtensionMenuBarItem: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let icon: String?
    public let actionId: String?
    public let isChecked: Bool
    public let isDisabled: Bool
    public let isSeparator: Bool
    public let children: [ExtensionMenuBarItem]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case icon
        case actionId = "action_id"
        case actionIdCamel = "actionId"
        case isChecked = "is_checked"
        case isCheckedCamel = "isChecked"
        case isDisabled = "is_disabled"
        case isDisabledCamel = "isDisabled"
        case isSeparator = "is_separator"
        case isSeparatorCamel = "isSeparator"
        case children
    }

    public init(
        id: String,
        title: String = "",
        icon: String? = nil,
        actionId: String? = nil,
        isChecked: Bool = false,
        isDisabled: Bool = false,
        isSeparator: Bool = false,
        children: [ExtensionMenuBarItem] = []
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.actionId = actionId
        self.isChecked = isChecked
        self.isDisabled = isDisabled
        self.isSeparator = isSeparator
        self.children = children
    }

    public static func separator(id: String = UUID().uuidString) -> ExtensionMenuBarItem {
        ExtensionMenuBarItem(id: id, title: "", isSeparator: true)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        actionId = try c.decodeIfPresent(String.self, forKey: .actionId)
            ?? c.decodeIfPresent(String.self, forKey: .actionIdCamel)
        isChecked = try c.decodeIfPresent(Bool.self, forKey: .isChecked)
            ?? c.decodeIfPresent(Bool.self, forKey: .isCheckedCamel)
            ?? false
        isDisabled = try c.decodeIfPresent(Bool.self, forKey: .isDisabled)
            ?? c.decodeIfPresent(Bool.self, forKey: .isDisabledCamel)
            ?? false
        isSeparator = try c.decodeIfPresent(Bool.self, forKey: .isSeparator)
            ?? c.decodeIfPresent(Bool.self, forKey: .isSeparatorCamel)
            ?? false
        children = try c.decodeIfPresent([ExtensionMenuBarItem].self, forKey: .children) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(icon, forKey: .icon)
        try c.encodeIfPresent(actionId, forKey: .actionId)
        try c.encode(isChecked, forKey: .isChecked)
        try c.encode(isDisabled, forKey: .isDisabled)
        try c.encode(isSeparator, forKey: .isSeparator)
        if !children.isEmpty {
            try c.encode(children, forKey: .children)
        }
    }
}

/// Top-level submenu specification published by an extension via `set_menu_bar_items`.
public struct ExtensionMenuBarSpec: Codable, Equatable, Sendable {
    public let title: String
    public let icon: String?
    public let items: [ExtensionMenuBarItem]

    public init(
        title: String,
        icon: String? = nil,
        items: [ExtensionMenuBarItem]
    ) {
        self.title = title
        self.icon = icon
        self.items = items
    }
}
