import Foundation

/// Trigger matching mode for user-defined Selection HUD custom triggers (#90).
public enum SelectionMatchTriggerMode: String, Codable, CaseIterable, Sendable {
    case regex
    case contains
    case prefix
    case suffix
    case validatorScript
}

/// User-defined auto-detect trigger attached to a custom Selection HUD option.
public struct SelectionMatchTrigger: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var icon: String
    public var mode: SelectionMatchTriggerMode
    public var pattern: String
    public var actionId: String
    public var isEnabled: Bool
    public var priority: Int

    public init(
        id: String,
        title: String,
        icon: String = "bolt.fill",
        mode: SelectionMatchTriggerMode,
        pattern: String,
        actionId: String,
        isEnabled: Bool = true,
        priority: Int = 980
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.mode = mode
        self.pattern = pattern
        self.actionId = actionId
        self.isEnabled = isEnabled
        self.priority = priority
    }
}

/// Metadata for a built-in Selection HUD auto-detector.
public struct SelectionDetectorInfo: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var icon: String
    public var isEnabled: Bool
    public var priority: Int

    public init(id: String, title: String, icon: String, isEnabled: Bool, priority: Int) {
        self.id = id
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.priority = priority
    }
}
