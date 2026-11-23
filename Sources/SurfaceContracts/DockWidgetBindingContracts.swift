import Foundation

/// Declares where a Dock Widget is allowed to render.
public enum DockWidgetPlacementCapability: String, Codable, Equatable, Hashable, Sendable {
    /// Renders only as a standalone Dock Widget.
    case standaloneOnly = "standalone_only"
    /// Renders only inside a bound Dock application icon's Dock Preview popover.
    case appBoundOnly = "app_bound_only"
    /// Can render as a standalone Dock Widget, bound to a Dock app icon, or both.
    case both = "both"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "standalone_only", "standaloneOnly":
            self = .standaloneOnly
        case "app_bound_only", "appBoundOnly":
            self = .appBoundOnly
        case "both":
            self = .both
        default:
            self = .both
        }
    }
}

/// User-selected placement mode for widgets supporting both standalone and app-bound rendering.
public enum DockWidgetPlacementMode: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case standalone = "standalone"
    case appBound = "app_bound"
    case both = "both"

    public var displayTitle: String {
        switch self {
        case .standalone: return "Standalone"
        case .appBound: return "App Icon"
        case .both: return "Both"
        }
    }

    public var includesStandalone: Bool {
        self == .standalone || self == .both
    }

    public var includesAppBound: Bool {
        self == .appBound || self == .both
    }

    public init?(flexibleRawValue raw: String) {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "standalone", "dock":
            self = .standalone
        case "app_bound", "appbound", "app", "appicon", "app_icon":
            self = .appBound
        case "both":
            self = .both
        default:
            return nil
        }
    }
}

/// Declares whether a Dock Widget binds to a fixed app or lets the user pick any app in Settings.
public enum DockIconBindingTarget: Codable, Equatable, Hashable, Sendable {
    case fixedApp(appName: String, bundleIdentifier: String?)
    case anyUserSelectedApp(suggestedAppName: String?, suggestedBundleIdentifier: String?)

    enum CodingKeys: String, CodingKey {
        case kind
        case appName = "app_name"
        case camelAppName = "appName"
        case bundleId = "bundle_id"
        case camelBundleId = "bundleIdentifier"
        case suggestedAppName = "suggested_app_name"
        case camelSuggestedAppName = "suggestedAppName"
        case suggestedBundleId = "suggested_bundle_id"
        case camelSuggestedBundleId = "suggestedBundleIdentifier"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(String.self, forKey: .kind)
        switch kind {
        case "fixed_app", "fixedApp":
            let name = try c.decodeIfPresent(String.self, forKey: .appName)
                ?? c.decode(String.self, forKey: .camelAppName)
            let bundle = try c.decodeIfPresent(String.self, forKey: .bundleId)
                ?? c.decodeIfPresent(String.self, forKey: .camelBundleId)
            self = .fixedApp(appName: name, bundleIdentifier: bundle)
        default:
            let suggestedName = try c.decodeIfPresent(String.self, forKey: .suggestedAppName)
                ?? c.decodeIfPresent(String.self, forKey: .camelSuggestedAppName)
            let suggestedBundle = try c.decodeIfPresent(String.self, forKey: .suggestedBundleId)
                ?? c.decodeIfPresent(String.self, forKey: .camelSuggestedBundleId)
            self = .anyUserSelectedApp(
                suggestedAppName: suggestedName,
                suggestedBundleIdentifier: suggestedBundle
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fixedApp(let appName, let bundleIdentifier):
            try c.encode("fixed_app", forKey: .kind)
            try c.encode(appName, forKey: .appName)
            try c.encodeIfPresent(bundleIdentifier, forKey: .bundleId)
        case .anyUserSelectedApp(let suggestedAppName, let suggestedBundleIdentifier):
            try c.encode("any_user_selected_app", forKey: .kind)
            try c.encodeIfPresent(suggestedAppName, forKey: .suggestedAppName)
            try c.encodeIfPresent(suggestedBundleIdentifier, forKey: .suggestedBundleId)
        }
    }
}

/// Wire & native specification for associating a Dock Widget with a Dock app icon (`IBindToDockIcon`).
public struct DockIconBindingSpec: Codable, Equatable, Hashable, Sendable {
    public let target: DockIconBindingTarget
    public let placementCapability: DockWidgetPlacementCapability
    public let supportsDynamicTint: Bool

    enum CodingKeys: String, CodingKey {
        case target
        case placementCapability = "placement_capability"
        case camelPlacementCapability = "placementCapability"
        case supportsDynamicTint = "supports_dynamic_tint"
        case camelSupportsDynamicTint = "supportsDynamicTint"
    }

