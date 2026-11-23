import Foundation

public enum SDUIDeltaOperation: Codable, Equatable, Sendable {
    case replaceNode(id: String, with: SDUINode)
}

public struct SDUIDelta: Codable, Equatable, Sendable {
    public let baseRevision: UInt64
    public let revision: UInt64
    public let operations: [SDUIDeltaOperation]

    public init(
        baseRevision: UInt64,
        revision: UInt64,
        operations: [SDUIDeltaOperation]
    ) {
        self.baseRevision = baseRevision
        self.revision = revision
        self.operations = operations
    }
}

public struct SDUISnapshot: Codable, Equatable, Sendable {
    public let revision: UInt64
    public let tree: SDUITree

    public init(revision: UInt64, tree: SDUITree) {
        self.revision = revision
        self.tree = tree
    }
}

public enum SDUIUpdate: Codable, Equatable, Sendable {
    case snapshot(SDUISnapshot)
    case delta(SDUIDelta)
}

public struct SDUIUpdateResult: Equatable, Sendable {
    public let accepted: Bool
    public let tree: SDUITree
    public let revision: UInt64
    public let diagnostic: SDUIDiagnostic?

    public init(
        accepted: Bool,
        tree: SDUITree,
        revision: UInt64,
        diagnostic: SDUIDiagnostic?
    ) {
        self.accepted = accepted
        self.tree = tree
        self.revision = revision
        self.diagnostic = diagnostic
    }
}

public struct SDUIState: Equatable, Sendable {
    public private(set) var tree: SDUITree
    public private(set) var revision: UInt64

    public init(tree: SDUITree, revision: UInt64 = 0) {
        self.tree = tree
        self.revision = revision
    }

    @discardableResult
    public mutating func apply(_ update: SDUIUpdate) -> SDUIUpdateResult {
        switch update {
        case .snapshot(let snapshot):
            guard snapshot.revision > revision else {
                return result(accepted: false, diagnostic: .staleRevision)
            }
            guard snapshot.tree.validate().isValid else {
                return result(accepted: false, diagnostic: .invalidTree)
            }
            tree = snapshot.tree
            revision = snapshot.revision
            return result(accepted: true, diagnostic: nil)
        case .delta(let delta):
            guard delta.baseRevision == revision else {
                return result(accepted: false, diagnostic: .staleRevision)
            }
            guard delta.revision > delta.baseRevision else {
                return result(accepted: false, diagnostic: .invalidRevision)
            }
            var updatedTree = tree
            for operation in delta.operations {
                guard case .replaceNode(let id, let replacement) = operation,
                      let replaced = updatedTree.replacingNode(id: id, with: replacement)
                else {
                    return result(accepted: false, diagnostic: .invalidTree)
                }
                updatedTree = replaced
            }
            guard updatedTree.validate().isValid else {
                return result(accepted: false, diagnostic: .invalidTree)
            }
            tree = updatedTree
            revision = delta.revision
            return result(accepted: true, diagnostic: nil)
        }
    }

    private func result(
        accepted: Bool,
        diagnostic: SDUIDiagnostic?
    ) -> SDUIUpdateResult {
        SDUIUpdateResult(
            accepted: accepted,
            tree: tree,
            revision: revision,
            diagnostic: diagnostic
        )
    }
}

public extension SDUITree {
    func replacingNode(id: String, with replacement: SDUINode) -> SDUITree? {
        guard let root = root.replacingNode(id: id, with: replacement) else {
            return nil
        }
        return Self(version: version, root: root)
    }
}

public extension SDUINode {
    func replacingNode(id: String, with replacement: SDUINode) -> SDUINode? {
        if self.id == id {
            return replacement
        }
        var didReplace = false
        let updatedChildren = children.map { child in
            guard !didReplace else { return child }
            guard let updated = child.replacingNode(id: id, with: replacement) else {
                return child
            }
            didReplace = true
            return updated
        }
        return didReplace
            ? SDUINode(
                id: self.id,
                primitive: primitive,
                value: value,
                progress: progress,
                children: updatedChildren,
                action: action,
                accessibility: accessibility,
                fallback: fallback,
                isRequired: isRequired
            )
            : nil
    }
}
