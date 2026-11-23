import Foundation

/// Defines whether an activity auto-dismisses after a duration or persists until explicitly cleared.
public enum SurfaceActivityPersistence: Codable, Equatable, Sendable {
    case transient(duration: TimeInterval)
    case persistent
}

/// Core lifecycle policy for a surface live activity.
public struct SurfaceActivityPolicy: Codable, Equatable, Sendable {
    public var persistence: SurfaceActivityPersistence
    public var priority: Int
    public var resurfaceOnPreempt: Bool
    public var isDismissable: Bool

    public init(
        persistence: SurfaceActivityPersistence,
        priority: Int,
        resurfaceOnPreempt: Bool,
        isDismissable: Bool
    ) {
        self.persistence = persistence
        self.priority = priority
        self.resurfaceOnPreempt = resurfaceOnPreempt
        self.isDismissable = isDismissable
    }

    public var isPersistent: Bool {
        if case .persistent = persistence { return true }
        return false
    }
}

/// Per-event configuration persisted for System Events & Live Activities.
public struct SystemEventRuleConfig: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var customDismissDuration: Double?
    public var isPersistentOverride: Bool?
    public var resurfaceOnPreemptOverride: Bool?

    public init(
        isEnabled: Bool = true,
        customDismissDuration: Double? = nil,
        isPersistentOverride: Bool? = nil,
        resurfaceOnPreemptOverride: Bool? = nil
    ) {
        self.isEnabled = isEnabled
        self.customDismissDuration = customDismissDuration
        self.isPersistentOverride = isPersistentOverride
        self.resurfaceOnPreemptOverride = resurfaceOnPreemptOverride
    }

    public static let `default` = SystemEventRuleConfig()
}
