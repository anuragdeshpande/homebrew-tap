import Foundation

/// Leading icon descriptor for a row in the core multi-line hover detail list.
public enum SurfaceHoverListIcon: Codable, Equatable, Sendable {
    case systemSymbol(name: String, tintHex: String? = nil)
    case fileType(fileName: String, filePath: String, preferDiskIcon: Bool = false)
    case appBundle(bundleId: String)

    enum CodingKeys: String, CodingKey {
        case kind
        case name
        case tintHex
        case fileName
        case filePath
        case preferDiskIcon
        case bundleId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "systemSymbol"
        switch kind {
        case "fileType":
            let fileName = try container.decodeIfPresent(String.self, forKey: .fileName) ?? ""
            let filePath = try container.decodeIfPresent(String.self, forKey: .filePath) ?? ""
            let preferDiskIcon = try container.decodeIfPresent(Bool.self, forKey: .preferDiskIcon) ?? false
            self = .fileType(fileName: fileName, filePath: filePath, preferDiskIcon: preferDiskIcon)
        case "appBundle":
            let bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId) ?? ""
            self = .appBundle(bundleId: bundleId)
        default:
            let name = try container.decodeIfPresent(String.self, forKey: .name) ?? "circle.fill"
            let tintHex = try container.decodeIfPresent(String.self, forKey: .tintHex)
            self = .systemSymbol(name: name, tintHex: tintHex)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .systemSymbol(let name, let tintHex):
            try container.encode("systemSymbol", forKey: .kind)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(tintHex, forKey: .tintHex)
        case .fileType(let fileName, let filePath, let preferDiskIcon):
            try container.encode("fileType", forKey: .kind)
            try container.encode(fileName, forKey: .fileName)
            try container.encode(filePath, forKey: .filePath)
            try container.encode(preferDiskIcon, forKey: .preferDiskIcon)
        case .appBundle(let bundleId):
            try container.encode("appBundle", forKey: .kind)
            try container.encode(bundleId, forKey: .bundleId)
        }
    }
}

/// Semantic tone for hover-revealed row actions in `SurfaceHoverListView`.
public enum SurfaceHoverListActionTone: String, Codable, CaseIterable, Sendable {
    case neutral
    case accent
    case destructive
    case positive
}

/// Visual chrome style for a row action when hovered.
public enum SurfaceHoverListActionStyle: String, Codable, CaseIterable, Sendable {
    /// Liquid Glass labeled capsule pill (e.g. "Cancel").
    case pill
    /// Compact circular icon button (e.g. Open / Go to location).
    case iconCircle
}

/// Interactive action revealed on the trailing edge when hovering a row in `SurfaceHoverListView`.
public struct SurfaceHoverListAction: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let systemIcon: String
    public let tone: SurfaceHoverListActionTone
    public let style: SurfaceHoverListActionStyle

    public init(
        id: String,
        title: String,
        systemIcon: String,
        tone: SurfaceHoverListActionTone = .neutral,
        style: SurfaceHoverListActionStyle = .pill
    ) {
        self.id = id
        self.title = title
        self.systemIcon = systemIcon
        self.tone = tone
        self.style = style
    }
}

/// Platform-wide row model for multi-item on-hover drawers across Notch, Pill, and Dynamic Island.
public struct SurfaceHoverListItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let icon: SurfaceHoverListIcon
    public let title: String
    public let subtitle: String
    public let statusText: String?
    public let isCompleted: Bool
    public let hoverActions: [SurfaceHoverListAction]
    public let metadata: [String: String]?

    public init(
        id: String,
        icon: SurfaceHoverListIcon,
        title: String,
        subtitle: String,
        statusText: String? = nil,
        isCompleted: Bool = false,
        hoverActions: [SurfaceHoverListAction] = [],
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.statusText = statusText
        self.isCompleted = isCompleted
        self.hoverActions = hoverActions
        self.metadata = metadata
    }
}

extension DownloadProgressSnapshot {
    /// Projects a download snapshot into a core `SurfaceHoverListItem`.
    public func asSurfaceHoverListItem() -> SurfaceHoverListItem {
        let subtitle = DownloadTrackerFormatting.formatRowSubtitle(for: self)
        let metadata: [String: String] = [
            "filePath": filePath,
            "source": source.rawValue
        ]
        if isCompleted {
            return SurfaceHoverListItem(
                id: id,
                icon: .fileType(fileName: fileName, filePath: filePath, preferDiskIcon: true),
                title: fileName,
                subtitle: subtitle,
                statusText: nil,
                isCompleted: true,
                hoverActions: [
                    SurfaceHoverListAction(
                        id: "open",
                        title: "Open",
                        systemIcon: "arrow.up.forward.square.fill",
                        tone: .positive,
                        style: .iconCircle
                    ),
                    SurfaceHoverListAction(
                        id: "reveal",
                        title: "Go to location",
                        systemIcon: "folder.fill",
                        tone: .accent,
                        style: .iconCircle
                    )
                ],
                metadata: metadata
            )
        }

        let actions: [SurfaceHoverListAction] = canCancel
            ? [
                SurfaceHoverListAction(
                    id: "cancel",
                    title: "Cancel",
                    systemIcon: "xmark",
                    tone: .destructive,
                    style: .pill
                )
            ]
            : []
        return SurfaceHoverListItem(
            id: id,
            icon: .fileType(fileName: fileName, filePath: filePath, preferDiskIcon: false),
            title: fileName,
            subtitle: subtitle,
            statusText: DownloadTrackerFormatting.formatSpeed(bytesPerSecond),
            isCompleted: false,
            hoverActions: actions,
            metadata: metadata
        )
    }
}
