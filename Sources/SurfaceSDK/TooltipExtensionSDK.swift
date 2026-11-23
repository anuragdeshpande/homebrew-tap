import Foundation
import SurfaceContracts

/// Lightweight SDK router for out-of-process extensions exposing Adaptable Tooltip & Ring actions
/// over the canonical `TooltipExtensionIPCRequest` / `TooltipExtensionIPCResponse` JSON contract.
public actor TooltipExtensionRouter {
    public typealias PrimaryEvaluator = @Sendable (SelectionMatchContext) async -> PrimaryTooltipMatch?
    public typealias ActionExecutor = @Sendable (SelectionActionContext) async -> SelectionActionOutcome
    public typealias ActionExpander = @Sendable (SelectionActionContext) async -> ExpandedTooltipContent?

    public let extensionId: String
    private var descriptors: [SurfaceActionDescriptor] = []
    private var primaryEvaluators: [String: PrimaryEvaluator] = [:]
    private var executors: [String: ActionExecutor] = [:]
    private var expanders: [String: ActionExpander] = [:]

    public init(extensionId: String) {
        self.extensionId = extensionId
    }

    public func register(
        descriptor: SurfaceActionDescriptor,
        evaluatePrimary: PrimaryEvaluator? = nil,
        execute: @escaping ActionExecutor,
        expand: ActionExpander? = nil
    ) {
        var tagged = descriptor
        tagged.sourceExtensionId = extensionId
        let key = tagged.actionId ?? tagged.id
        descriptors.removeAll { ($0.actionId ?? $0.id) == key }
        descriptors.append(tagged)
        if let evaluatePrimary {
            primaryEvaluators[key] = evaluatePrimary
        }
        executors[key] = execute
        if let expand {
            expanders[key] = expand
        }
    }

    public func registeredDescriptors() -> [SurfaceActionDescriptor] {
        descriptors
    }

    public func handle(_ request: TooltipExtensionIPCRequest) async -> TooltipExtensionIPCResponse {
        switch request {
        case .registerDescriptors:
            return .registered(count: descriptors.count)
        case .evaluatePrimaryTooltip(_, let context):
            var best: PrimaryTooltipMatch?
            for descriptor in descriptors {
                let key = descriptor.actionId ?? descriptor.id
                if let evaluator = primaryEvaluators[key],
                   let match = await evaluator(context) {
                    if let currentBest = best {
                        if match.priority > currentBest.priority {
                            best = match
                        }
                    } else {
                        best = match
                    }
                }
            }
            return .primaryMatch(best)
        case .executeAction(_, let context):
            guard let executor = executors[context.actionId] else {
                return .error("Unknown tooltip actionId: \(context.actionId)")
            }
            let outcome = await executor(context)
            return .outcome(outcome)
        case .expandAction(_, let context):
            if let expander = expanders[context.actionId],
               let expanded = await expander(context) {
                return .expanded(expanded)
            }
            if let executor = executors[context.actionId] {
                let outcome = await executor(context)
                if case .expand(let content) = outcome {
                    return .expanded(content)
                }
                return .outcome(outcome)
            }
            return .error("No expander registered for actionId: \(context.actionId)")
        }
    }

    /// JSON-line helper for cross-language stdin/stdout or HTTP bridge invocations.
    public func handleJSON(_ requestData: Data) async -> Data {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        do {
            let request = try decoder.decode(TooltipExtensionIPCRequest.self, from: requestData)
            let response = await handle(request)
            return try encoder.encode(response)
        } catch {
            let fallback = TooltipExtensionIPCResponse.error("Invalid IPC request: \(error.localizedDescription)")
            return (try? encoder.encode(fallback)) ?? Data("{\"error\":\"encoding_failure\"}".utf8)
        }
    }
}
