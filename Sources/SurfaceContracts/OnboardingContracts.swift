import Foundation

/// Ordered steps in Archipelago's first-run and on-demand onboarding wizard.
/// Dedicated showcase screens give each Archipelago surface room to breathe.
public enum ArchipelagoOnboardingStep: String, CaseIterable, Codable, Identifiable, Sendable {
    case welcome
    case notificationSurface
    case radialRingSurface
    case dockPreviewsSurface
    case selectionHUDSurface
    case permissions
    case personalize
    case ready

    public var id: String { rawValue }

    /// Parses step strings, preserving backwards-compatibility with legacy `"surfaces"`.
    public static func parse(rawValue: String) -> ArchipelagoOnboardingStep? {
        if rawValue == "surfaces" {
            return .notificationSurface
        }
        return ArchipelagoOnboardingStep(rawValue: rawValue)
    }

    public static func step(forBeat beatId: String) -> ArchipelagoOnboardingStep? {
        switch beatId {
        case "notification": return .notificationSurface
        case "radialRing": return .radialRingSurface
        case "dockPreviews": return .dockPreviewsSurface
        case "selectionHUD": return .selectionHUDSurface
        default: return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let parsed = Self.parse(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown ArchipelagoOnboardingStep: \(raw)"
            )
        }
        self = parsed
    }

    public var index: Int {
        switch self {
        case .welcome: return 0
        case .notificationSurface: return 1
        case .radialRingSurface: return 2
        case .dockPreviewsSurface: return 3
        case .selectionHUDSurface: return 4
        case .permissions: return 5
        case .personalize: return 6
        case .ready: return 7
        }
    }

    public var isSurfaceShowcaseStep: Bool {
        surfaceOrdinal != nil
    }

    public var surfaceOrdinal: Int? {
        switch self {
        case .notificationSurface: return 1
        case .radialRingSurface: return 2
        case .dockPreviewsSurface: return 3
        case .selectionHUDSurface: return 4
        default: return nil
        }
    }

    public var beatIdentifier: String? {
        switch self {
        case .notificationSurface: return "notification"
        case .radialRingSurface: return "radialRing"
        case .dockPreviewsSurface: return "dockPreviews"
        case .selectionHUDSurface: return "selectionHUD"
        default: return nil
        }
    }

    public static let finaleWelcomeTitle = "Welcome to your Expanded Mac"

    public var title: String {
        switch self {
        case .welcome: return "An Island of Islands"
        case .notificationSurface: return "Notification Surface"
        case .radialRingSurface: return "Radial Action Ring"
        case .dockPreviewsSurface: return "Dock Previews & Widgets"
        case .selectionHUDSurface: return "Context-Aware Selection HUD"
        case .permissions: return "Permissions & Privacy"
        case .personalize: return "Let's Personalize for You"
        case .ready: return "You're All Set"
        }
    }

    public var subtitle: String {
        switch self {
        case .welcome:
            return "Expand your Mac with purpose-built native surfaces — each designed for one job so you can get more done anywhere on screen."
        case .notificationSurface:
            return "Surfaces urgent system alerts, transfers, and live states that need your attention — never a catch-all drawer stuffing clutter into the notch."
        case .radialRingSurface:
            return "A concentric quick-action wheel triggered by a three-finger trackpad tap, putting shortcuts right beneath your cursor."
        case .dockPreviewsSurface:
            return "Hover any Dock app icon to view open and minimized windows side-by-side alongside glanceable Liquid Glass Dock widgets."
        case .selectionHUDSurface:
            return "Automatically recognizes whether you highlighted prose, a web link, or code — offering Rewrite, Open Link, Explain, or Copy right above your text."
        case .permissions:
            return "Grant Accessibility and Screen Recording so Archipelago can anchor surfaces and render previews accurately — 100% locally on your Mac."
        case .personalize:
            return "Choose where Archipelago lives, your default surface finish, and your preferred notification geometry."
        case .ready:
            return "Your Archipelago workspace is configured and ready. Open Settings anytime to fine-tune individual surfaces."
        }
    }

    public var next: ArchipelagoOnboardingStep? {
        switch self {
        case .welcome: return .notificationSurface
        case .notificationSurface: return .radialRingSurface
        case .radialRingSurface: return .dockPreviewsSurface
        case .dockPreviewsSurface: return .selectionHUDSurface
        case .selectionHUDSurface: return .permissions
        case .permissions: return .personalize
        case .personalize: return .ready
        case .ready: return nil
        }
    }

