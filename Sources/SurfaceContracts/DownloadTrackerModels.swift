import Foundation

/// Supported download sources tracked by the bundled System Events Download Tracker.
public enum DownloadTrackerSource: String, CaseIterable, Codable, Identifiable, Sendable {
    case airdrop
    case downloadsFolder
    case chromium
    case safari
    case firefox

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .airdrop:
            return "AirDrop"
        case .downloadsFolder:
            return "Downloads Folder"
        case .chromium:
            return "Chromium Browsers"
        case .safari:
            return "Safari"
        case .firefox:
            return "Firefox"
        }
    }

    public var subtitle: String {
        switch self {
        case .airdrop:
            return "Incoming AirDrop file transfers"
        case .downloadsFolder:
            return "Completed files and Smart DMG installers in ~/Downloads"
        case .chromium:
            return "Chrome, Arc, Brave, Edge, Vivaldi, and Opera (.crdownload, .opdownload)"
        case .safari:
            return "Safari active transfers (.download)"
        case .firefox:
            return "Firefox active transfers (.part)"
        }
    }

    public var iconName: String {
        switch self {
        case .airdrop:
            return "airplayaudio"
        case .downloadsFolder:
            return "folder.fill"
        case .chromium:
            return "globe"
        case .safari:
            return "safari.fill"
        case .firefox:
            return "flame.fill"
        }
    }

    public var defaultsKey: String {
        "archipelago.downloadTracker.source.\(rawValue)"
    }

    public var partialSuffixes: [String] {
        switch self {
        case .chromium:
            return [".crdownload", ".opdownload"]
        case .safari:
            return [".download"]
        case .firefox:
            return [".part"]
        case .airdrop, .downloadsFolder:
            return []
        }
    }

    /// Infers the browser download source from a partial file name, if applicable.
    public static func browserSource(forPartialFilename filename: String) -> DownloadTrackerSource? {
        let lower = filename.lowercased()
        if lower.hasSuffix(".crdownload") || lower.hasSuffix(".opdownload") {
            return .chromium
        }
        if lower.hasSuffix(".download") {
            return .safari
        }
        if lower.hasSuffix(".part") {
            return .firefox
        }
        return nil
    }

    /// Strips any known browser partial download suffix to recover the target file name.
    public static func displayFilename(forPartialFilename filename: String) -> String {
        let lower = filename.lowercased()
        for suffix in [".crdownload", ".opdownload", ".download", ".part"] {
            if lower.hasSuffix(suffix) {
                return String(filename.dropLast(suffix.count))
            }
        }
        return filename
    }
}

/// Snapshot of active or recently completed download progress emitted by `DownloadTrackerMonitor`.
public struct DownloadProgressSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let source: DownloadTrackerSource
    public let fileName: String
    public let filePath: String
    public let downloadLocation: String
    public let bytesReceived: Int64
    public let totalBytes: Int64?
    public let progress: Double?
    public let bytesPerSecond: Double?
    public let estimatedSecondsRemaining: TimeInterval?
    public let isCompleted: Bool
    public let canCancel: Bool

    public init(
        id: String,
        source: DownloadTrackerSource,
        fileName: String,
        filePath: String,
        downloadLocation: String? = nil,
        bytesReceived: Int64,
        totalBytes: Int64?,
        progress: Double?,
        bytesPerSecond: Double? = nil,
        estimatedSecondsRemaining: TimeInterval? = nil,
        isCompleted: Bool = false,
        canCancel: Bool = true
    ) {
        self.id = id
        self.source = source
        self.fileName = fileName
        self.filePath = filePath
        if let downloadLocation, !downloadLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.downloadLocation = downloadLocation
        } else {
            let parentName = URL(fileURLWithPath: filePath).deletingLastPathComponent().lastPathComponent
            self.downloadLocation = parentName.isEmpty || parentName == "/" ? "Downloads" : parentName
        }
        self.bytesReceived = bytesReceived
        self.totalBytes = totalBytes
        self.progress = progress
        self.bytesPerSecond = bytesPerSecond
        self.estimatedSecondsRemaining = estimatedSecondsRemaining
        self.isCompleted = isCompleted
        self.canCancel = canCancel
    }
}

/// Summary strings and progress values computed across active downloads for compact wings and Island.
public struct DownloadAggregatePresentation: Equatable, Sendable {
    public let activeCount: Int
    public let leadingText: String
    public let trailingText: String
    public let aggregateProgress: Double?
    public let totalRemainingSeconds: TimeInterval?

