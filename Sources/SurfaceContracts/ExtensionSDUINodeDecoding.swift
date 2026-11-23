import Foundation

internal enum ExtensionSDUINodeCodingKey: String, CodingKey {
    case type, id
    case content, text, style, bold
    case title, subtitle, footer, message, label, unit
    case icon, iconName = "icon_name", camelIconName = "iconName"
    case actionId = "action_id", camelActionId = "actionId"
    case toggleActionId = "toggle_action_id", camelToggleActionId = "toggleActionId"
    case toggleValue = "toggle_value", camelToggleValue = "toggleValue"
    case actionTitle = "action_title", camelActionTitle = "actionTitle"
    case source, width, height, cornerRadius = "corner_radius"
    case axis, alignment, spacing, minLength = "min_length", children
    case value, min, max, step, precision, total, maxValue = "max_value"
    case submitActionId = "submit_action_id", submitButtonTitle = "submit_button_title", fields
    case bars, colorMode = "color_mode", barWidth = "bar_width", barSpacing = "bar_spacing", animated
    case tintColor = "tint_color", camelTintColor = "tintColor"
    case isEnabled = "is_enabled", camelIsEnabled = "isEnabled"
    case requiredPermissions = "required_permissions", camelRequiredPermissions = "requiredPermissions"
    case badgeText = "badge_text", camelBadgeText = "badgeText"
    case isExpanded = "is_expanded", camelIsExpanded = "isExpanded"
    case tone
    case filledSymbol = "filled_symbol", emptySymbol = "empty_symbol"
    case valueText = "value_text", trailingNodes = "trailing_nodes"
    case leading, trailing
    case isOn = "is_on", camelIsOn = "isOn"
    case infoText = "info_text", camelInfoText = "infoText"
    case isDisabled = "is_disabled", camelIsDisabled = "isDisabled"
    case selectedId = "selected_id", camelSelectedId = "selectedId"
    case options
    case pickerStyle = "picker_style", camelPickerStyle = "pickerStyle"
    case placeholder, multiline, minLines = "min_lines"
    case triggerOnChange = "trigger_on_change"
    case shortcut
    case allowDoubleTap = "allow_double_tap", allowClear = "allow_clear"
    case selectedIds = "selected_ids", multiSelect = "multi_select"
    case hexColor = "hex_color", supportsOpacity = "supports_opacity"
    case path, allowedExtensions = "allowed_extensions", selectDirectories = "select_directories"
    case buttons, lines, maxHeight = "max_height", monospaced
    case destinationTitle = "destination_title", destinationNodes = "destination_nodes"
    case modelId = "model_id", showDangerZone = "show_danger_zone", showLogs = "show_logs"
    case scope, selectedProviderId = "selected_provider_id", selectedModelId = "selected_model_id"
    case allowSystemDefault = "allow_system_default"
    case payload
}

extension ExtensionSDUINode: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ExtensionSDUINodeCodingKey.self)
        let type = try container.decode(String.self, forKey: .type)
        let id = try container.decode(String.self, forKey: .id)

        if let node = try Self.decodeCoreNode(type: type, id: id, from: container) {
            self = node
            return
        }
        if let node = try Self.decodeLayoutAndDisplayNode(type: type, id: id, from: container) {
            self = node
            return
        }
        if let node = try Self.decodeControlNode(type: type, id: id, from: container) {
            self = node
            return
        }
        if let node = try Self.decodeHostSlotNode(type: type, id: id, from: container) {
            self = node
            return
        }

        throw DecodingError.dataCorruptedError(
            forKey: .type,
            in: container,
            debugDescription: "Unknown SDUI type: \(type)"
        )
    }
}

private extension ExtensionSDUINode {
    typealias DecodeBox = KeyedDecodingContainer<ExtensionSDUINodeCodingKey>
    typealias K = ExtensionSDUINodeCodingKey

