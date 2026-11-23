import Foundation

public extension ExtensionSDUINode {
    var nodeTypeName: String {
        switch self {
        case .text: return "text"
        case .button: return "button"
        case .image: return "image"
        case .container: return "container"
        case .slider: return "slider"
        case .form: return "form"
        case .waveform: return "waveform"
        case .section: return "section"
        case .extensionHeader: return "extension_header"
        case .disclosureGroup: return "disclosure_group"
        case .callout: return "callout"
        case .divider: return "divider"
        case .spacer: return "spacer"
        case .badge: return "badge"
        case .infoPopover: return "info_popover"
        case .ratingScale: return "rating_scale"
        case .metricRow: return "metric_row"
        case .listRow: return "list_row"
        case .toggle: return "toggle"
        case .segmentedControl: return "segmented_control"
        case .picker: return "picker"
        case .stepper: return "stepper"
        case .labeledSlider: return "labeled_slider"
        case .textInput: return "text_input"
        case .shortcutRecorder: return "shortcut_recorder"
        case .chipSelector: return "chip_selector"
        case .colorPicker: return "color_picker"
        case .filePicker: return "file_picker"
        case .buttonGroup: return "button_group"
        case .progress: return "progress"
        case .logViewer: return "log_viewer"
        case .navigationLink: return "navigation_link"
        case .aiModelCard: return "ai_model_card"
        case .aiProviderPicker: return "ai_provider_picker"
        case .calendarBadge: return "calendar_badge"
        case .calendarEventBanner: return "calendar_event_banner"
        case .calendarMonthAgenda: return "calendar_month_agenda"
        }
    }

    var directChildNodes: [ExtensionSDUINode] {
        switch self {
        case .container(_, _, _, _, let children),
             .section(_, _, _, _, let children),
             .disclosureGroup(_, _, _, _, _, _, _, _, _, _, let children):
            return children
        case .infoPopover(_, _, _, _, let content):
            return content
        case .metricRow(_, _, _, _, _, _, let trailingNodes):
            return trailingNodes
        case .listRow(_, _, _, _, _, let leading, let trailing, _):
            return leading + trailing
        case .navigationLink(_, _, _, _, _, _, _, let destinationNodes, _, _):
            return destinationNodes
        case .segmentedControl(_, _, _, _, let options, _, _, _):
            return options.flatMap { $0.popoverNodes ?? [] }
        default:
            return []
        }
    }

    var allDescendantsCount: Int {
        var count = 1
        for child in directChildNodes {
            count += child.allDescendantsCount
        }
        return count
    }

    func collectNodeTypes() -> [String] {
        var types = [nodeTypeName]
        for child in directChildNodes {
            types.append(contentsOf: child.collectNodeTypes())
        }
        return types
    }

    func collectSectionTitles() -> [String] {
        var titles: [String] = []
        if case .section(_, let title, _, _, _) = self, let title, !title.isEmpty {
            titles.append(title)
        }
        for child in directChildNodes {
            titles.append(contentsOf: child.collectSectionTitles())
        }
        return titles
    }

    var actionIdentifier: String? {
        switch self {
        case .button(_, _, _, let actionId, _),
             .extensionHeader(_, _, _, _, _, _, let actionId, _),
             .toggle(_, _, _, _, _, let actionId, _, _),
             .segmentedControl(_, _, _, _, _, let actionId, _, _),
             .picker(_, _, _, _, _, _, _, let actionId, _, _),
             .stepper(_, _, _, _, _, _, _, _, _, let actionId, _),
             .labeledSlider(_, _, _, _, _, _, _, _, _, _, let actionId, _, _),
             .textInput(_, _, _, _, _, _, _, let actionId, _, _),
             .shortcutRecorder(_, _, _, _, let actionId, _, _, _),
             .chipSelector(_, _, _, _, _, let actionId),
             .colorPicker(_, _, _, let actionId, _),
             .filePicker(_, _, _, _, _, let actionId, _, _),
             .aiProviderPicker(_, _, _, _, _, _, _, let actionId):
            return actionId
        case .slider(_, _, _, _, _, let actionId),
             .callout(_, _, _, _, _, _, let actionId),
             .listRow(_, _, _, _, _, _, _, let actionId),
             .disclosureGroup(_, _, _, _, _, _, _, _, _, let actionId, _):
            return actionId
        case .form(_, let submitActionId, _, _):
            return submitActionId
        default:
            return nil
        }
    }

    func findNode(id targetId: String) -> ExtensionSDUINode? {
        if id == targetId { return self }
        for child in directChildNodes {
            if let match = child.findNode(id: targetId) {
                return match
            }
        }
        return nil
    }
}