    public var previous: ArchipelagoOnboardingStep? {
        switch self {
        case .welcome: return nil
        case .notificationSurface: return .welcome
        case .radialRingSurface: return .notificationSurface
        case .dockPreviewsSurface: return .radialRingSurface
        case .selectionHUDSurface: return .dockPreviewsSurface
        case .permissions: return .selectionHUDSurface
        case .personalize: return .permissions
        case .ready: return .personalize
        }
    }
}

/// Identifies which live PreviewKit or feature panel accompanies a What's New Bento cell.
public enum ArchipelagoWhatsNewPreviewKind: String, Codable, Equatable, Sendable {
    case notification
    case radialRing
    case dockPreview
    case selectionHUD
    case permissions
    case localAI
}

/// Distinguishes required core system authorizations from optional feature authorizations.
public enum ArchipelagoPermissionRequirementTier: String, Codable, Equatable, Sendable {
    case required
    case optional
}

/// Visual highlight card presented in the What's New dialog and Bento detail view.
public struct ArchipelagoWhatsNewHighlight: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let iconName: String
    public let title: String
    public let subtitle: String
    public let badge: String?
    public let detailDescription: String
    public let bulletPoints: [String]
    public let previewKind: ArchipelagoWhatsNewPreviewKind?

    public init(
        id: String,
        iconName: String,
        title: String,
        subtitle: String,
        badge: String? = nil,
        detailDescription: String = "",
        bulletPoints: [String] = [],
        previewKind: ArchipelagoWhatsNewPreviewKind? = nil
    ) {
        self.id = id
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.detailDescription = detailDescription
        self.bulletPoints = bulletPoints
        self.previewKind = previewKind
    }
}

/// Categorized changelog list rendered inside the What's New dialog.
public struct ArchipelagoWhatsNewCategorySection: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let category: String
    public let title: String
    public let items: [String]
    public let itemDescriptions: [String: String]

    public init(
        id: String,
        category: String,
        title: String,
        items: [String],
        itemDescriptions: [String: String] = [:]
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.items = items
        self.itemDescriptions = itemDescriptions
    }
}

/// Structured release payload rendered in the What's New dialog.
public struct ArchipelagoWhatsNewRelease: Codable, Equatable, Sendable, Identifiable {
    public var id: String { "\(version)-\(build)" }
    public let version: String
    public let build: String
    public let title: String
    public let publishedAt: String?
    public let summary: String
    public let highlights: [ArchipelagoWhatsNewHighlight]
    public let sections: [ArchipelagoWhatsNewCategorySection]

    public init(
        version: String,
        build: String,
        title: String,
        publishedAt: String? = nil,
        summary: String,
        highlights: [ArchipelagoWhatsNewHighlight],
        sections: [ArchipelagoWhatsNewCategorySection]
    ) {
        self.version = version
        self.build = build
        self.title = title
        self.publishedAt = publishedAt
        self.summary = summary
        self.highlights = highlights
        self.sections = sections
    }
}

/// Decision made by the onboarding/update launch evaluator.
public enum ArchipelagoLaunchPresentationDecision: String, Codable, Equatable, Sendable {
    case none
    case onboarding
    case whatsNew
}

/// Real-time GPU/Metal frame-pacing telemetry recorded during onboarding completion flare playback.
public struct ArchipelagoOnboardingFlareMetrics: Codable, Equatable, Sendable {
    public let runCount: Int
    public let lastRunRenderedFrames: Int
    public let lastRunDurationSeconds: Double
    public let averageFPS: Double
    public let minInstantFPS: Double
    public let p95FrameIntervalMs: Double
    public let maxFrameIntervalMs: Double
    public let droppedFrameCount: Int
    public let usedScreenRefractionTexture: Bool
    public let rendererBackend: String

    public init(
        runCount: Int,
        lastRunRenderedFrames: Int,
        lastRunDurationSeconds: Double,
        averageFPS: Double,
        minInstantFPS: Double,
        p95FrameIntervalMs: Double,
        maxFrameIntervalMs: Double,
        droppedFrameCount: Int,
        usedScreenRefractionTexture: Bool,
        rendererBackend: String = "metal_liquid_wave"
    ) {
        self.runCount = runCount
        self.lastRunRenderedFrames = lastRunRenderedFrames
        self.lastRunDurationSeconds = lastRunDurationSeconds
        self.averageFPS = averageFPS
        self.minInstantFPS = minInstantFPS
        self.p95FrameIntervalMs = p95FrameIntervalMs
        self.maxFrameIntervalMs = maxFrameIntervalMs
        self.droppedFrameCount = droppedFrameCount
        self.usedScreenRefractionTexture = usedScreenRefractionTexture
        self.rendererBackend = rendererBackend
    }
}