    static func decodeCoreNode(type: String, id: String, from c: DecodeBox) throws -> ExtensionSDUINode? {
        switch type {
        case "text":
            let content: String = try c.decodeIfPresent(String.self, forKey: .content)
                ?? c.decodeIfPresent(String.self, forKey: .text)
                ?? ""
            let style = try c.decodeIfPresent(ExtensionSDUITextStyle.self, forKey: .style) ?? .body
            let bold = try c.decodeIfPresent(Bool.self, forKey: .bold) ?? false
            return .text(id: id, content: content, style: style, bold: bold)

        case "button":
            let title = try c.decodeIfPresent(String.self, forKey: .title)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let style = try c.decodeIfPresent(ExtensionSDUIButtonStyle.self, forKey: .style) ?? .default
            return .button(id: id, title: title, icon: icon, actionId: actionId, style: style)

        case "image":
            let source = try c.decode(ExtensionSDUIImageSource.self, forKey: .source)
            let width = try c.decodeIfPresent(Double.self, forKey: .width)
            let height = try c.decodeIfPresent(Double.self, forKey: .height)
            let cornerRadius = try c.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 0.0
            return .image(id: id, source: source, width: width, height: height, cornerRadius: cornerRadius)

        case "container":
            let axis = try c.decodeIfPresent(ExtensionSDUIAxis.self, forKey: .axis) ?? .vertical
            let alignment = try c.decodeIfPresent(ExtensionSDUIAlignment.self, forKey: .alignment) ?? .leading
            let spacing = try c.decodeIfPresent(Double.self, forKey: .spacing) ?? 8.0
            let children = try c.decodeIfPresent([ExtensionSDUINode].self, forKey: .children) ?? []
            return .container(id: id, axis: axis, alignment: alignment, spacing: spacing, children: children)

        case "slider":
            let value = try c.decodeIfPresent(Double.self, forKey: .value) ?? 0.0
            let min = try c.decodeIfPresent(Double.self, forKey: .min) ?? 0.0
            let max = try c.decodeIfPresent(Double.self, forKey: .max) ?? 1.0
            let step = try c.decodeIfPresent(Double.self, forKey: .step)
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId)
            return .slider(id: id, value: value, min: min, max: max, step: step, actionId: actionId)

        case "form":
            let submitActionId = try c.decodeIfPresent(String.self, forKey: .submitActionId) ?? "submit"
            let submitButtonTitle = try c.decodeIfPresent(String.self, forKey: .submitButtonTitle) ?? "Submit"
            let fields = try c.decodeIfPresent([ExtensionSDUIFormField].self, forKey: .fields) ?? []
            return .form(id: id, submitActionId: submitActionId, submitButtonTitle: submitButtonTitle, fields: fields)

        case "waveform":
            let bars = try c.decodeIfPresent([Double].self, forKey: .bars) ?? []
            let colorMode = try c.decodeIfPresent(ExtensionSDUIWaveformColorMode.self, forKey: .colorMode)
                ?? .solid(color: "#007AFF")
            let barWidth = try c.decodeIfPresent(Double.self, forKey: .barWidth)
            let barSpacing = try c.decodeIfPresent(Double.self, forKey: .barSpacing) ?? 2.0
            let cornerRadius = try c.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 1.5
            let animated = try c.decodeIfPresent(Bool.self, forKey: .animated) ?? true
            return .waveform(
                id: id,
                bars: bars,
                colorMode: colorMode,
                barWidth: barWidth,
                barSpacing: barSpacing,
                cornerRadius: cornerRadius,
                animated: animated
            )

        default:
            return nil
        }
    }

    static func decodeLayoutAndDisplayNode(type: String, id: String, from c: DecodeBox) throws -> ExtensionSDUINode? {
        switch type {
        case "section":
            let title = try c.decodeIfPresent(String.self, forKey: .title)
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let footer = try c.decodeIfPresent(String.self, forKey: .footer)
            let children = try c.decodeIfPresent([ExtensionSDUINode].self, forKey: .children) ?? []
            return .section(id: id, title: title, subtitle: subtitle, footer: footer, children: children)

        case "extension_header", "extensionHeader":
            let perms = try c.decodeIfPresent([ExtensionSDUIPermissionItem].self, forKey: .requiredPermissions)
                ?? c.decodeIfPresent([ExtensionSDUIPermissionItem].self, forKey: .camelRequiredPermissions)
                ?? []
            let title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
            let iconName = try decodeOptionalString(c, .iconName, .camelIconName) ?? "puzzlepiece.extension"
            let tintColor = try decodeOptionalString(c, .tintColor, .camelTintColor) ?? "#0A84FF"
            let isEnabled = try decodeBool(c, .isEnabled, .camelIsEnabled, default: true)
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? "\(id)_enabled"
            return .extensionHeader(
                id: id,
                title: title,
                subtitle: subtitle,
                iconName: iconName,
                tintColor: tintColor,
                isEnabled: isEnabled,
                actionId: actionId,
                requiredPermissions: perms
            )

        case "disclosure_group", "disclosureGroup":
            let title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let tintColor = try decodeOptionalString(c, .tintColor, .camelTintColor)
            let badgeText = try decodeOptionalString(c, .badgeText, .camelBadgeText)
            let isExpanded = try decodeBool(c, .isExpanded, .camelIsExpanded, default: false)
            let toggleValue = try c.decodeIfPresent(Bool.self, forKey: .toggleValue)
                ?? c.decodeIfPresent(Bool.self, forKey: .camelToggleValue)
            let toggleActionId = try decodeOptionalString(c, .toggleActionId, .camelToggleActionId)
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId)
            let children = try c.decodeIfPresent([ExtensionSDUINode].self, forKey: .children) ?? []
            return .disclosureGroup(
                id: id,
                title: title,
                subtitle: subtitle,
                icon: icon,
                tintColor: tintColor,
                badgeText: badgeText,
                isExpanded: isExpanded,
                toggleValue: toggleValue,
                toggleActionId: toggleActionId,
                actionId: actionId,
                children: children
            )

        case "callout":
            let title = try c.decodeIfPresent(String.self, forKey: .title)
            let message = try c.decodeIfPresent(String.self, forKey: .message) ?? ""
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let tone = try c.decodeIfPresent(ExtensionSDUITone.self, forKey: .tone) ?? .neutral
            let actionTitle = try decodeOptionalString(c, .actionTitle, .camelActionTitle)
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId)
            return .callout(id: id, title: title, message: message, icon: icon, tone: tone, actionTitle: actionTitle, actionId: actionId)

        case "divider":
            let style = try c.decodeIfPresent(ExtensionSDUIDividerStyle.self, forKey: .style) ?? .fullWidth
            return .divider(id: id, style: style)

        case "spacer":
            let minLength = try c.decodeIfPresent(Double.self, forKey: .minLength)
            return .spacer(id: id, minLength: minLength)

        case "badge":
            let label = try c.decodeIfPresent(String.self, forKey: .label)
                ?? c.decodeIfPresent(String.self, forKey: .text)
                ?? ""
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let tone = try c.decodeIfPresent(ExtensionSDUITone.self, forKey: .tone) ?? .neutral
            return .badge(id: id, label: label, icon: icon, tone: tone)

        case "info_popover", "infoPopover":
            let title = try c.decodeIfPresent(String.self, forKey: .title)
            let message = try c.decodeIfPresent(String.self, forKey: .message)
                ?? c.decodeIfPresent(String.self, forKey: .text)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let content = try c.decodeIfPresent([ExtensionSDUINode].self, forKey: .children) ?? []
            return .infoPopover(id: id, title: title, message: message, icon: icon, content: content)

        case "rating_scale", "ratingScale":
            let label = try c.decodeIfPresent(String.self, forKey: .label)
            let value = try c.decodeIfPresent(Int.self, forKey: .value) ?? 0
            let maxValue = try c.decodeIfPresent(Int.self, forKey: .maxValue) ?? 5
            let filledSymbol = try c.decodeIfPresent(String.self, forKey: .filledSymbol) ?? "circle.fill"
            let emptySymbol = try c.decodeIfPresent(String.self, forKey: .emptySymbol) ?? "circle"
            let tone = try c.decodeIfPresent(ExtensionSDUITone.self, forKey: .tone) ?? .accent
            return .ratingScale(id: id, label: label, value: value, maxValue: maxValue, filledSymbol: filledSymbol, emptySymbol: emptySymbol, tone: tone)

        case "metric_row", "metricRow":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
            let valueText = try c.decodeIfPresent(String.self, forKey: .valueText)
            let badgeText = try decodeOptionalString(c, .badgeText, .camelBadgeText)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let tone = try c.decodeIfPresent(ExtensionSDUITone.self, forKey: .tone)
            let trailingNodes = try c.decodeIfPresent([ExtensionSDUINode].self, forKey: .trailingNodes) ?? []
            return .metricRow(id: id, label: label, valueText: valueText, badgeText: badgeText, icon: icon, tone: tone, trailingNodes: trailingNodes)

        case "list_row", "listRow":
            let title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let tintColor = try decodeOptionalString(c, .tintColor, .camelTintColor)
            let leading = try c.decodeIfPresent([ExtensionSDUINode].self, forKey: .leading) ?? []
            let trailing = try c.decodeIfPresent([ExtensionSDUINode].self, forKey: .trailing) ?? []
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId)
            return .listRow(id: id, title: title, subtitle: subtitle, icon: icon, tintColor: tintColor, leading: leading, trailing: trailing, actionId: actionId)

        default:
            return nil
        }
    }

    static func decodeControlNode(type: String, id: String, from c: DecodeBox) throws -> ExtensionSDUINode? {
        switch type {
        case "toggle":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let isOn = try decodeBool(c, .isOn, .camelIsOn, default: false)
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let infoText = try decodeOptionalString(c, .infoText, .camelInfoText)
            let isDisabled = try decodeBool(c, .isDisabled, .camelIsDisabled, default: false)
            return .toggle(id: id, label: label, subtitle: subtitle, icon: icon, isOn: isOn, actionId: actionId, infoText: infoText, isDisabled: isDisabled)

        case "segmented_control", "segmentedControl":
            let label = try c.decodeIfPresent(String.self, forKey: .label)
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let selectedId = try decodeOptionalString(c, .selectedId, .camelSelectedId) ?? ""
            let options = try c.decodeIfPresent([ExtensionSDUISegmentedOption].self, forKey: .options) ?? []
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let infoText = try decodeOptionalString(c, .infoText, .camelInfoText)
            let isDisabled = try decodeBool(c, .isDisabled, .camelIsDisabled, default: false)
            return .segmentedControl(id: id, label: label, subtitle: subtitle, selectedId: selectedId, options: options, actionId: actionId, infoText: infoText, isDisabled: isDisabled)

        case "picker":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let selectedId = try decodeOptionalString(c, .selectedId, .camelSelectedId) ?? ""
            let options = try c.decodeIfPresent([ExtensionSDUIPickerOption].self, forKey: .options) ?? []
            let pickerStyle = try c.decodeIfPresent(ExtensionSDUIPickerStyle.self, forKey: .pickerStyle)
                ?? c.decodeIfPresent(ExtensionSDUIPickerStyle.self, forKey: .camelPickerStyle)
                ?? .menu
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let infoText = try decodeOptionalString(c, .infoText, .camelInfoText)
            let isDisabled = try decodeBool(c, .isDisabled, .camelIsDisabled, default: false)
            return .picker(id: id, label: label, subtitle: subtitle, icon: icon, selectedId: selectedId, options: options, pickerStyle: pickerStyle, actionId: actionId, infoText: infoText, isDisabled: isDisabled)

        case "stepper":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let value = try c.decodeIfPresent(Double.self, forKey: .value) ?? 0
            let min = try c.decodeIfPresent(Double.self, forKey: .min) ?? 0
            let max = try c.decodeIfPresent(Double.self, forKey: .max) ?? 100
            let step = try c.decodeIfPresent(Double.self, forKey: .step) ?? 1
            let unit = try c.decodeIfPresent(String.self, forKey: .unit)
            let precision = try c.decodeIfPresent(Int.self, forKey: .precision) ?? 0
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let isDisabled = try decodeBool(c, .isDisabled, .camelIsDisabled, default: false)
            return .stepper(id: id, label: label, subtitle: subtitle, value: value, min: min, max: max, step: step, unit: unit, precision: precision, actionId: actionId, isDisabled: isDisabled)

        case "labeled_slider", "labeledSlider":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let value = try c.decodeIfPresent(Double.self, forKey: .value) ?? 0
            let min = try c.decodeIfPresent(Double.self, forKey: .min) ?? 0
            let max = try c.decodeIfPresent(Double.self, forKey: .max) ?? 1
            let step = try c.decodeIfPresent(Double.self, forKey: .step)
            let unit = try c.decodeIfPresent(String.self, forKey: .unit)
            let precision = try c.decodeIfPresent(Int.self, forKey: .precision) ?? 1
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let infoText = try decodeOptionalString(c, .infoText, .camelInfoText)
            let isDisabled = try decodeBool(c, .isDisabled, .camelIsDisabled, default: false)
            return .labeledSlider(id: id, label: label, subtitle: subtitle, icon: icon, value: value, min: min, max: max, step: step, unit: unit, precision: precision, actionId: actionId, infoText: infoText, isDisabled: isDisabled)

        case "text_input", "textInput":
            let label = try c.decodeIfPresent(String.self, forKey: .label)
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let text = try c.decodeIfPresent(String.self, forKey: .text)
                ?? c.decodeIfPresent(String.self, forKey: .value)
                ?? ""
            let placeholder = try c.decodeIfPresent(String.self, forKey: .placeholder)
            let multiline = try c.decodeIfPresent(Bool.self, forKey: .multiline) ?? false
            let minLines = try c.decodeIfPresent(Int.self, forKey: .minLines) ?? 3
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let triggerOnChange = try c.decodeIfPresent(Bool.self, forKey: .triggerOnChange) ?? false
            let isDisabled = try decodeBool(c, .isDisabled, .camelIsDisabled, default: false)
            return .textInput(id: id, label: label, subtitle: subtitle, text: text, placeholder: placeholder, multiline: multiline, minLines: minLines, actionId: actionId, triggerOnChange: triggerOnChange, isDisabled: isDisabled)

        case "shortcut_recorder", "shortcutRecorder":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let shortcut = try c.decodeIfPresent(ExtensionSDUIShortcutValue.self, forKey: .shortcut)
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let allowDoubleTap = try c.decodeIfPresent(Bool.self, forKey: .allowDoubleTap) ?? true
            let allowClear = try c.decodeIfPresent(Bool.self, forKey: .allowClear) ?? true
            let infoText = try decodeOptionalString(c, .infoText, .camelInfoText)
            return .shortcutRecorder(id: id, label: label, subtitle: subtitle, shortcut: shortcut, actionId: actionId, allowDoubleTap: allowDoubleTap, allowClear: allowClear, infoText: infoText)

        case "chip_selector", "chipSelector":
            let label = try c.decodeIfPresent(String.self, forKey: .label)
            let options = try c.decodeIfPresent([ExtensionSDUIChipOption].self, forKey: .options) ?? []
            let selectedIds = try c.decodeIfPresent([String].self, forKey: .selectedIds) ?? []
            let multiSelect = try c.decodeIfPresent(Bool.self, forKey: .multiSelect) ?? true
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            return .chipSelector(id: id, label: label, options: options, selectedIds: selectedIds, multiSelect: multiSelect, actionId: actionId)

        case "color_picker", "colorPicker":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
            let hexColor = try c.decodeIfPresent(String.self, forKey: .hexColor) ?? "#0A84FF"
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let supportsOpacity = try c.decodeIfPresent(Bool.self, forKey: .supportsOpacity) ?? false
            return .colorPicker(id: id, label: label, hexColor: hexColor, actionId: actionId, supportsOpacity: supportsOpacity)

        case "file_picker", "filePicker":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let path = try c.decodeIfPresent(String.self, forKey: .path)
            let placeholder = try c.decodeIfPresent(String.self, forKey: .placeholder)
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            let allowedExtensions = try c.decodeIfPresent([String].self, forKey: .allowedExtensions) ?? []
            let selectDirectories = try c.decodeIfPresent(Bool.self, forKey: .selectDirectories) ?? false
            return .filePicker(id: id, label: label, subtitle: subtitle, path: path, placeholder: placeholder, actionId: actionId, allowedExtensions: allowedExtensions, selectDirectories: selectDirectories)

        case "button_group", "buttonGroup":
            let buttons = try c.decodeIfPresent([ExtensionSDUIButtonItem].self, forKey: .buttons) ?? []
            let spacing = try c.decodeIfPresent(Double.self, forKey: .spacing) ?? 8
            let alignment = try c.decodeIfPresent(ExtensionSDUIAlignment.self, forKey: .alignment) ?? .leading
            return .buttonGroup(id: id, buttons: buttons, spacing: spacing, alignment: alignment)

        case "progress":
            let label = try c.decodeIfPresent(String.self, forKey: .label)
            let value = try c.decodeIfPresent(Double.self, forKey: .value)
            let total = try c.decodeIfPresent(Double.self, forKey: .total)
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let tone = try c.decodeIfPresent(ExtensionSDUITone.self, forKey: .tone) ?? .accent
            return .progress(id: id, label: label, value: value, total: total, subtitle: subtitle, tone: tone)

        case "log_viewer", "logViewer":
            let title = try c.decodeIfPresent(String.self, forKey: .title)
            let lines = try c.decodeIfPresent([String].self, forKey: .lines) ?? []
            let maxHeight = try c.decodeIfPresent(Double.self, forKey: .maxHeight) ?? 160
            let monospaced = try c.decodeIfPresent(Bool.self, forKey: .monospaced) ?? true
            return .logViewer(id: id, title: title, lines: lines, maxHeight: maxHeight, monospaced: monospaced)

        case "navigation_link", "navigationLink":
            let title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let icon = try c.decodeIfPresent(String.self, forKey: .icon)
            let tintColor = try decodeOptionalString(c, .tintColor, .camelTintColor)
            let badgeText = try decodeOptionalString(c, .badgeText, .camelBadgeText)
            let destinationTitle = try c.decodeIfPresent(String.self, forKey: .destinationTitle) ?? title
            let destinationNodes = try c.decodeIfPresent([ExtensionSDUINode].self, forKey: .destinationNodes) ?? []
            let toggleValue = try c.decodeIfPresent(Bool.self, forKey: .toggleValue)
            let toggleActionId = try decodeOptionalString(c, .toggleActionId, .camelToggleActionId)
            return .navigationLink(
                id: id,
                title: title,
                subtitle: subtitle,
                icon: icon,
                tintColor: tintColor,
                badgeText: badgeText,
                destinationTitle: destinationTitle,
                destinationNodes: destinationNodes,
                toggleValue: toggleValue,
                toggleActionId: toggleActionId
            )

        default:
            return nil
        }
    }

    static func decodeHostSlotNode(type: String, id: String, from c: DecodeBox) throws -> ExtensionSDUINode? {
        switch type {
        case "ai_model_card", "aiModelCard":
            let modelId = try c.decode(String.self, forKey: .modelId)
            let title = try c.decodeIfPresent(String.self, forKey: .title)
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let showDangerZone = try c.decodeIfPresent(Bool.self, forKey: .showDangerZone) ?? true
            let showLogs = try c.decodeIfPresent(Bool.self, forKey: .showLogs) ?? true
            return .aiModelCard(id: id, modelId: modelId, title: title, subtitle: subtitle, showDangerZone: showDangerZone, showLogs: showLogs)

        case "ai_provider_picker", "aiProviderPicker":
            let label = try c.decodeIfPresent(String.self, forKey: .label) ?? "AI Provider"
            let subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
            let scope = try c.decodeIfPresent(ExtensionSDUIProviderScope.self, forKey: .scope) ?? .chat
            let selectedProviderId = try c.decodeIfPresent(String.self, forKey: .selectedProviderId)
            let selectedModelId = try c.decodeIfPresent(String.self, forKey: .selectedModelId)
            let allowSystemDefault = try c.decodeIfPresent(Bool.self, forKey: .allowSystemDefault) ?? true
            let actionId = try decodeOptionalString(c, .actionId, .camelActionId) ?? id
            return .aiProviderPicker(id: id, label: label, subtitle: subtitle, scope: scope, selectedProviderId: selectedProviderId, selectedModelId: selectedModelId, allowSystemDefault: allowSystemDefault, actionId: actionId)

        case "calendar_badge", "calendarBadge":
            let payload = try c.decode(ExtensionSDUICalendarBadgePayload.self, forKey: .payload)
            return .calendarBadge(id: id, payload: payload)

        case "calendar_event_banner", "calendarEventBanner":
            let payload = try c.decode(ExtensionSDUICalendarEventBannerPayload.self, forKey: .payload)
            return .calendarEventBanner(id: id, payload: payload)

        case "calendar_month_agenda", "calendarMonthAgenda":
            let payload = try c.decode(ExtensionSDUICalendarMonthAgendaPayload.self, forKey: .payload)
            return .calendarMonthAgenda(id: id, payload: payload)

        default:
            return nil
        }
    }

    static func decodeOptionalString(_ c: DecodeBox, _ primary: K, _ fallback: K) throws -> String? {
        if let value = try c.decodeIfPresent(String.self, forKey: primary) {
            return value
        }
        return try c.decodeIfPresent(String.self, forKey: fallback)
    }

    static func decodeBool(_ c: DecodeBox, _ primary: K, _ fallback: K, default defaultValue: Bool) throws -> Bool {
        if let value = try c.decodeIfPresent(Bool.self, forKey: primary) {
            return value
        }
        return try c.decodeIfPresent(Bool.self, forKey: fallback) ?? defaultValue
    }
}
