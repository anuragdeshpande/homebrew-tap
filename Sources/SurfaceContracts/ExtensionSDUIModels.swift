import Foundation

public enum ExtensionSDUIAxis: String, Codable, Sendable {
    case vertical
    case horizontal
}

public enum ExtensionSDUIAlignment: String, Codable, Sendable {
    case leading
    case center
    case trailing
}

public enum ExtensionSDUITextStyle: String, Codable, Sendable {
    case body
    case title
    case headline
    case subheadline
    case caption
    case secondary
    case monospaced
}

public enum ExtensionSDUIButtonStyle: String, Codable, Sendable {
    case `default`
    case prominent
    case iconOnly = "icon_only"
    case destructive
    case secondary
    case bordered
    case plain
}

public struct ExtensionSDUIImageSource: Codable, Equatable, Sendable {
    public let kind: String
    public let name: String?
    public let url: String?
    public let dataUrl: String?

    enum CodingKeys: String, CodingKey {
        case kind
        case name
        case url
        case dataUrl = "data_url"
    }

    public init(kind: String, name: String? = nil, url: String? = nil, dataUrl: String? = nil) {
        self.kind = kind
        self.name = name
        self.url = url
        self.dataUrl = dataUrl
    }
}

public struct ExtensionSDUIPickerOption: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: String?
    public let badge: String?
    public let isDisabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case label
        case subtitle
        case icon
        case badge
        case isDisabled = "is_disabled"
    }

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        badge: String? = nil,
        isDisabled: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.isDisabled = isDisabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        if let title = try container.decodeIfPresent(String.self, forKey: .title) {
            self.title = title
        } else {
            self.title = try container.decodeIfPresent(String.self, forKey: .label) ?? id
        }
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
        self.badge = try container.decodeIfPresent(String.self, forKey: .badge)
        self.isDisabled = try container.decodeIfPresent(Bool.self, forKey: .isDisabled) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(badge, forKey: .badge)
        if isDisabled {
            try container.encode(isDisabled, forKey: .isDisabled)
        }
    }
}

