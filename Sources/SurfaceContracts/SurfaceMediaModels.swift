import Foundation

/// High-level playback state reported by system MediaRemote or simulated media events.
public enum SurfaceMediaPlaybackState: String, Codable, Equatable, Sendable {
    case playing
    case paused
    case stopped
}

/// Transport commands supported by the system MediaRemote controller.
public enum SurfaceMediaCommand: Equatable, Sendable {
    case play
    case pause
    case togglePlayPause
    case nextTrack
    case previousTrack
    case seek(seconds: Double)
    case openSourceApp

    /// Raw Apple MediaRemote command identifier for `MRMediaRemoteSendCommand`.
    public var mediaRemoteCommandId: Int? {
        switch self {
        case .play: return 0
        case .pause: return 1
        case .togglePlayPause: return 2
        case .nextTrack: return 4
        case .previousTrack: return 5
        case .seek, .openSourceApp: return nil
        }
    }
}

/// Normalized RGB accent color extracted from media artwork for single-hero styling.
public struct SurfaceMediaAccentColor: Codable, Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = min(1.0, max(0.0, red))
        self.green = min(1.0, max(0.0, green))
        self.blue = min(1.0, max(0.0, blue))
    }

    public var hexString: String {
        let r = Int((red * 255.0).rounded())
        let g = Int((green * 255.0).rounded())
        let b = Int((blue * 255.0).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

/// Snapshot of the currently active system Now Playing media session.
public struct SurfaceMediaState: Codable, Equatable, Sendable {
    public let title: String
    public let artist: String
    public let album: String
    public let isPlaying: Bool
    public let playbackRate: Double
    public let duration: Double
    public let elapsedTime: Double
    public let elapsedTimestamp: Date?
    public let isLiveStream: Bool
    public let bundleIdentifier: String?
    public let parentBundleIdentifier: String?
    public let sourceAppName: String?
    public let contentItemIdentifier: String?
    public let artworkIdentifier: String?
    public let artworkMIMEType: String?
    public let artworkURL: String?
    public let artworkBase64: String?
    public let accentColor: SurfaceMediaAccentColor?
    public let isSimulated: Bool

    public init(
        title: String,
        artist: String = "",
        album: String = "",
        isPlaying: Bool,
        playbackRate: Double? = nil,
        duration: Double = 0,
        elapsedTime: Double = 0,
        elapsedTimestamp: Date? = Date(),
        isLiveStream: Bool = false,
        bundleIdentifier: String? = nil,
        parentBundleIdentifier: String? = nil,
        sourceAppName: String? = nil,
        contentItemIdentifier: String? = nil,
        artworkIdentifier: String? = nil,
        artworkMIMEType: String? = nil,
        artworkURL: String? = nil,
        artworkBase64: String? = nil,
        accentColor: SurfaceMediaAccentColor? = nil,
        isSimulated: Bool = false
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.artist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        self.album = album.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isPlaying = isPlaying
        self.playbackRate = playbackRate ?? (isPlaying ? 1.0 : 0.0)
        self.duration = duration.isFinite && duration > 0 ? duration : 0
        self.elapsedTime = elapsedTime.isFinite && elapsedTime >= 0 ? elapsedTime : 0
        self.elapsedTimestamp = elapsedTimestamp
        self.isLiveStream = isLiveStream
        self.bundleIdentifier = bundleIdentifier
        self.parentBundleIdentifier = parentBundleIdentifier
        self.sourceAppName = sourceAppName
        self.contentItemIdentifier = contentItemIdentifier
        self.artworkIdentifier = artworkIdentifier
        self.artworkMIMEType = artworkMIMEType
        self.artworkURL = artworkURL
        self.artworkBase64 = artworkBase64
        self.accentColor = accentColor
        self.isSimulated = isSimulated
    }

    public var playbackState: SurfaceMediaPlaybackState {
        if !hasTrack { return .stopped }
        return isPlaying ? .playing : .paused
    }

    public var hasTrack: Bool {
        !title.isEmpty || !artist.isEmpty
    }

    public var hasArtwork: Bool {
        if let artworkBase64, !artworkBase64.isEmpty { return true }
        if let artworkURL, !artworkURL.isEmpty { return true }
        return false
    }

    /// Resolves the user-facing application bundle identifier, unwrapping WebKit/helper/renderer
    /// subprocesses back to their parent app bundle when available.
    public var launchableBundleIdentifier: String? {
        Self.resolveLaunchableBundleIdentifier(
            bundleIdentifier: bundleIdentifier,
            parentBundleIdentifier: parentBundleIdentifier
        )
    }

    public static func resolveLaunchableBundleIdentifier(
        bundleIdentifier: String?,
        parentBundleIdentifier: String?
    ) -> String? {
        let trimmedBundle = bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedParent = parentBundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let bundle = trimmedBundle, !bundle.isEmpty else {
            return (trimmedParent?.isEmpty == false) ? trimmedParent : nil
        }
        let lower = bundle.lowercased()
        let subprocessMarkers = [
            "webkit", ".helper", ".renderer", ".gpu", ".utility",
            ".network", ".plugin", ".web", "crashpad"
        ]
        if let parent = trimmedParent, !parent.isEmpty,
           subprocessMarkers.contains(where: { lower.contains($0) }) {
            return parent
        }
        return bundle
    }

    /// Subtitle combining artist and album or source application for the hover drawer.
    public var subtitleText: String {
        if !artist.isEmpty && !album.isEmpty && album.caseInsensitiveCompare(artist) != .orderedSame {
            return "\(artist) — \(album)"
        }
        if !artist.isEmpty {
            return artist
        }
        if let sourceAppName, !sourceAppName.isEmpty {
            return sourceAppName
        }
        return album
    }

    /// Stable cache key for artwork decoding and transitions.
    public var resolvedArtworkCacheKey: String {
        if let artworkIdentifier, !artworkIdentifier.isEmpty {
            return "\(launchableBundleIdentifier ?? "media")::\(artworkIdentifier)"
        }
        if let contentItemIdentifier, !contentItemIdentifier.isEmpty {
            return "\(launchableBundleIdentifier ?? "media")::item:\(contentItemIdentifier)"
        }
        return "\(launchableBundleIdentifier ?? "media")::\(title)|\(artist)"
    }

    /// Projects the current playback position at `date` using the MediaRemote anchor timestamp.
    public func estimatedElapsedTime(at date: Date = Date()) -> Double {
        guard !isLiveStream else { return elapsedTime }
        guard isPlaying else {
            return duration > 0 ? min(duration, max(0, elapsedTime)) : max(0, elapsedTime)
        }
        let effectiveRate = playbackRate > 0 ? playbackRate : 1.0
        let delta: Double
        if let elapsedTimestamp {
            delta = max(0, date.timeIntervalSince(elapsedTimestamp))
        } else {
            delta = 0
        }
        let projected = elapsedTime + delta * effectiveRate
        if duration > 0 {
            return min(duration, max(0, projected))
        }
        return max(0, projected)
    }

    /// Normalized playback progress in `[0, 1]` at `date`.
    public func progress(at date: Date = Date()) -> Double {
        guard !isLiveStream, duration > 0 else { return 0 }
        return min(1.0, max(0.0, estimatedElapsedTime(at: date) / duration))
    }

    /// Formats a duration in seconds as `m:ss` or `h:mm:ss`.
    public static func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Returns a copy with updated playback state, elapsed position, or metadata.
    public func withPlaybackState(
        isPlaying: Bool,
        elapsedTime: Double? = nil,
        timestamp: Date = Date()
    ) -> SurfaceMediaState {
        SurfaceMediaState(
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            playbackRate: isPlaying ? 1.0 : 0.0,
            duration: duration,
            elapsedTime: elapsedTime ?? estimatedElapsedTime(at: timestamp),
            elapsedTimestamp: timestamp,
            isLiveStream: isLiveStream,
            bundleIdentifier: bundleIdentifier,
            parentBundleIdentifier: parentBundleIdentifier,
            sourceAppName: sourceAppName,
            contentItemIdentifier: contentItemIdentifier,
            artworkIdentifier: artworkIdentifier,
            artworkMIMEType: artworkMIMEType,
            artworkURL: artworkURL,
            artworkBase64: artworkBase64,
            accentColor: accentColor,
            isSimulated: isSimulated
        )
    }
}
