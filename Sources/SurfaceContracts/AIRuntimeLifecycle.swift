import Foundation

/// Shared runtime-identifier normalization and managed-label helpers used across
/// `ProcessMonitorKit` and `SurfaceCore`.
public enum AIRuntimeLifecycle: Sendable {
    public static let parakeetRuntimeId = "parakeet-mlx"
    public static let omlxRuntimeId = "omlx"

    public static func canonicalRuntimeId(_ runtimeId: String) -> String {
        let normalized = runtimeId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized == omlxRuntimeId || normalized.contains(omlxRuntimeId) {
            return omlxRuntimeId
        }
        if normalized.contains("parakeet") {
            return parakeetRuntimeId
        }
        return runtimeId
    }

    public static func markLoaded(
        _ runtimeId: String,
        in timestamps: inout [String: Date],
        at date: Date = Date()
    ) {
        timestamps[canonicalRuntimeId(runtimeId)] = date
    }

    public static func markUnloaded(_ runtimeId: String, in timestamps: inout [String: Date]) {
        timestamps.removeValue(forKey: canonicalRuntimeId(runtimeId))
    }

    public static func isLoaded(_ runtimeId: String, in timestamps: [String: Date]) -> Bool {
        timestamps[canonicalRuntimeId(runtimeId)] != nil
    }

    public static func managedLabelParts(_ label: String) -> (runtime: String, modelName: String) {
        let components = label.split(separator: "(", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let runtime = components.first ?? "AI"
        let modelName = components.count > 1
            ? components[1].replacingOccurrences(of: ")", with: "")
            : runtime
        return (canonicalRuntimeId(runtime), modelName)
    }
}
