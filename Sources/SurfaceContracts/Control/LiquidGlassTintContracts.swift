import Foundation

public enum LiquidGlassSurfaceKind: String, Codable, CaseIterable, Sendable {
    case island = "island"
    case notch = "notch"
    case pill = "pill"
    case dockWidget = "dockWidget"
    case dockPreview = "dockPreview"
    case fastClip = "fastClip"
}

public struct SurfaceTintTelemetry: Codable, Equatable, Sendable {
    public let surface: String
    public let isActive: Bool
    public let targetTint: Double
    public let currentTint: Double
    public let isTransitioning: Bool
    public let transitionProgress: Double
    public let alpha: Double

    public init(
        surface: String,
        isActive: Bool,
        targetTint: Double,
        currentTint: Double,
        isTransitioning: Bool,
        transitionProgress: Double,
        alpha: Double
    ) {
        self.surface = surface
        self.isActive = isActive
        self.targetTint = targetTint
        self.currentTint = currentTint
        self.isTransitioning = isTransitioning
        self.transitionProgress = transitionProgress
        self.alpha = alpha
    }
}

public struct LiquidGlassTintStatusResponse: Codable, Equatable, Sendable {
    public let mode: ArchipelagoLiquidGlassTintMode
    public let customTintAmount: Double
    public let activeTintEnabled: Bool
    public let atRestTintAmount: Double
    public let hideWhenInactive: Bool
    public let inactiveDismissDelay: Double
    public let isPrimaryPresented: Bool
    public let isPointerHoldingReveal: Bool
    public let timestamp: Double
    public let surfaces: [String: SurfaceTintTelemetry]

    public init(
        mode: ArchipelagoLiquidGlassTintMode,
        customTintAmount: Double,
        activeTintEnabled: Bool,
        atRestTintAmount: Double,
        hideWhenInactive: Bool,
        inactiveDismissDelay: Double,
        isPrimaryPresented: Bool = true,
        isPointerHoldingReveal: Bool = false,
        timestamp: Double,
        surfaces: [String: SurfaceTintTelemetry]
    ) {
        self.mode = mode
        self.customTintAmount = customTintAmount
        self.activeTintEnabled = activeTintEnabled
        self.atRestTintAmount = atRestTintAmount
        self.hideWhenInactive = hideWhenInactive
        self.inactiveDismissDelay = inactiveDismissDelay
        self.isPrimaryPresented = isPrimaryPresented
        self.isPointerHoldingReveal = isPointerHoldingReveal
        self.timestamp = timestamp
        self.surfaces = surfaces
    }
}