    public init(
        target: DockIconBindingTarget,
        placementCapability: DockWidgetPlacementCapability = .both,
        supportsDynamicTint: Bool = true
    ) {
        self.target = target
        self.placementCapability = placementCapability
        self.supportsDynamicTint = supportsDynamicTint
    }

    public static func fixedApp(
        _ appName: String,
        bundleIdentifier: String? = nil,
        placementCapability: DockWidgetPlacementCapability = .both,
        supportsDynamicTint: Bool = true
    ) -> DockIconBindingSpec {
        DockIconBindingSpec(
            target: .fixedApp(appName: appName, bundleIdentifier: bundleIdentifier),
            placementCapability: placementCapability,
            supportsDynamicTint: supportsDynamicTint
        )
    }

    public static func anyUserSelectedApp(
        suggestedAppName: String? = nil,
        suggestedBundleIdentifier: String? = nil,
        placementCapability: DockWidgetPlacementCapability = .both,
        supportsDynamicTint: Bool = true
    ) -> DockIconBindingSpec {
        DockIconBindingSpec(
            target: .anyUserSelectedApp(
                suggestedAppName: suggestedAppName,
                suggestedBundleIdentifier: suggestedBundleIdentifier
            ),
            placementCapability: placementCapability,
            supportsDynamicTint: supportsDynamicTint
        )
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.target = try c.decode(DockIconBindingTarget.self, forKey: .target)
        self.placementCapability = try c.decodeIfPresent(DockWidgetPlacementCapability.self, forKey: .placementCapability)
            ?? c.decodeIfPresent(DockWidgetPlacementCapability.self, forKey: .camelPlacementCapability)
            ?? .both
        self.supportsDynamicTint = try c.decodeIfPresent(Bool.self, forKey: .supportsDynamicTint)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelSupportsDynamicTint)
            ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(target, forKey: .target)
        try c.encode(placementCapability, forKey: .placementCapability)
        try c.encode(supportsDynamicTint, forKey: .supportsDynamicTint)
    }

    /// Resolves the effective placement mode given an optional user-selected preference.
    /// Fixed-app specs default to `.both` (when capability is `.both`) so the widget attaches
    /// automatically when that app icon is present in the Dock without extra configuration.
    public func effectivePlacementMode(userPreference: DockWidgetPlacementMode?) -> DockWidgetPlacementMode {
        switch placementCapability {
        case .standaloneOnly:
            return .standalone
        case .appBoundOnly:
            return .appBound
        case .both:
            if let userPreference {
                return userPreference
            }
            if case .fixedApp = target {
                return .both
            }
            return .standalone
        }
    }

    public var allowsUserAppSelection: Bool {
        if case .anyUserSelectedApp = target {
            return true
        }
        return false
    }
}

/// Idiomatic Swift protocol equivalent of `IBindToDockIcon`.
public protocol DockIconBindableWidget {
    var dockIconBindingSpec: DockIconBindingSpec { get }
}

/// Persisted per-widget app binding and Dynamic Tint configuration.
public struct DockWidgetAppBindingRecord: Codable, Equatable, Hashable, Sendable {
    public var widgetId: String
    public var placementMode: DockWidgetPlacementMode
    public var boundAppName: String?
    public var boundAppBundleIdentifier: String?
    public var boundAppPath: String?
    public var dynamicTintEnabled: Bool
    public var extractedTintHex: String?

    public init(
        widgetId: String,
        placementMode: DockWidgetPlacementMode = .standalone,
        boundAppName: String? = nil,
        boundAppBundleIdentifier: String? = nil,
        boundAppPath: String? = nil,
        dynamicTintEnabled: Bool = false,
        extractedTintHex: String? = nil
    ) {
        self.widgetId = widgetId
        self.placementMode = placementMode
        self.boundAppName = boundAppName
        self.boundAppBundleIdentifier = boundAppBundleIdentifier
        self.boundAppPath = boundAppPath
        self.dynamicTintEnabled = dynamicTintEnabled
        self.extractedTintHex = extractedTintHex
    }

    public var hasBoundApp: Bool {
        let hasBundle = boundAppBundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasName = boundAppName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        return hasBundle || hasName
    }
}

/// Active content view mode inside a Dock Preview popover when a widget is bound to the hovered app.
public enum DockPreviewContentMode: String, Codable, Equatable, Hashable, Sendable {
    case windows
    case widget
}