    public init(
        activeCount: Int,
        leadingText: String,
        trailingText: String,
        aggregateProgress: Double?,
        totalRemainingSeconds: TimeInterval?
    ) {
        self.activeCount = activeCount
        self.leadingText = leadingText
        self.trailingText = trailingText
        self.aggregateProgress = aggregateProgress
        self.totalRemainingSeconds = totalRemainingSeconds
    }
}

/// Pure, thread-safe formatting and aggregation helpers shared across `SurfaceCore` and `SurfaceUI`.
public enum DownloadTrackerFormatting: Sendable {
    public static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: max(0, bytes), countStyle: .file)
    }

    public static func formatTimeRemaining(_ seconds: TimeInterval?) -> String? {
        guard let seconds, seconds.isFinite, seconds >= 0 else { return nil }
        let rounded = Int(ceil(seconds))
        if rounded <= 0 {
            return "< 1s"
        }
        if rounded < 60 {
            return "\(rounded)s"
        }
        if rounded < 3600 {
            let minutes = rounded / 60
            let remSeconds = rounded % 60
            return remSeconds == 0 ? "\(minutes)m" : "\(minutes)m \(remSeconds)s"
        }
        let hours = rounded / 3600
        let remMinutes = (rounded % 3600) / 60
        return remMinutes == 0 ? "\(hours)h" : "\(hours)h \(remMinutes)m"
    }

    public static func formatSpeed(_ bytesPerSecond: Double?) -> String {
        guard let bps = bytesPerSecond, bps.isFinite, bps > 0 else { return "--" }
        if bps < 1_000.0 {
            return "\(Int(bps.rounded())) B/s"
        }
        if bps < 1_000_000.0 {
            return String(format: "%.0f KB/s", bps / 1_000.0)
        }
        if bps < 1_000_000_000.0 {
            return String(format: "%.1f MB/s", bps / 1_000_000.0)
        }
        return String(format: "%.2f GB/s", bps / 1_000_000_000.0)
    }

    public static func formatRowSubtitle(for snapshot: DownloadProgressSnapshot) -> String {
        if snapshot.isCompleted {
            let finalBytes = max(snapshot.bytesReceived, snapshot.totalBytes ?? 0)
            return "\(formatBytes(finalBytes)) · \(snapshot.downloadLocation)"
        }
        if let total = snapshot.totalBytes, total > 0 {
            return "\(formatBytes(snapshot.bytesReceived)) / \(formatBytes(total)) · \(snapshot.downloadLocation)"
        }
        return "\(formatBytes(snapshot.bytesReceived)) · \(snapshot.downloadLocation)"
    }

    public static func aggregatePresentation(for transfers: [DownloadProgressSnapshot]) -> DownloadAggregatePresentation {
        let active = transfers.filter { !$0.isCompleted }
        let activeCount = active.count
        let leadingText = activeCount <= 1 ? "Downloading" : "\(activeCount) Downloading"

        let maxETA = active
            .compactMap(\.estimatedSecondsRemaining)
            .filter { $0.isFinite && $0 >= 0 }
            .max()

        let hasKnownTotal = active.contains { ($0.totalBytes ?? 0) > 0 }
        let trailingText: String
        if let maxETA, let formatted = formatTimeRemaining(maxETA) {
            trailingText = formatted
        } else if hasKnownTotal {
            trailingText = "--"
        } else {
            let totalReceived = active.reduce(Int64(0)) { $0 + max(0, $1.bytesReceived) }
            trailingText = formatBytes(totalReceived)
        }

        let knownTotalEntries = active.filter { ($0.totalBytes ?? 0) > 0 }
        let aggregateProgress: Double?
        if !knownTotalEntries.isEmpty {
            let receivedSum = knownTotalEntries.reduce(Int64(0)) { $0 + max(0, $1.bytesReceived) }
            let totalSum = knownTotalEntries.reduce(Int64(0)) { $0 + max(1, $1.totalBytes ?? 0) }
            aggregateProgress = totalSum > 0 ? min(1.0, max(0.0, Double(receivedSum) / Double(totalSum))) : nil
        } else {
            aggregateProgress = nil
        }

        return DownloadAggregatePresentation(
            activeCount: activeCount,
            leadingText: leadingText,
            trailingText: trailingText,
            aggregateProgress: aggregateProgress,
            totalRemainingSeconds: maxETA
        )
    }
}
