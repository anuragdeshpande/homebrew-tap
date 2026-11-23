import Foundation

/// Execution authority tier for a permission declared by an extension.
public enum ExtensionPermissionTier: String, Codable, Equatable, Sendable {
    case hostDelegated = "host_delegated"
    case directSystem = "direct_system"
}

/// A permission requirement declared in an extension manifest or SDK definition.
public struct ExtensionPermissionRequirement: Codable, Equatable, Sendable {
    public let name: String
    public let title: String?
    public let tier: ExtensionPermissionTier
    public let justification: String
    public let systemPermission: String?

    public init(
        name: String,
        title: String? = nil,
        tier: ExtensionPermissionTier = .hostDelegated,
        justification: String,
        systemPermission: String? = nil
    ) {
        self.name = name
        self.title = title
        self.tier = tier
        self.justification = justification
        self.systemPermission = systemPermission
    }

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !justification.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var displayTitle: String {
        if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        return name
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

/// A resolved per-extension permission declaration tracked by the host permission manager.
public struct ExtensionPermissionDeclaration: Codable, Equatable, Identifiable, Sendable {
    public let extensionId: String
    public let extensionName: String
    public let requirement: ExtensionPermissionRequirement

    public var id: String {
        "\(extensionId):\(requirement.name)"
    }

    public init(
        extensionId: String,
        extensionName: String,
        requirement: ExtensionPermissionRequirement
    ) {
        self.extensionId = extensionId
        self.extensionName = extensionName
        self.requirement = requirement
    }
}
