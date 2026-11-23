import Foundation

public enum SDUIValidationIssue: Equatable, Sendable {
    case duplicateNodeID(String)
    case unapprovedPrimitive(SDUIPrimitive)
    case missingAccessibilityMetadata(String)
    case missingProgressValue(String)
    case invalidProgress(String)
    case missingAccessibleName(String)
    case actionOnNonButton(String)
    case invalidActionAccessibility(String)
    case actionAccessibilityMismatch(String)
    case fallbackIDMismatch(String)
}

public struct SDUIValidationResult: Equatable, Sendable {
    public let issues: [SDUIValidationIssue]
    public var isValid: Bool { issues.isEmpty }

    public init(issues: [SDUIValidationIssue]) {
        self.issues = issues
    }
}

public struct SDUILogicalRect: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct SDUISemanticHitRegion: Equatable, Sendable {
    public let nodeID: String
    public let actionID: String
    public let bounds: SDUILogicalRect
    public let accessibility: SDUIAccessibilityMetadata

    public init(
        nodeID: String,
        actionID: String,
        bounds: SDUILogicalRect,
        accessibility: SDUIAccessibilityMetadata
    ) {
        self.nodeID = nodeID
        self.actionID = actionID
        self.bounds = bounds
        self.accessibility = accessibility
    }
}

public enum SDUIDiagnostic: Equatable, Sendable {
    case staleRevision
    case invalidRevision
    case invalidTree
    case unsupportedRequiredPrimitive
}

public struct SDUIMaterializationResult: Equatable, Sendable {
    public let accepted: Bool
    public let tree: SDUITree?
    public let diagnostic: SDUIDiagnostic?

    public init(
        accepted: Bool,
        tree: SDUITree?,
        diagnostic: SDUIDiagnostic?
    ) {
        self.accepted = accepted
        self.tree = tree
        self.diagnostic = diagnostic
    }
}

public extension SDUITree {
    func validate() -> SDUIValidationResult {
        var ids = Set<String>()
        var issues: [SDUIValidationIssue] = []
        validate(
            node: root,
            ids: &ids,
            issues: &issues
        )
        return SDUIValidationResult(issues: issues)
    }

    func semanticHitRegions(
        boundsByNodeID: [String: SDUILogicalRect]
    ) -> [SDUISemanticHitRegion] {
        allNodes()
            .compactMap { node in
                guard
                    let action = node.action,
                    let bounds = boundsByNodeID[node.id]
                else {
                    return nil
                }
                return SDUISemanticHitRegion(
                    nodeID: node.id,
                    actionID: action.id,
                    bounds: bounds,
                    accessibility: action.accessibility
                )
            }
    }

    func materialize(
        supportedPrimitives: Set<SDUIPrimitive>
    ) -> SDUIMaterializationResult {
        guard let root = materialize(
            node: root,
            supportedPrimitives: supportedPrimitives
        ) else {
            return SDUIMaterializationResult(
                accepted: false,
                tree: nil,
                diagnostic: .unsupportedRequiredPrimitive
            )
        }
        let tree = Self(version: version, root: root)
        guard tree.validate().isValid else {
            return SDUIMaterializationResult(
                accepted: false,
                tree: nil,
                diagnostic: .invalidTree
            )
        }
        return SDUIMaterializationResult(
            accepted: true,
            tree: tree,
            diagnostic: nil
        )
    }

    private func validate(
        node: SDUINode,
        ids: inout Set<String>,
        issues: inout [SDUIValidationIssue]
    ) {
        if !ids.insert(node.id).inserted {
            issues.append(.duplicateNodeID(node.id))
        }
        if !SDUIPrimitive.approved.contains(node.primitive) {
            issues.append(.unapprovedPrimitive(node.primitive))
        }
        if node.accessibility == nil {
            issues.append(.missingAccessibilityMetadata(node.id))
        }
        if node.primitive == .progress, node.progress == nil {
            issues.append(.missingProgressValue(node.id))
        }
        if let progress = node.progress, !(0...1).contains(progress) {
            issues.append(.invalidProgress(node.id))
        }
        if let accessibility = node.accessibility, accessibility.label.isEmpty {
            issues.append(.missingAccessibleName(node.id))
        }
        if let action = node.action {
            if node.primitive != .button {
                issues.append(.actionOnNonButton(node.id))
            } else if action.accessibility.role != .button || action.accessibility.label.isEmpty {
                issues.append(.invalidActionAccessibility(node.id))
            } else if node.accessibility != action.accessibility {
                issues.append(.actionAccessibilityMismatch(node.id))
            }
        }
        if case .node(let fallback) = node.fallback, fallback.id != node.id {
            issues.append(.fallbackIDMismatch(node.id))
        }
        for child in node.children {
            validate(node: child, ids: &ids, issues: &issues)
        }
    }

    private func materialize(
        node: SDUINode,
        supportedPrimitives: Set<SDUIPrimitive>
    ) -> SDUINode? {
        guard SDUIPrimitive.approved.contains(node.primitive),
              supportedPrimitives.contains(node.primitive)
        else {
            guard !node.isRequired, let fallback = node.fallback else {
                return nil
            }
            guard case .node(let fallbackNode) = fallback else {
                return nil
            }
            guard fallbackNode.id == node.id else {
                return nil
            }
            return materialize(node: fallbackNode, supportedPrimitives: supportedPrimitives)
        }

        var children: [SDUINode] = []
        for child in node.children {
            guard let materializedChild = materialize(
                node: child,
                supportedPrimitives: supportedPrimitives
            ) else {
                return nil
            }
            children.append(materializedChild)
        }
        return SDUINode(
            id: node.id,
            primitive: node.primitive,
            value: node.value,
            progress: node.progress,
            children: children,
            action: node.action,
            accessibility: node.accessibility,
            fallback: nil,
            isRequired: node.isRequired
        )
    }
}
