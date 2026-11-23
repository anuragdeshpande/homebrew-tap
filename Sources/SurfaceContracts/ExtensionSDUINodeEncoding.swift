import Foundation

extension ExtensionSDUINode: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ExtensionSDUINodeCodingKey.self)
        try container.encode(id, forKey: .id)

        if try encodeCoreNode(into: &container) { return }
        if try encodeLayoutAndDisplayNode(into: &container) { return }
        if try encodeControlNode(into: &container) { return }
        try encodeHostSlotNode(into: &container)
    }
}

private extension ExtensionSDUINode {
    typealias EncodeBox = KeyedEncodingContainer<ExtensionSDUINodeCodingKey>

    func encodeCoreNode(into c: inout EncodeBox) throws -> Bool {
        switch self {
        case .text(_, let content, let style, let bold):
            try c.encode("text", forKey: .type)
            try c.encode(content, forKey: .content)
            try c.encode(style, forKey: .style)
            try c.encode(bold, forKey: .bold)
        case .button(_, let title, let icon, let actionId, let style):
            try c.encode("button", forKey: .type)
            try c.encodeIfPresent(title, forKey: .title)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encode(actionId, forKey: .actionId)
            try c.encode(style, forKey: .style)
        case .image(_, let source, let width, let height, let cornerRadius):
            try c.encode("image", forKey: .type)
            try c.encode(source, forKey: .source)
            try c.encodeIfPresent(width, forKey: .width)
            try c.encodeIfPresent(height, forKey: .height)
            try c.encode(cornerRadius, forKey: .cornerRadius)
        case .container(_, let axis, let alignment, let spacing, let children):
            try c.encode("container", forKey: .type)
            try c.encode(axis, forKey: .axis)
            try c.encode(alignment, forKey: .alignment)
            try c.encode(spacing, forKey: .spacing)
            try c.encode(children, forKey: .children)
        case .slider(_, let value, let min, let max, let step, let actionId):
            try c.encode("slider", forKey: .type)
            try c.encode(value, forKey: .value)
            try c.encode(min, forKey: .min)
            try c.encode(max, forKey: .max)
            try c.encodeIfPresent(step, forKey: .step)
            try c.encodeIfPresent(actionId, forKey: .actionId)
        case .form(_, let submitActionId, let submitButtonTitle, let fields):
            try c.encode("form", forKey: .type)
            try c.encode(submitActionId, forKey: .submitActionId)
            try c.encode(submitButtonTitle, forKey: .submitButtonTitle)
            try c.encode(fields, forKey: .fields)
        case .waveform(_, let bars, let colorMode, let barWidth, let barSpacing, let cornerRadius, let animated):
            try c.encode("waveform", forKey: .type)
            try c.encode(bars, forKey: .bars)
            try c.encode(colorMode, forKey: .colorMode)
            try c.encodeIfPresent(barWidth, forKey: .barWidth)
            try c.encode(barSpacing, forKey: .barSpacing)
            try c.encode(cornerRadius, forKey: .cornerRadius)
            try c.encode(animated, forKey: .animated)
        default:
            return false
        }
        return true
    }