public enum ExtensionSDUIFormField: Codable, Equatable, Sendable {
    case textField(id: String, label: String, placeholder: String?, isSecure: Bool, isRequired: Bool)
    case toggle(id: String, label: String, isOn: Bool)
    case picker(id: String, label: String, options: [ExtensionSDUIPickerOption], selectedId: String)
    case datePicker(id: String, label: String, timestampSeconds: Int64?)

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case label
        case placeholder
        case isSecure = "is_secure"
        case isRequired = "is_required"
        case isOn = "is_on"
        case camelIsOn = "isOn"
        case options
        case selectedId = "selected_id"
        case timestampSeconds = "timestamp_seconds"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let id = try container.decode(String.self, forKey: .id)
        let label = try container.decode(String.self, forKey: .label)
        switch type {
        case "textField":
            let placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
            let isSecure = try container.decodeIfPresent(Bool.self, forKey: .isSecure) ?? false
            let isRequired = try container.decodeIfPresent(Bool.self, forKey: .isRequired) ?? false
            self = .textField(id: id, label: label, placeholder: placeholder, isSecure: isSecure, isRequired: isRequired)
        case "toggle":
            let isOn = try container.decodeIfPresent(Bool.self, forKey: .isOn)
                ?? container.decodeIfPresent(Bool.self, forKey: .camelIsOn)
                ?? false
            self = .toggle(id: id, label: label, isOn: isOn)
        case "picker":
            let options = try container.decodeIfPresent([ExtensionSDUIPickerOption].self, forKey: .options) ?? []
            let selectedId = try container.decodeIfPresent(String.self, forKey: .selectedId) ?? ""
            self = .picker(id: id, label: label, options: options, selectedId: selectedId)
        case "datePicker":
            let timestampSeconds = try container.decodeIfPresent(Int64.self, forKey: .timestampSeconds)
            self = .datePicker(id: id, label: label, timestampSeconds: timestampSeconds)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown field type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .textField(let id, let label, let placeholder, let isSecure, let isRequired):
            try container.encode("textField", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(label, forKey: .label)
            try container.encodeIfPresent(placeholder, forKey: .placeholder)
            try container.encode(isSecure, forKey: .isSecure)
            try container.encode(isRequired, forKey: .isRequired)
        case .toggle(let id, let label, let isOn):
            try container.encode("toggle", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(label, forKey: .label)
            try container.encode(isOn, forKey: .isOn)
        case .picker(let id, let label, let options, let selectedId):
            try container.encode("picker", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(label, forKey: .label)
            try container.encode(options, forKey: .options)
            try container.encode(selectedId, forKey: .selectedId)
        case .datePicker(let id, let label, let timestampSeconds):
            try container.encode("datePicker", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(label, forKey: .label)
            try container.encodeIfPresent(timestampSeconds, forKey: .timestampSeconds)
        }
    }
}

public enum ExtensionSDUICallSpeaker: String, Codable, Equatable, Sendable {
    case local
    case remote
    case both
    case idle
}

public enum ExtensionSDUIWaveformColorMode: Codable, Equatable, Sendable {
    case solid(color: String)
    case gradient(primaryColor: String, secondaryColor: String)
    case callSplit(
        localSpeakerColor: String,
        remoteCallerColor: String,
        activeSpeaker: ExtensionSDUICallSpeaker,
        blendInactive: Double
    )

    enum CodingKeys: String, CodingKey {
        case kind
        case color
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case localSpeakerColor = "local_speaker_color"
        case remoteCallerColor = "remote_caller_color"
        case activeSpeaker = "active_speaker"
        case blendInactive = "blend_inactive"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "solid"
        switch kind {
        case "gradient":
            let primary = try container.decodeIfPresent(String.self, forKey: .primaryColor) ?? "#38BDF8"
            let secondary = try container.decodeIfPresent(String.self, forKey: .secondaryColor) ?? "#818CF8"
            self = .gradient(primaryColor: primary, secondaryColor: secondary)
        case "call_split":
            let local = try container.decodeIfPresent(String.self, forKey: .localSpeakerColor) ?? "#34D399"
            let remote = try container.decodeIfPresent(String.self, forKey: .remoteCallerColor) ?? "#60A5FA"
            let speaker = try container.decodeIfPresent(ExtensionSDUICallSpeaker.self, forKey: .activeSpeaker) ?? .both
            let blend = try container.decodeIfPresent(Double.self, forKey: .blendInactive) ?? 0.35
            self = .callSplit(
                localSpeakerColor: local,
                remoteCallerColor: remote,
                activeSpeaker: speaker,
                blendInactive: blend
            )
        default:
            let color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#007AFF"
            self = .solid(color: color)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .solid(let color):
            try container.encode("solid", forKey: .kind)
            try container.encode(color, forKey: .color)
        case .gradient(let primaryColor, let secondaryColor):
            try container.encode("gradient", forKey: .kind)
            try container.encode(primaryColor, forKey: .primaryColor)
            try container.encode(secondaryColor, forKey: .secondaryColor)
        case .callSplit(let localSpeakerColor, let remoteCallerColor, let activeSpeaker, let blendInactive):
            try container.encode("call_split", forKey: .kind)
            try container.encode(localSpeakerColor, forKey: .localSpeakerColor)
            try container.encode(remoteCallerColor, forKey: .remoteCallerColor)
            try container.encode(activeSpeaker, forKey: .activeSpeaker)
            try container.encode(blendInactive, forKey: .blendInactive)
        }
    }
}

public indirect enum ExtensionSDUINode: Equatable, Identifiable, Sendable {
    // Existing primitives (associated value signatures preserved for backward compatibility)
    case text(id: String, content: String, style: ExtensionSDUITextStyle, bold: Bool)
    case button(id: String, title: String?, icon: String?, actionId: String, style: ExtensionSDUIButtonStyle)
    case image(id: String, source: ExtensionSDUIImageSource, width: Double?, height: Double?, cornerRadius: Double)
    case container(id: String, axis: ExtensionSDUIAxis, alignment: ExtensionSDUIAlignment, spacing: Double, children: [ExtensionSDUINode])
    case slider(id: String, value: Double, min: Double, max: Double, step: Double?, actionId: String?)
    case form(id: String, submitActionId: String, submitButtonTitle: String, fields: [ExtensionSDUIFormField])
    case waveform(
        id: String,
        bars: [Double],
        colorMode: ExtensionSDUIWaveformColorMode,
        barWidth: Double? = nil,
        barSpacing: Double,
        cornerRadius: Double,
        animated: Bool
    )

    // Layout & Structural primitives
    case section(id: String, title: String?, subtitle: String?, footer: String?, children: [ExtensionSDUINode])
    case extensionHeader(
        id: String,
        title: String,
        subtitle: String,
        iconName: String,
        tintColor: String,
        isEnabled: Bool,
        actionId: String,
        requiredPermissions: [ExtensionSDUIPermissionItem]
    )
    case disclosureGroup(
        id: String,
        title: String,
        subtitle: String?,
        icon: String?,
        tintColor: String?,
        badgeText: String?,
        isExpanded: Bool,
        toggleValue: Bool?,
        toggleActionId: String?,
        actionId: String?,
        children: [ExtensionSDUINode]
    )
    case callout(
        id: String,
        title: String?,
        message: String,
        icon: String?,
        tone: ExtensionSDUITone,
        actionTitle: String?,
        actionId: String?
    )
    case divider(id: String, style: ExtensionSDUIDividerStyle)
    case spacer(id: String, minLength: Double?)

    // Display primitives
    case badge(id: String, label: String, icon: String?, tone: ExtensionSDUITone)
    case infoPopover(id: String, title: String?, message: String?, icon: String?, content: [ExtensionSDUINode])
    case ratingScale(
        id: String,
        label: String?,
        value: Int,
        maxValue: Int,
        filledSymbol: String,
        emptySymbol: String,
        tone: ExtensionSDUITone
    )
    case metricRow(
        id: String,
        label: String,
        valueText: String?,
        badgeText: String?,
        icon: String?,
        tone: ExtensionSDUITone?,
        trailingNodes: [ExtensionSDUINode]
    )
    case listRow(
        id: String,
        title: String,
        subtitle: String?,
        icon: String?,
        tintColor: String?,
        leading: [ExtensionSDUINode],
        trailing: [ExtensionSDUINode],
        actionId: String?
    )

    // Immediate interactive controls
    case toggle(
        id: String,
        label: String,
        subtitle: String?,
        icon: String?,
        isOn: Bool,
        actionId: String,
        infoText: String?,
        isDisabled: Bool
    )
    case segmentedControl(
        id: String,
        label: String?,
        subtitle: String?,
        selectedId: String,
        options: [ExtensionSDUISegmentedOption],
        actionId: String,
        infoText: String?,
        isDisabled: Bool
    )
    case picker(
        id: String,
        label: String,
        subtitle: String?,
        icon: String?,
        selectedId: String,
        options: [ExtensionSDUIPickerOption],
        pickerStyle: ExtensionSDUIPickerStyle,
        actionId: String,
        infoText: String?,
        isDisabled: Bool
    )
    case stepper(
        id: String,
        label: String,
        subtitle: String?,
        value: Double,
        min: Double,
        max: Double,
        step: Double,
        unit: String?,
        precision: Int,
        actionId: String,
        isDisabled: Bool
    )
    case labeledSlider(
        id: String,
        label: String,
        subtitle: String?,
        icon: String?,
        value: Double,
        min: Double,
        max: Double,
        step: Double?,
        unit: String?,
        precision: Int,
        actionId: String,
        infoText: String?,
        isDisabled: Bool
    )
    case textInput(
        id: String,
        label: String?,
        subtitle: String?,
        text: String,
        placeholder: String?,
        multiline: Bool,
        minLines: Int,
        actionId: String,
        triggerOnChange: Bool,
        isDisabled: Bool
    )
    case shortcutRecorder(
        id: String,
        label: String,
        subtitle: String?,
        shortcut: ExtensionSDUIShortcutValue?,
        actionId: String,
        allowDoubleTap: Bool,
        allowClear: Bool,
        infoText: String?
    )
    case chipSelector(
        id: String,
        label: String?,
        options: [ExtensionSDUIChipOption],
        selectedIds: [String],
        multiSelect: Bool,
        actionId: String
    )
    case colorPicker(id: String, label: String, hexColor: String, actionId: String, supportsOpacity: Bool)
    case filePicker(
        id: String,
        label: String,
        subtitle: String?,
        path: String?,
        placeholder: String?,
        actionId: String,
        allowedExtensions: [String],
        selectDirectories: Bool
    )
    case buttonGroup(
        id: String,
        buttons: [ExtensionSDUIButtonItem],
        spacing: Double,
        alignment: ExtensionSDUIAlignment
    )
    case progress(id: String, label: String?, value: Double?, total: Double?, subtitle: String?, tone: ExtensionSDUITone)
    case logViewer(id: String, title: String?, lines: [String], maxHeight: Double, monospaced: Bool)
    case navigationLink(
        id: String,
        title: String,
        subtitle: String?,
        icon: String?,
        tintColor: String?,
        badgeText: String?,
        destinationTitle: String,
        destinationNodes: [ExtensionSDUINode],
        toggleValue: Bool? = nil,
        toggleActionId: String? = nil
    )

    // Declarative host-bound slots (rendered natively by Core)
    case aiModelCard(id: String, modelId: String, title: String?, subtitle: String?, showDangerZone: Bool, showLogs: Bool)
    case aiProviderPicker(
        id: String,
        label: String,
        subtitle: String?,
        scope: ExtensionSDUIProviderScope,
        selectedProviderId: String?,
        selectedModelId: String?,
        allowSystemDefault: Bool,
        actionId: String
    )
    case calendarBadge(id: String, payload: ExtensionSDUICalendarBadgePayload)
    case calendarEventBanner(id: String, payload: ExtensionSDUICalendarEventBannerPayload)
    case calendarMonthAgenda(id: String, payload: ExtensionSDUICalendarMonthAgendaPayload)

    public var id: String {
        switch self {
        case .text(let id, _, _, _): return id
        case .button(let id, _, _, _, _): return id
        case .image(let id, _, _, _, _): return id
        case .container(let id, _, _, _, _): return id
        case .slider(let id, _, _, _, _, _): return id
        case .form(let id, _, _, _): return id
        case .waveform(let id, _, _, _, _, _, _): return id
        case .section(let id, _, _, _, _): return id
        case .extensionHeader(let id, _, _, _, _, _, _, _): return id
        case .disclosureGroup(let id, _, _, _, _, _, _, _, _, _, _): return id
        case .callout(let id, _, _, _, _, _, _): return id
        case .divider(let id, _): return id
        case .spacer(let id, _): return id
        case .badge(let id, _, _, _): return id
        case .infoPopover(let id, _, _, _, _): return id
        case .ratingScale(let id, _, _, _, _, _, _): return id
        case .metricRow(let id, _, _, _, _, _, _): return id
        case .listRow(let id, _, _, _, _, _, _, _): return id
        case .toggle(let id, _, _, _, _, _, _, _): return id
        case .segmentedControl(let id, _, _, _, _, _, _, _): return id
        case .picker(let id, _, _, _, _, _, _, _, _, _): return id
        case .stepper(let id, _, _, _, _, _, _, _, _, _, _): return id
        case .labeledSlider(let id, _, _, _, _, _, _, _, _, _, _, _, _): return id
        case .textInput(let id, _, _, _, _, _, _, _, _, _): return id
        case .shortcutRecorder(let id, _, _, _, _, _, _, _): return id
        case .chipSelector(let id, _, _, _, _, _): return id
        case .colorPicker(let id, _, _, _, _): return id
        case .filePicker(let id, _, _, _, _, _, _, _): return id
        case .buttonGroup(let id, _, _, _): return id
        case .progress(let id, _, _, _, _, _): return id
        case .logViewer(let id, _, _, _, _): return id
        case .navigationLink(let id, _, _, _, _, _, _, _, _, _): return id
        case .aiModelCard(let id, _, _, _, _, _): return id
        case .aiProviderPicker(let id, _, _, _, _, _, _, _): return id
        case .calendarBadge(let id, _): return id
        case .calendarEventBanner(let id, _): return id
        case .calendarMonthAgenda(let id, _): return id
        }
    }
}