/// Observable status snapshot exposed to Settings, tests, and the CLI (`onboarding.status`).
public struct ArchipelagoOnboardingStatusSnapshot: Codable, Equatable, Sendable {
    public let hasCompletedOnboarding: Bool
    public let inProgress: Bool
    public let currentStep: ArchipelagoOnboardingStep
    public let resumedFromRelaunch: Bool
    public let pendingRelaunchPermission: String?
    public let completedOnboardingVersion: String?
    public let lastSeenWhatsNewVersion: String?
    public let currentVersion: String
    public let currentBuild: String
    public let isOnboardingVisible: Bool
    public let isWhatsNewVisible: Bool
    public let activeWhatsNewRelease: ArchipelagoWhatsNewRelease?
    public let requiredPermissions: [String]
    public let optionalPermissions: [String]
    public let permissionStates: [String: String]
    public let allRequiredPermissionsGranted: Bool
    public let canAdvanceFromCurrentStep: Bool
    public let needsRelaunch: Bool
    public let lastLaunchDecision: ArchipelagoLaunchPresentationDecision
    public let activeSurfaceBeat: String
    public let isOptionalPermissionsExpanded: Bool
    public let expandedPermissionExplanations: [String]
    public let selectedWhatsNewCellId: String?
    public let selectedWhatsNewCategoryTab: String
    public let isCompletionFlareActive: Bool
    public let completionFlareTriggerCount: Int
    public let lastFlareMetrics: ArchipelagoOnboardingFlareMetrics?
    public let isFinaleMorphActive: Bool
    public let finaleGreetingTitle: String

    public init(
        hasCompletedOnboarding: Bool,
        inProgress: Bool,
        currentStep: ArchipelagoOnboardingStep,
        resumedFromRelaunch: Bool,
        pendingRelaunchPermission: String?,
        completedOnboardingVersion: String?,
        lastSeenWhatsNewVersion: String?,
        currentVersion: String,
        currentBuild: String,
        isOnboardingVisible: Bool,
        isWhatsNewVisible: Bool,
        activeWhatsNewRelease: ArchipelagoWhatsNewRelease?,
        requiredPermissions: [String],
        optionalPermissions: [String],
        permissionStates: [String: String],
        allRequiredPermissionsGranted: Bool,
        canAdvanceFromCurrentStep: Bool,
        needsRelaunch: Bool,
        lastLaunchDecision: ArchipelagoLaunchPresentationDecision,
        activeSurfaceBeat: String = "notification",
        isOptionalPermissionsExpanded: Bool = false,
        expandedPermissionExplanations: [String] = [],
        selectedWhatsNewCellId: String? = nil,
        selectedWhatsNewCategoryTab: String = "all",
        isCompletionFlareActive: Bool = false,
        completionFlareTriggerCount: Int = 0,
        lastFlareMetrics: ArchipelagoOnboardingFlareMetrics? = nil,
        isFinaleMorphActive: Bool = false,
        finaleGreetingTitle: String = ArchipelagoOnboardingStep.finaleWelcomeTitle
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.inProgress = inProgress
        self.currentStep = currentStep
        self.resumedFromRelaunch = resumedFromRelaunch
        self.pendingRelaunchPermission = pendingRelaunchPermission
        self.completedOnboardingVersion = completedOnboardingVersion
        self.lastSeenWhatsNewVersion = lastSeenWhatsNewVersion
        self.currentVersion = currentVersion
        self.currentBuild = currentBuild
        self.isOnboardingVisible = isOnboardingVisible
        self.isWhatsNewVisible = isWhatsNewVisible
        self.activeWhatsNewRelease = activeWhatsNewRelease
        self.requiredPermissions = requiredPermissions
        self.optionalPermissions = optionalPermissions
        self.permissionStates = permissionStates
        self.allRequiredPermissionsGranted = allRequiredPermissionsGranted
        self.canAdvanceFromCurrentStep = canAdvanceFromCurrentStep
        self.needsRelaunch = needsRelaunch
        self.lastLaunchDecision = lastLaunchDecision
        self.activeSurfaceBeat = activeSurfaceBeat
        self.isOptionalPermissionsExpanded = isOptionalPermissionsExpanded
        self.expandedPermissionExplanations = expandedPermissionExplanations
        self.selectedWhatsNewCellId = selectedWhatsNewCellId
        self.selectedWhatsNewCategoryTab = selectedWhatsNewCategoryTab
        self.isCompletionFlareActive = isCompletionFlareActive
        self.completionFlareTriggerCount = completionFlareTriggerCount
        self.lastFlareMetrics = lastFlareMetrics
        self.isFinaleMorphActive = isFinaleMorphActive
        self.finaleGreetingTitle = finaleGreetingTitle
    }
}
