import Foundation

/// Categorizes a mounted macOS volume as user-visible or background/system-managed.
public enum MountedVolumeCategory: String, Codable, Equatable, Sendable {
    case userVisible
    case backgroundSystem
}

/// Resolved metadata and classification for a mounted volume or disk image.
public struct MountedVolumeDescriptor: Codable, Equatable, Sendable {
    public let mountPath: String
    public let rawLastPathComponent: String
    public let displayName: String
    public let sizeBytes: Int64?
    public let formattedSize: String?
    public let formatDescription: String?
    public let isDiskImage: Bool
    public let hasInstallableApp: Bool
    public let appBundlePath: String?
    public let category: MountedVolumeCategory
    public let backgroundReason: String?
    public let isSimulated: Bool

    public init(
        mountPath: String,
        rawLastPathComponent: String,
        displayName: String,
        sizeBytes: Int64? = nil,
        formattedSize: String? = nil,
        formatDescription: String? = nil,
        isDiskImage: Bool = false,
        hasInstallableApp: Bool = false,
        appBundlePath: String? = nil,
        category: MountedVolumeCategory = .userVisible,
        backgroundReason: String? = nil,
        isSimulated: Bool = false
    ) {
        self.mountPath = mountPath
        self.rawLastPathComponent = rawLastPathComponent
        self.displayName = displayName
        self.sizeBytes = sizeBytes
        self.formattedSize = formattedSize
        self.formatDescription = formatDescription
        self.isDiskImage = isDiskImage
        self.hasInstallableApp = hasInstallableApp
        self.appBundlePath = appBundlePath
        self.category = category
        self.backgroundReason = backgroundReason
        self.isSimulated = isSimulated
    }
}

/// Live-activity drive state rendered in the compact wings and spacious on-hover drawer.
public struct SurfaceDriveState: Codable, Equatable, Sendable {
    public let volumeName: String
    public let mountPath: String
    public let formattedSize: String?
    public let sizeBytes: Int64?
    public let formatDescription: String?
    public let isMounted: Bool
    public let isDiskImage: Bool
    public let hasInstallableApp: Bool
    public let appBundlePath: String?
    public let isBackgroundSystemMount: Bool
    public let backgroundReason: String?
    public let isSimulated: Bool

    public init(
        volumeName: String,
        mountPath: String,
        formattedSize: String? = nil,
        sizeBytes: Int64? = nil,
        formatDescription: String? = nil,
        isMounted: Bool = true,
        isDiskImage: Bool = false,
        hasInstallableApp: Bool = false,
        appBundlePath: String? = nil,
        isBackgroundSystemMount: Bool = false,
        backgroundReason: String? = nil,
        isSimulated: Bool = false
    ) {
        self.volumeName = volumeName
        self.mountPath = mountPath
        self.formattedSize = formattedSize
        self.sizeBytes = sizeBytes
        self.formatDescription = formatDescription
        self.isMounted = isMounted
        self.isDiskImage = isDiskImage
        self.hasInstallableApp = hasInstallableApp
        self.appBundlePath = appBundlePath
        self.isBackgroundSystemMount = isBackgroundSystemMount
        self.backgroundReason = backgroundReason
        self.isSimulated = isSimulated
    }

    public init(descriptor: MountedVolumeDescriptor, isMounted: Bool) {
        self.volumeName = descriptor.displayName
        self.mountPath = descriptor.mountPath
        self.formattedSize = descriptor.formattedSize
        self.sizeBytes = descriptor.sizeBytes
        self.formatDescription = descriptor.formatDescription
        self.isMounted = isMounted
        self.isDiskImage = descriptor.isDiskImage
        self.hasInstallableApp = descriptor.hasInstallableApp
        self.appBundlePath = descriptor.appBundlePath
        self.isBackgroundSystemMount = (descriptor.category == .backgroundSystem)
        self.backgroundReason = descriptor.backgroundReason
        self.isSimulated = descriptor.isSimulated
    }

    /// Icon token resolved by `MacOSVolumeIconProvider` for native macOS volume/DMG icons.
    public var leadingIconToken: String {
        if isDiskImage {
            return "volume://dmg"
        }
        if !mountPath.isEmpty && !isSimulated,
           let encodedPath = mountPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            return "volume://path/\(encodedPath)"
        }
        return "volume://external"
    }

    /// Concise summary rendered in the on-hover drawer (`<Name> — <Size>` or `<Name> — Safely Ejected`).
    public var hoverSummaryText: String {
        guard isMounted else {
            return "\(volumeName) — Safely Ejected"
        }
        if let size = formattedSize?.trimmingCharacters(in: .whitespacesAndNewlines), !size.isEmpty {
            return "\(volumeName) — \(size)"
        }
        return volumeName
    }
}
