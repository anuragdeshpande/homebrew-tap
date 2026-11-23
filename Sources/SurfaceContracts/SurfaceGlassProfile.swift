import Foundation

/// Self-contained Theme + Dynamic & Liquid Glass appearance profile that can be owned
/// independently by each surface (`primary`, `radialRing`, `selectionHUD`, `dockWidget`, `dockPreview`)
/// or inherited and overridden on a per-Dock-Widget basis by built-in and third-party extensions.
public struct SurfaceGlassProfile: Codable, Equatable, Sendable {
    public var theme: ArchipelagoTheme
    public var frostMode: ArchipelagoFrostMode
    public var frostLevel: Double
    public var dynamicGlassLevel: Double
    public var dynamicGlassTintDepth: Double
    /// Optical black tint applied directly to native `NSGlassEffectView.tintColor` (0 = Clear, 1 = Obsidian Tinted Glass)
    /// without adding surface smoke or dulling glass refraction.
    public var glassBlackTintAmount: Double
    public var glassColorTintPreset: ArchipelagoGlassColorTintPreset
    public var glassColorTintHex: String
    public var liquidGlassWallpaperBleed: Bool
    public var liquidGlassTintMode: ArchipelagoLiquidGlassTintMode
    public var liquidGlassCustomTintAmount: Double
    public var liquidGlassActiveTintEnabled: Bool
    public var liquidGlassAtRestTintAmount: Double

    public init(
        theme: ArchipelagoTheme = .dynamicGlass,
        frostMode: ArchipelagoFrostMode = .systemDefault,
        frostLevel: Double = 0.0,
        dynamicGlassLevel: Double = 0.5,
        dynamicGlassTintDepth: Double = 0.22,
        glassBlackTintAmount: Double = 0.0,
        glassColorTintPreset: ArchipelagoGlassColorTintPreset = .none,
        glassColorTintHex: String = "",
        liquidGlassWallpaperBleed: Bool = true,
        liquidGlassTintMode: ArchipelagoLiquidGlassTintMode = .systemDefault,
        liquidGlassCustomTintAmount: Double = 0.65,
        liquidGlassActiveTintEnabled: Bool = false,
        liquidGlassAtRestTintAmount: Double = 0.40
    ) {
        self.theme = theme
        self.frostMode = frostMode
        self.frostLevel = min(1.0, max(0.0, frostLevel))
        self.dynamicGlassLevel = min(1.0, max(0.0, dynamicGlassLevel))
        self.dynamicGlassTintDepth = min(1.0, max(0.0, dynamicGlassTintDepth))
        self.glassBlackTintAmount = min(1.0, max(0.0, glassBlackTintAmount))
        self.glassColorTintPreset = glassColorTintPreset
        self.glassColorTintHex = glassColorTintHex
        self.liquidGlassWallpaperBleed = liquidGlassWallpaperBleed
        self.liquidGlassTintMode = liquidGlassTintMode
        self.liquidGlassCustomTintAmount = min(1.0, max(0.0, liquidGlassCustomTintAmount))
        self.liquidGlassActiveTintEnabled = liquidGlassActiveTintEnabled
        self.liquidGlassAtRestTintAmount = min(1.0, max(0.0, liquidGlassAtRestTintAmount))
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.theme = try c.decodeIfPresent(ArchipelagoTheme.self, forKey: .theme) ?? .dynamicGlass
        self.frostMode = try c.decodeIfPresent(ArchipelagoFrostMode.self, forKey: .frostMode) ?? .systemDefault
        self.frostLevel = min(1.0, max(0.0, try c.decodeIfPresent(Double.self, forKey: .frostLevel) ?? 0.0))
        self.dynamicGlassLevel = min(1.0, max(0.0, try c.decodeIfPresent(Double.self, forKey: .dynamicGlassLevel) ?? 0.5))
        self.dynamicGlassTintDepth = min(1.0, max(0.0, try c.decodeIfPresent(Double.self, forKey: .dynamicGlassTintDepth) ?? 0.22))
        self.glassBlackTintAmount = min(1.0, max(0.0, try c.decodeIfPresent(Double.self, forKey: .glassBlackTintAmount) ?? 0.0))
        self.glassColorTintPreset = try c.decodeIfPresent(ArchipelagoGlassColorTintPreset.self, forKey: .glassColorTintPreset) ?? .none
        self.glassColorTintHex = try c.decodeIfPresent(String.self, forKey: .glassColorTintHex) ?? ""
        self.liquidGlassWallpaperBleed = try c.decodeIfPresent(Bool.self, forKey: .liquidGlassWallpaperBleed) ?? true
        self.liquidGlassTintMode = try c.decodeIfPresent(ArchipelagoLiquidGlassTintMode.self, forKey: .liquidGlassTintMode) ?? .systemDefault
        self.liquidGlassCustomTintAmount = min(1.0, max(0.0, try c.decodeIfPresent(Double.self, forKey: .liquidGlassCustomTintAmount) ?? 0.65))
        self.liquidGlassActiveTintEnabled = try c.decodeIfPresent(Bool.self, forKey: .liquidGlassActiveTintEnabled) ?? false
        self.liquidGlassAtRestTintAmount = min(1.0, max(0.0, try c.decodeIfPresent(Double.self, forKey: .liquidGlassAtRestTintAmount) ?? 0.40))
    }

    public func enforcingNotchRestriction(
        target: ArchipelagoSurfaceThemeTarget,
        surfaceStyle: ArchipelagoSurfaceStyle,
        hasPhysicalNotch: Bool
    ) -> SurfaceGlassProfile {
        guard target == .primary,
              surfaceStyle == .notch,
              hasPhysicalNotch,
              theme == .liquidGlass else {
            return self
        }
        var copy = self
        copy.theme = .dynamicGlass
        return copy
    }
}