    func encodeLayoutAndDisplayNode(into c: inout EncodeBox) throws -> Bool {
        switch self {
        case .section(_, let title, let subtitle, let footer, let children):
            try c.encode("section", forKey: .type)
            try c.encodeIfPresent(title, forKey: .title)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(footer, forKey: .footer)
            try c.encode(children, forKey: .children)
        case .extensionHeader(_, let title, let subtitle, let iconName, let tintColor, let isEnabled, let actionId, let perms):
            try c.encode("extension_header", forKey: .type)
            try c.encode(title, forKey: .title)
            try c.encode(subtitle, forKey: .subtitle)
            try c.encode(iconName, forKey: .iconName)
            try c.encode(tintColor, forKey: .tintColor)
            try c.encode(isEnabled, forKey: .isEnabled)
            try c.encode(actionId, forKey: .actionId)
            try c.encode(perms, forKey: .requiredPermissions)
        case .disclosureGroup(_, let title, let subtitle, let icon, let tintColor, let badgeText, let isExpanded, let toggleValue, let toggleActionId, let actionId, let children):
            try c.encode("disclosure_group", forKey: .type)
            try c.encode(title, forKey: .title)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encodeIfPresent(tintColor, forKey: .tintColor)
            try c.encodeIfPresent(badgeText, forKey: .badgeText)
            try c.encode(isExpanded, forKey: .isExpanded)
            try c.encodeIfPresent(toggleValue, forKey: .toggleValue)
            try c.encodeIfPresent(toggleActionId, forKey: .toggleActionId)
            try c.encodeIfPresent(actionId, forKey: .actionId)
            try c.encode(children, forKey: .children)
        case .callout(_, let title, let message, let icon, let tone, let actionTitle, let actionId):
            try c.encode("callout", forKey: .type)
            try c.encodeIfPresent(title, forKey: .title)
            try c.encode(message, forKey: .message)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encode(tone, forKey: .tone)
            try c.encodeIfPresent(actionTitle, forKey: .actionTitle)
            try c.encodeIfPresent(actionId, forKey: .actionId)
        case .divider(_, let style):
            try c.encode("divider", forKey: .type)
            try c.encode(style, forKey: .style)
        case .spacer(_, let minLength):
            try c.encode("spacer", forKey: .type)
            try c.encodeIfPresent(minLength, forKey: .minLength)
        case .badge(_, let label, let icon, let tone):
            try c.encode("badge", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encode(tone, forKey: .tone)
        case .infoPopover(_, let title, let message, let icon, let content):
            try c.encode("info_popover", forKey: .type)
            try c.encodeIfPresent(title, forKey: .title)
            try c.encodeIfPresent(message, forKey: .message)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encode(content, forKey: .children)
        case .ratingScale(_, let label, let value, let maxValue, let filledSymbol, let emptySymbol, let tone):
            try c.encode("rating_scale", forKey: .type)
            try c.encodeIfPresent(label, forKey: .label)
            try c.encode(value, forKey: .value)
            try c.encode(maxValue, forKey: .maxValue)
            try c.encode(filledSymbol, forKey: .filledSymbol)
            try c.encode(emptySymbol, forKey: .emptySymbol)
            try c.encode(tone, forKey: .tone)
        case .metricRow(_, let label, let valueText, let badgeText, let icon, let tone, let trailingNodes):
            try c.encode("metric_row", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(valueText, forKey: .valueText)
            try c.encodeIfPresent(badgeText, forKey: .badgeText)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encodeIfPresent(tone, forKey: .tone)
            try c.encode(trailingNodes, forKey: .trailingNodes)
        case .listRow(_, let title, let subtitle, let icon, let tintColor, let leading, let trailing, let actionId):
            try c.encode("list_row", forKey: .type)
            try c.encode(title, forKey: .title)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encodeIfPresent(tintColor, forKey: .tintColor)
            try c.encode(leading, forKey: .leading)
            try c.encode(trailing, forKey: .trailing)
            try c.encodeIfPresent(actionId, forKey: .actionId)
        default:
            return false
        }
        return true
    }

    func encodeControlNode(into c: inout EncodeBox) throws -> Bool {
        switch self {
        case .toggle(_, let label, let subtitle, let icon, let isOn, let actionId, let infoText, let isDisabled):
            try c.encode("toggle", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encode(isOn, forKey: .isOn)
            try c.encode(actionId, forKey: .actionId)
            try c.encodeIfPresent(infoText, forKey: .infoText)
            if isDisabled { try c.encode(isDisabled, forKey: .isDisabled) }
        case .segmentedControl(_, let label, let subtitle, let selectedId, let options, let actionId, let infoText, let isDisabled):
            try c.encode("segmented_control", forKey: .type)
            try c.encodeIfPresent(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encode(selectedId, forKey: .selectedId)
            try c.encode(options, forKey: .options)
            try c.encode(actionId, forKey: .actionId)
            try c.encodeIfPresent(infoText, forKey: .infoText)
            if isDisabled { try c.encode(isDisabled, forKey: .isDisabled) }
        case .picker(_, let label, let subtitle, let icon, let selectedId, let options, let pickerStyle, let actionId, let infoText, let isDisabled):
            try c.encode("picker", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encode(selectedId, forKey: .selectedId)
            try c.encode(options, forKey: .options)
            try c.encode(pickerStyle, forKey: .pickerStyle)
            try c.encode(actionId, forKey: .actionId)
            try c.encodeIfPresent(infoText, forKey: .infoText)
            if isDisabled { try c.encode(isDisabled, forKey: .isDisabled) }
        case .stepper(_, let label, let subtitle, let value, let min, let max, let step, let unit, let precision, let actionId, let isDisabled):
            try c.encode("stepper", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encode(value, forKey: .value)
            try c.encode(min, forKey: .min)
            try c.encode(max, forKey: .max)
            try c.encode(step, forKey: .step)
            try c.encodeIfPresent(unit, forKey: .unit)
            try c.encode(precision, forKey: .precision)
            try c.encode(actionId, forKey: .actionId)
            if isDisabled { try c.encode(isDisabled, forKey: .isDisabled) }
        case .labeledSlider(_, let label, let subtitle, let icon, let value, let min, let max, let step, let unit, let precision, let actionId, let infoText, let isDisabled):
            try c.encode("labeled_slider", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encode(value, forKey: .value)
            try c.encode(min, forKey: .min)
            try c.encode(max, forKey: .max)
            try c.encodeIfPresent(step, forKey: .step)
            try c.encodeIfPresent(unit, forKey: .unit)
            try c.encode(precision, forKey: .precision)
            try c.encode(actionId, forKey: .actionId)
            try c.encodeIfPresent(infoText, forKey: .infoText)
            if isDisabled { try c.encode(isDisabled, forKey: .isDisabled) }
        case .textInput(_, let label, let subtitle, let text, let placeholder, let multiline, let minLines, let actionId, let triggerOnChange, let isDisabled):
            try c.encode("text_input", forKey: .type)
            try c.encodeIfPresent(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encode(text, forKey: .text)
            try c.encodeIfPresent(placeholder, forKey: .placeholder)
            try c.encode(multiline, forKey: .multiline)
            try c.encode(minLines, forKey: .minLines)
            try c.encode(actionId, forKey: .actionId)
            try c.encode(triggerOnChange, forKey: .triggerOnChange)
            if isDisabled { try c.encode(isDisabled, forKey: .isDisabled) }
        case .shortcutRecorder(_, let label, let subtitle, let shortcut, let actionId, let allowDoubleTap, let allowClear, let infoText):
            try c.encode("shortcut_recorder", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(shortcut, forKey: .shortcut)
            try c.encode(actionId, forKey: .actionId)
            try c.encode(allowDoubleTap, forKey: .allowDoubleTap)
            try c.encode(allowClear, forKey: .allowClear)
            try c.encodeIfPresent(infoText, forKey: .infoText)
        case .chipSelector(_, let label, let options, let selectedIds, let multiSelect, let actionId):
            try c.encode("chip_selector", forKey: .type)
            try c.encodeIfPresent(label, forKey: .label)
            try c.encode(options, forKey: .options)
            try c.encode(selectedIds, forKey: .selectedIds)
            try c.encode(multiSelect, forKey: .multiSelect)
            try c.encode(actionId, forKey: .actionId)
        case .colorPicker(_, let label, let hexColor, let actionId, let supportsOpacity):
            try c.encode("color_picker", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encode(hexColor, forKey: .hexColor)
            try c.encode(actionId, forKey: .actionId)
            try c.encode(supportsOpacity, forKey: .supportsOpacity)
        case .filePicker(_, let label, let subtitle, let path, let placeholder, let actionId, let allowedExtensions, let selectDirectories):
            try c.encode("file_picker", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(path, forKey: .path)
            try c.encodeIfPresent(placeholder, forKey: .placeholder)
            try c.encode(actionId, forKey: .actionId)
            try c.encode(allowedExtensions, forKey: .allowedExtensions)
            try c.encode(selectDirectories, forKey: .selectDirectories)
        case .buttonGroup(_, let buttons, let spacing, let alignment):
            try c.encode("button_group", forKey: .type)
            try c.encode(buttons, forKey: .buttons)
            try c.encode(spacing, forKey: .spacing)
            try c.encode(alignment, forKey: .alignment)
        case .progress(_, let label, let value, let total, let subtitle, let tone):
            try c.encode("progress", forKey: .type)
            try c.encodeIfPresent(label, forKey: .label)
            try c.encodeIfPresent(value, forKey: .value)
            try c.encodeIfPresent(total, forKey: .total)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encode(tone, forKey: .tone)
        case .logViewer(_, let title, let lines, let maxHeight, let monospaced):
            try c.encode("log_viewer", forKey: .type)
            try c.encodeIfPresent(title, forKey: .title)
            try c.encode(lines, forKey: .lines)
            try c.encode(maxHeight, forKey: .maxHeight)
            try c.encode(monospaced, forKey: .monospaced)
        case .navigationLink(_, let title, let subtitle, let icon, let tintColor, let badgeText, let destinationTitle, let destinationNodes, let toggleValue, let toggleActionId):
            try c.encode("navigation_link", forKey: .type)
            try c.encode(title, forKey: .title)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(icon, forKey: .icon)
            try c.encodeIfPresent(tintColor, forKey: .tintColor)
            try c.encodeIfPresent(badgeText, forKey: .badgeText)
            try c.encode(destinationTitle, forKey: .destinationTitle)
            try c.encode(destinationNodes, forKey: .destinationNodes)
            try c.encodeIfPresent(toggleValue, forKey: .toggleValue)
            try c.encodeIfPresent(toggleActionId, forKey: .toggleActionId)
        default:
            return false
        }
        return true
    }

    func encodeHostSlotNode(into c: inout EncodeBox) throws {
        switch self {
        case .aiModelCard(_, let modelId, let title, let subtitle, let showDangerZone, let showLogs):
            try c.encode("ai_model_card", forKey: .type)
            try c.encode(modelId, forKey: .modelId)
            try c.encodeIfPresent(title, forKey: .title)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encode(showDangerZone, forKey: .showDangerZone)
            try c.encode(showLogs, forKey: .showLogs)
        case .aiProviderPicker(_, let label, let subtitle, let scope, let selectedProviderId, let selectedModelId, let allowSystemDefault, let actionId):
            try c.encode("ai_provider_picker", forKey: .type)
            try c.encode(label, forKey: .label)
            try c.encodeIfPresent(subtitle, forKey: .subtitle)
            try c.encode(scope, forKey: .scope)
            try c.encodeIfPresent(selectedProviderId, forKey: .selectedProviderId)
            try c.encodeIfPresent(selectedModelId, forKey: .selectedModelId)
            try c.encode(allowSystemDefault, forKey: .allowSystemDefault)
            try c.encode(actionId, forKey: .actionId)
        case .calendarBadge(_, let payload):
            try c.encode("calendar_badge", forKey: .type)
            try c.encode(payload, forKey: .payload)
        case .calendarEventBanner(_, let payload):
            try c.encode("calendar_event_banner", forKey: .type)
            try c.encode(payload, forKey: .payload)
        case .calendarMonthAgenda(_, let payload):
            try c.encode("calendar_month_agenda", forKey: .type)
            try c.encode(payload, forKey: .payload)
        default:
            break
        }
    }
}
