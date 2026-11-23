import Foundation

/// A single calendar source synced from macOS EventKit (Apple Calendar).
public struct ExtensionCalendarSource: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let accountTitle: String
    public let colorHex: String
    public let isSubscribed: Bool
    public let isImmutable: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case accountTitle = "account_title"
        case camelAccountTitle = "accountTitle"
        case colorHex = "color_hex"
        case camelColorHex = "colorHex"
        case isSubscribed = "is_subscribed"
        case camelIsSubscribed = "isSubscribed"
        case isImmutable = "is_immutable"
        case camelIsImmutable = "isImmutable"
    }

    public init(
        id: String,
        title: String,
        accountTitle: String = "",
        colorHex: String = "#0A84FF",
        isSubscribed: Bool = false,
        isImmutable: Bool = false
    ) {
        self.id = id
        self.title = title
        self.accountTitle = accountTitle
        self.colorHex = colorHex
        self.isSubscribed = isSubscribed
        self.isImmutable = isImmutable
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.title = try c.decode(String.self, forKey: .title)
        self.accountTitle = try c.decodeIfPresent(String.self, forKey: .accountTitle)
            ?? c.decodeIfPresent(String.self, forKey: .camelAccountTitle)
            ?? ""
        self.colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex)
            ?? c.decodeIfPresent(String.self, forKey: .camelColorHex)
            ?? "#0A84FF"
        self.isSubscribed = try c.decodeIfPresent(Bool.self, forKey: .isSubscribed)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelIsSubscribed)
            ?? false
        self.isImmutable = try c.decodeIfPresent(Bool.self, forKey: .isImmutable)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelIsImmutable)
            ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(accountTitle, forKey: .accountTitle)
        try c.encode(colorHex, forKey: .colorHex)
        try c.encode(isSubscribed, forKey: .isSubscribed)
        try c.encode(isImmutable, forKey: .isImmutable)
    }
}

/// EventKit lifecycle status of a calendar event (`EKEventStatus`).
public enum ExtensionCalendarEventStatus: String, Codable, Equatable, Sendable {
    case none
    case confirmed
    case tentative
    case canceled
}

/// Current user's RSVP / attendance status for an invited calendar event (`EKParticipantStatus`).
public enum ExtensionCalendarAttendanceStatus: String, Codable, Equatable, Sendable {
    case none
    case pending
    case accepted
    case declined
    case tentative
}

/// Host-mediated action that can be performed on a calendar event from the preview UI or CLI.
public enum ExtensionCalendarEventAction: String, Codable, Equatable, Sendable, CaseIterable {
    case openInCalendar = "open_in_calendar"
    case remove
}

/// A single calendar event fetched from macOS EventKit (Apple Calendar).
public struct ExtensionCalendarEvent: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let calendarId: String
    public let calendarTitle: String
    public let calendarColorHex: String
    public let title: String
    public let startTimestamp: Double
    public let endTimestamp: Double
    public let isAllDay: Bool
    public let location: String?
    public let meetingURL: String?
    public let meetingProvider: String?
    public let eventStatus: ExtensionCalendarEventStatus
    public let attendanceStatus: ExtensionCalendarAttendanceStatus
    public let canRespond: Bool
    public let canRemove: Bool

    public var isCanceled: Bool { eventStatus == .canceled }
    public var isDeclined: Bool { attendanceStatus == .declined }

    enum CodingKeys: String, CodingKey {
        case id
        case calendarId = "calendar_id"
        case camelCalendarId = "calendarId"
        case calendarTitle = "calendar_title"
        case camelCalendarTitle = "calendarTitle"
        case calendarColorHex = "calendar_color_hex"
        case camelCalendarColorHex = "calendarColorHex"
        case title
        case startTimestamp = "start_timestamp"
        case camelStartTimestamp = "startTimestamp"
        case endTimestamp = "end_timestamp"
        case camelEndTimestamp = "endTimestamp"
        case isAllDay = "is_all_day"
        case camelIsAllDay = "isAllDay"
        case location
        case meetingURL = "meeting_url"
        case camelMeetingURL = "meetingURL"
        case meetingProvider = "meeting_provider"
        case camelMeetingProvider = "meetingProvider"
        case eventStatus = "event_status"
        case camelEventStatus = "eventStatus"
        case attendanceStatus = "attendance_status"
        case camelAttendanceStatus = "attendanceStatus"
        case canRespond = "can_respond"
        case camelCanRespond = "canRespond"
        case canRemove = "can_remove"
        case camelCanRemove = "canRemove"
    }

    public init(
        id: String,
        calendarId: String,
        calendarTitle: String,
        calendarColorHex: String,
        title: String,
        startTimestamp: Double,
        endTimestamp: Double,
        isAllDay: Bool = false,
        location: String? = nil,
        meetingURL: String? = nil,
        meetingProvider: String? = nil,
        eventStatus: ExtensionCalendarEventStatus = .none,
        attendanceStatus: ExtensionCalendarAttendanceStatus = .none,
        canRespond: Bool = false,
        canRemove: Bool = false
    ) {
        self.id = id
        self.calendarId = calendarId
        self.calendarTitle = calendarTitle
        self.calendarColorHex = calendarColorHex
        self.title = title
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.isAllDay = isAllDay
        self.location = location
        self.meetingURL = meetingURL
        self.meetingProvider = meetingProvider
        self.eventStatus = eventStatus
        self.attendanceStatus = attendanceStatus
        self.canRespond = canRespond
        self.canRemove = canRemove
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.calendarId = try c.decodeIfPresent(String.self, forKey: .calendarId)
            ?? c.decodeIfPresent(String.self, forKey: .camelCalendarId)
            ?? ""
        self.calendarTitle = try c.decodeIfPresent(String.self, forKey: .calendarTitle)
            ?? c.decodeIfPresent(String.self, forKey: .camelCalendarTitle)
            ?? ""
        self.calendarColorHex = try c.decodeIfPresent(String.self, forKey: .calendarColorHex)
            ?? c.decodeIfPresent(String.self, forKey: .camelCalendarColorHex)
            ?? "#0A84FF"
        self.title = try c.decode(String.self, forKey: .title)
        self.startTimestamp = try c.decodeIfPresent(Double.self, forKey: .startTimestamp)
            ?? c.decode(Double.self, forKey: .camelStartTimestamp)
        self.endTimestamp = try c.decodeIfPresent(Double.self, forKey: .endTimestamp)
            ?? c.decode(Double.self, forKey: .camelEndTimestamp)
        self.isAllDay = try c.decodeIfPresent(Bool.self, forKey: .isAllDay)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelIsAllDay)
            ?? false
        self.location = try c.decodeIfPresent(String.self, forKey: .location)
        self.meetingURL = try c.decodeIfPresent(String.self, forKey: .meetingURL)
            ?? c.decodeIfPresent(String.self, forKey: .camelMeetingURL)
        self.meetingProvider = try c.decodeIfPresent(String.self, forKey: .meetingProvider)
            ?? c.decodeIfPresent(String.self, forKey: .camelMeetingProvider)
        self.eventStatus = try c.decodeIfPresent(ExtensionCalendarEventStatus.self, forKey: .eventStatus)
            ?? c.decodeIfPresent(ExtensionCalendarEventStatus.self, forKey: .camelEventStatus)
            ?? .none
        self.attendanceStatus = try c.decodeIfPresent(ExtensionCalendarAttendanceStatus.self, forKey: .attendanceStatus)
            ?? c.decodeIfPresent(ExtensionCalendarAttendanceStatus.self, forKey: .camelAttendanceStatus)
            ?? .none
        self.canRespond = try c.decodeIfPresent(Bool.self, forKey: .canRespond)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelCanRespond)
            ?? false
        self.canRemove = try c.decodeIfPresent(Bool.self, forKey: .canRemove)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelCanRemove)
            ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(calendarId, forKey: .calendarId)
        try c.encode(calendarTitle, forKey: .calendarTitle)
        try c.encode(calendarColorHex, forKey: .calendarColorHex)
        try c.encode(title, forKey: .title)
        try c.encode(startTimestamp, forKey: .startTimestamp)
        try c.encode(endTimestamp, forKey: .endTimestamp)
        try c.encode(isAllDay, forKey: .isAllDay)
        try c.encodeIfPresent(location, forKey: .location)
        try c.encodeIfPresent(meetingURL, forKey: .meetingURL)
        try c.encodeIfPresent(meetingProvider, forKey: .meetingProvider)
        try c.encode(eventStatus, forKey: .eventStatus)
        try c.encode(attendanceStatus, forKey: .attendanceStatus)
        try c.encode(canRespond, forKey: .canRespond)
        try c.encode(canRemove, forKey: .canRemove)
    }
}

/// On-demand detail payload fetched for a single calendar event only when inspected (e.g. hover popover).
public struct ExtensionCalendarEventDetails: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let notes: String?
    public let location: String?
    public let meetingURL: String?
    public let meetingProvider: String?
    public let organizerName: String?
    public let attendeeCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case notes
        case location
        case meetingURL = "meeting_url"
        case meetingProvider = "meeting_provider"
        case organizerName = "organizer_name"
        case attendeeCount = "attendee_count"
    }

    public init(
        id: String,
        title: String,
        notes: String? = nil,
        location: String? = nil,
        meetingURL: String? = nil,
        meetingProvider: String? = nil,
        organizerName: String? = nil,
        attendeeCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.location = location
        self.meetingURL = meetingURL
        self.meetingProvider = meetingProvider
        self.organizerName = organizerName
        self.attendeeCount = attendeeCount
    }
}

/// One calendar source's proportional slice inside the daily meetings vs. free-time stacked bar.
public struct CalendarDayLoadSegment: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let calendarTitle: String
    public let colorHex: String
    public let minutes: Int
    public let meetingCount: Int

    public init(
        id: String,
        calendarTitle: String,
        colorHex: String,
        minutes: Int,
        meetingCount: Int
    ) {
        self.id = id
        self.calendarTitle = calendarTitle
        self.colorHex = colorHex
        self.minutes = minutes
        self.meetingCount = meetingCount
    }
}

/// One timed calendar event positioned along the day's 12h or 24h hourly timeline bar.
public struct CalendarDayTimelineBlock: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let event: ExtensionCalendarEvent
    /// Start offset in minutes from `windowStartHour` (clamped to `[0, windowHours * 60]`).
    public let startMinuteOffset: Double
    /// End offset in minutes from `windowStartHour` (clamped to `[0, windowHours * 60]`).
    public let endMinuteOffset: Double
    /// Vertical lane index when meetings overlap (`0`-based).
    public let laneIndex: Int
    /// Total overlapping lanes in this block's overlap cluster (`>= 1`).
    public let laneCount: Int

    public init(
        id: String,
        event: ExtensionCalendarEvent,
        startMinuteOffset: Double,
        endMinuteOffset: Double,
        laneIndex: Int = 0,
        laneCount: Int = 1
    ) {
        self.id = id
        self.event = event
        self.startMinuteOffset = startMinuteOffset
        self.endMinuteOffset = endMinuteOffset
        self.laneIndex = laneIndex
        self.laneCount = max(1, laneCount)
    }
}

/// Interval-merged meetings vs. free-time summary and hourly timeline blocks for a single calendar day.
public struct CalendarDayLoadSummary: Codable, Equatable, Sendable {
    public let dayStartTimestamp: Double
    public let meetingCount: Int
    public let allDayCount: Int
    public let busyMinutes: Int
    public let freeMinutes: Int
    public let workdayMinutes: Int
    public let windowHours: Int
    public let windowStartHour: Int
    public let windowEndHour: Int
    public let windowFreeMinutes: Int
    public let segments: [CalendarDayLoadSegment]
    public let timelineBlocks: [CalendarDayTimelineBlock]

    public init(
        dayStartTimestamp: Double,
        meetingCount: Int,
        allDayCount: Int,
        busyMinutes: Int,
        freeMinutes: Int,
        workdayMinutes: Int,
        windowHours: Int = 12,
        windowStartHour: Int = 8,
        windowEndHour: Int = 20,
        windowFreeMinutes: Int? = nil,
        segments: [CalendarDayLoadSegment],
        timelineBlocks: [CalendarDayTimelineBlock] = []
    ) {
        self.dayStartTimestamp = dayStartTimestamp
        self.meetingCount = meetingCount
        self.allDayCount = allDayCount
        self.busyMinutes = busyMinutes
        self.freeMinutes = freeMinutes
        self.workdayMinutes = workdayMinutes
        self.windowHours = windowHours
        self.windowStartHour = windowStartHour
        self.windowEndHour = windowEndHour
        self.windowFreeMinutes = windowFreeMinutes ?? max(0, windowHours * 60 - busyMinutes)
        self.segments = segments
        self.timelineBlocks = timelineBlocks
    }

    public static func compute(
        events: [ExtensionCalendarEvent],
        enabledCalendarIds: [String],
        for date: Date,
        workdayMinutes: Int = 8 * 60,
        windowHours: Int = 12,
        calendar: Calendar = .current
    ) -> CalendarDayLoadSummary {
        let allowed = enabledCalendarIds.isEmpty ? nil : Set(enabledCalendarIds)
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86400)
        let dayStartTs = dayStart.timeIntervalSince1970
        let dayEndTs = dayEnd.timeIntervalSince1970

        var intervals: [(start: Double, end: Double)] = []
        var timedEventsForDay: [(event: ExtensionCalendarEvent, start: Double, end: Double)] = []
        var rawMinutesByCalendar: [String: (title: String, colorHex: String, minutes: Double, count: Int)] = [:]
        var meetingCount = 0
        var allDayCount = 0

        for event in events {
            if let allowed, !allowed.contains(event.calendarId) {
                continue
            }
            // Event overlaps [dayStartTs, dayEndTs)
            guard event.endTimestamp > dayStartTs && event.startTimestamp < dayEndTs else {
                continue
            }
            if event.isAllDay {
                allDayCount += 1
                continue
            }
            let clippedStart = max(dayStartTs, event.startTimestamp)
            let clippedEnd = min(dayEndTs, event.endTimestamp)
            let durationSec = clippedEnd - clippedStart
            guard durationSec > 0 else { continue }

            meetingCount += 1
            intervals.append((clippedStart, clippedEnd))
            timedEventsForDay.append((event, clippedStart, clippedEnd))
            let minutes = durationSec / 60.0
            let key = event.calendarId.isEmpty ? event.calendarColorHex : event.calendarId
            if var existing = rawMinutesByCalendar[key] {
                existing.minutes += minutes
                existing.count += 1
                rawMinutesByCalendar[key] = existing
            } else {
                rawMinutesByCalendar[key] = (
                    title: event.calendarTitle.isEmpty ? "Calendar" : event.calendarTitle,
                    colorHex: event.calendarColorHex,
                    minutes: minutes,
                    count: 1
                )
            }
        }

        // Merge overlapping intervals so concurrent meetings don't inflate total booked time.
        let mergedSeconds = Self.mergedDurationSeconds(intervals)
        let safeWorkday = max(60, workdayMinutes)
        let busyMinutes = min(24 * 60, Int(round(mergedSeconds / 60.0)))
        let freeMinutes = max(0, safeWorkday - busyMinutes)
        let totalRawMinutes = rawMinutesByCalendar.values.reduce(0.0) { $0 + $1.minutes }

        let segments: [CalendarDayLoadSegment] = rawMinutesByCalendar
            .map { key, entry in
                let scaledMinutes: Int
                if totalRawMinutes > 0 && busyMinutes > 0 {
                    scaledMinutes = max(1, Int(round((entry.minutes / totalRawMinutes) * Double(busyMinutes))))
                } else {
                    scaledMinutes = 0
                }
                return CalendarDayLoadSegment(
                    id: key,
                    calendarTitle: entry.title,
                    colorHex: entry.colorHex,
                    minutes: scaledMinutes,
                    meetingCount: entry.count
                )
            }
            .filter { $0.minutes > 0 }
            .sorted { lhs, rhs in
                if lhs.minutes != rhs.minutes { return lhs.minutes > rhs.minutes }
                return lhs.calendarTitle.localizedCaseInsensitiveCompare(rhs.calendarTitle) == .orderedAscending
            }

        // Compute 12h or 24h timeline window boundaries and lane-packed blocks.
        let normalizedWindowHours = (windowHours == 24) ? 24 : 12
        let windowStartHour: Int
        if normalizedWindowHours == 24 {
            windowStartHour = 0
        } else {
            // Default 8 AM – 8 PM; gently shift within [0, 12] if an early/late meeting falls outside.
            var startHour = 8
            if let earliestTs = timedEventsForDay.map(\.start).min(),
               let latestTs = timedEventsForDay.map(\.end).max() {
                let earliestHour = Int(floor((earliestTs - dayStartTs) / 3600.0))
                let latestHourCeil = Int(ceil((latestTs - dayStartTs) / 3600.0))
                if earliestHour < startHour {
                    startHour = max(0, earliestHour)
                } else if latestHourCeil > startHour + 12 {
                    startHour = min(12, max(startHour, latestHourCeil - 12))
                }
            }
            windowStartHour = startHour
        }
        let windowEndHour = windowStartHour + normalizedWindowHours
        let windowStartTs = dayStartTs + Double(windowStartHour) * 3600.0
        let windowEndTs = dayStartTs + Double(windowEndHour) * 3600.0

        var windowIntervals: [(start: Double, end: Double)] = []
        var rawBlocks: [(event: ExtensionCalendarEvent, startMin: Double, endMin: Double)] = []
        for item in timedEventsForDay.sorted(by: { $0.start < $1.start }) {
            let cs = max(windowStartTs, item.start)
            let ce = min(windowEndTs, item.end)
            guard ce > cs else { continue }
            windowIntervals.append((cs, ce))
            rawBlocks.append((
                event: item.event,
                startMin: (cs - windowStartTs) / 60.0,
                endMin: (ce - windowStartTs) / 60.0
            ))
        }

        let windowBusyMinutes = min(normalizedWindowHours * 60, Int(round(Self.mergedDurationSeconds(windowIntervals) / 60.0)))
        let windowFreeMinutes = max(0, normalizedWindowHours * 60 - windowBusyMinutes)
        let timelineBlocks = Self.assignOverlapLanes(rawBlocks)

        return CalendarDayLoadSummary(
            dayStartTimestamp: dayStartTs,
            meetingCount: meetingCount,
            allDayCount: allDayCount,
            busyMinutes: busyMinutes,
            freeMinutes: freeMinutes,
            workdayMinutes: safeWorkday,
            windowHours: normalizedWindowHours,
            windowStartHour: windowStartHour,
            windowEndHour: windowEndHour,
            windowFreeMinutes: windowFreeMinutes,
            segments: segments,
            timelineBlocks: timelineBlocks
        )
    }

    private static func mergedDurationSeconds(_ intervals: [(start: Double, end: Double)]) -> Double {
        let sorted = intervals.sorted { $0.start < $1.start }
        var mergedSeconds: Double = 0
        var currentStart: Double?
        var currentEnd: Double = 0

        for interval in sorted {
            if let cs = currentStart {
                if interval.start <= currentEnd {
                    currentEnd = max(currentEnd, interval.end)
                } else {
                    mergedSeconds += max(0, currentEnd - cs)
                    currentStart = interval.start
                    currentEnd = interval.end
                }
            } else {
                currentStart = interval.start
                currentEnd = interval.end
            }
        }
        if let cs = currentStart {
            mergedSeconds += max(0, currentEnd - cs)
        }
        return mergedSeconds
    }

    private static func assignOverlapLanes(
        _ blocks: [(event: ExtensionCalendarEvent, startMin: Double, endMin: Double)]
    ) -> [CalendarDayTimelineBlock] {
        guard !blocks.isEmpty else { return [] }
        // Group overlapping blocks into clusters and greedily assign vertical lanes per cluster.
        var result: [CalendarDayTimelineBlock] = []
        var cluster: [(event: ExtensionCalendarEvent, startMin: Double, endMin: Double)] = []
        var clusterMaxEnd: Double = -1

        func flushCluster() {
            guard !cluster.isEmpty else { return }
            var laneEndTimes: [Double] = []
            var assigned: [(event: ExtensionCalendarEvent, startMin: Double, endMin: Double, lane: Int)] = []
            for item in cluster {
                if let idx = laneEndTimes.firstIndex(where: { $0 <= item.startMin + 0.1 }) {
                    laneEndTimes[idx] = item.endMin
                    assigned.append((item.event, item.startMin, item.endMin, idx))
                } else {
                    let nextLane = laneEndTimes.count
                    laneEndTimes.append(item.endMin)
                    assigned.append((item.event, item.startMin, item.endMin, nextLane))
                }
            }
            let totalLanes = max(1, laneEndTimes.count)
            for item in assigned {
                result.append(
                    CalendarDayTimelineBlock(
                        id: item.event.id,
                        event: item.event,
                        startMinuteOffset: item.startMin,
                        endMinuteOffset: item.endMin,
                        laneIndex: item.lane,
                        laneCount: totalLanes
                    )
                )
            }
            cluster.removeAll(keepingCapacity: true)
            clusterMaxEnd = -1
        }

        for item in blocks {
            if !cluster.isEmpty && item.startMin >= clusterMaxEnd - 0.1 {
                flushCluster()
            }
            cluster.append(item)
            clusterMaxEnd = max(clusterMaxEnd, item.endMin)
        }
        flushCluster()
        return result
    }

    public static func formatDuration(minutes: Int) -> String {
        let clamped = max(0, minutes)
        let hours = clamped / 60
        let mins = clamped % 60
        if hours == 0 {
            return "\(mins)m"
        }
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }
}

/// Snapshot of Apple Calendar sources and events delivered by `HostCalendarBridge`.
public struct ExtensionCalendarSnapshot: Codable, Equatable, Sendable {
    public let permissionGranted: Bool
    public let sources: [ExtensionCalendarSource]
    public let events: [ExtensionCalendarEvent]
    public let rangeStartTimestamp: Double
    public let rangeEndTimestamp: Double
    public let fetchedAtTimestamp: Double

    enum CodingKeys: String, CodingKey {
        case permissionGranted = "permission_granted"
        case camelPermissionGranted = "permissionGranted"
        case sources
        case events
        case rangeStartTimestamp = "range_start_timestamp"
        case camelRangeStartTimestamp = "rangeStartTimestamp"
        case rangeEndTimestamp = "range_end_timestamp"
        case camelRangeEndTimestamp = "rangeEndTimestamp"
        case fetchedAtTimestamp = "fetched_at_timestamp"
        case camelFetchedAtTimestamp = "fetchedAtTimestamp"
    }

    public init(
        permissionGranted: Bool,
        sources: [ExtensionCalendarSource],
        events: [ExtensionCalendarEvent],
        rangeStartTimestamp: Double,
        rangeEndTimestamp: Double,
        fetchedAtTimestamp: Double = Date().timeIntervalSince1970
    ) {
        self.permissionGranted = permissionGranted
        self.sources = sources
        self.events = events
        self.rangeStartTimestamp = rangeStartTimestamp
        self.rangeEndTimestamp = rangeEndTimestamp
        self.fetchedAtTimestamp = fetchedAtTimestamp
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.permissionGranted = try c.decodeIfPresent(Bool.self, forKey: .permissionGranted)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelPermissionGranted)
            ?? false
        self.sources = try c.decodeIfPresent([ExtensionCalendarSource].self, forKey: .sources) ?? []
        self.events = try c.decodeIfPresent([ExtensionCalendarEvent].self, forKey: .events) ?? []
        self.rangeStartTimestamp = try c.decodeIfPresent(Double.self, forKey: .rangeStartTimestamp)
            ?? c.decodeIfPresent(Double.self, forKey: .camelRangeStartTimestamp)
            ?? 0
        self.rangeEndTimestamp = try c.decodeIfPresent(Double.self, forKey: .rangeEndTimestamp)
            ?? c.decodeIfPresent(Double.self, forKey: .camelRangeEndTimestamp)
            ?? 0
        self.fetchedAtTimestamp = try c.decodeIfPresent(Double.self, forKey: .fetchedAtTimestamp)
            ?? c.decodeIfPresent(Double.self, forKey: .camelFetchedAtTimestamp)
            ?? Date().timeIntervalSince1970
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(permissionGranted, forKey: .permissionGranted)
        try c.encode(sources, forKey: .sources)
        try c.encode(events, forKey: .events)
        try c.encode(rangeStartTimestamp, forKey: .rangeStartTimestamp)
        try c.encode(rangeEndTimestamp, forKey: .rangeEndTimestamp)
        try c.encode(fetchedAtTimestamp, forKey: .fetchedAtTimestamp)
    }
}

/// Generic 3-state Dock Widget specification emitted by out-of-process extensions via `set_dock_widget`.
public struct ExtensionDockWidgetSpec: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let previewWidth: Double
    public let expandedWidth: Double
    public let expandedHeight: Double
    public let defaultSquare: ExtensionSDUINode
    public let hoverExpanded: ExtensionSDUINode?
    public let verticalExpanded: ExtensionSDUINode?
    public let dockIconBinding: DockIconBindingSpec?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case previewWidth = "preview_width"
        case camelPreviewWidth = "previewWidth"
        case expandedWidth = "expanded_width"
        case camelExpandedWidth = "expandedWidth"
        case expandedHeight = "expanded_height"
        case camelExpandedHeight = "expandedHeight"
        case defaultSquare = "default_square"
        case camelDefaultSquare = "defaultSquare"
        case hoverExpanded = "hover_expanded"
        case camelHoverExpanded = "hoverExpanded"
        case verticalExpanded = "vertical_expanded"
        case camelVerticalExpanded = "verticalExpanded"
        case dockIconBinding = "dock_icon_binding"
        case camelDockIconBinding = "dockIconBinding"
    }

    public init(
        id: String,
        title: String = "Extension Widget",
        previewWidth: Double = 320,
        expandedWidth: Double = 336,
        expandedHeight: Double = 460,
        defaultSquare: ExtensionSDUINode,
        hoverExpanded: ExtensionSDUINode? = nil,
        verticalExpanded: ExtensionSDUINode? = nil,
        dockIconBinding: DockIconBindingSpec? = nil
    ) {
        self.id = id
        self.title = title
        self.previewWidth = previewWidth
        self.expandedWidth = expandedWidth
        self.expandedHeight = expandedHeight
        self.defaultSquare = defaultSquare
        self.hoverExpanded = hoverExpanded
        self.verticalExpanded = verticalExpanded
        self.dockIconBinding = dockIconBinding
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? id
        self.previewWidth = try c.decodeIfPresent(Double.self, forKey: .previewWidth)
            ?? c.decodeIfPresent(Double.self, forKey: .camelPreviewWidth)
            ?? 320
        self.expandedWidth = try c.decodeIfPresent(Double.self, forKey: .expandedWidth)
            ?? c.decodeIfPresent(Double.self, forKey: .camelExpandedWidth)
            ?? 336
        self.expandedHeight = try c.decodeIfPresent(Double.self, forKey: .expandedHeight)
            ?? c.decodeIfPresent(Double.self, forKey: .camelExpandedHeight)
            ?? 460
        self.defaultSquare = try c.decodeIfPresent(ExtensionSDUINode.self, forKey: .defaultSquare)
            ?? c.decode(ExtensionSDUINode.self, forKey: .camelDefaultSquare)
        self.hoverExpanded = try c.decodeIfPresent(ExtensionSDUINode.self, forKey: .hoverExpanded)
            ?? c.decodeIfPresent(ExtensionSDUINode.self, forKey: .camelHoverExpanded)
        self.verticalExpanded = try c.decodeIfPresent(ExtensionSDUINode.self, forKey: .verticalExpanded)
            ?? c.decodeIfPresent(ExtensionSDUINode.self, forKey: .camelVerticalExpanded)
        self.dockIconBinding = try c.decodeIfPresent(DockIconBindingSpec.self, forKey: .dockIconBinding)
            ?? c.decodeIfPresent(DockIconBindingSpec.self, forKey: .camelDockIconBinding)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(previewWidth, forKey: .previewWidth)
        try c.encode(expandedWidth, forKey: .expandedWidth)
        try c.encode(expandedHeight, forKey: .expandedHeight)
        try c.encode(defaultSquare, forKey: .defaultSquare)
        try c.encodeIfPresent(hoverExpanded, forKey: .hoverExpanded)
        try c.encodeIfPresent(verticalExpanded, forKey: .verticalExpanded)
        try c.encodeIfPresent(dockIconBinding, forKey: .dockIconBinding)
    }
}

/// Compact calendar date badge payload (`MON` / `16`) used in Dock Widgets and Live Activities.
public struct ExtensionSDUICalendarBadgePayload: Codable, Equatable, Sendable {
    public let weekday: String
    public let dayNumber: String
    public let accentColor: String

    enum CodingKeys: String, CodingKey {
        case weekday
        case dayNumber = "day_number"
        case camelDayNumber = "dayNumber"
        case accentColor = "accent_color"
        case camelAccentColor = "accentColor"
    }

    public init(weekday: String, dayNumber: String, accentColor: String = "#E54858") {
        self.weekday = weekday
        self.dayNumber = dayNumber
        self.accentColor = accentColor
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.weekday = try c.decode(String.self, forKey: .weekday)
        self.dayNumber = try c.decodeIfPresent(String.self, forKey: .dayNumber)
            ?? c.decode(String.self, forKey: .camelDayNumber)
        self.accentColor = try c.decodeIfPresent(String.self, forKey: .accentColor)
            ?? c.decodeIfPresent(String.self, forKey: .camelAccentColor)
            ?? "#E54858"
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(weekday, forKey: .weekday)
        try c.encode(dayNumber, forKey: .dayNumber)
        try c.encode(accentColor, forKey: .accentColor)
    }
}

/// Horizontal upcoming-event preview banner payload (date badge + event title/time/countdown + action icon).
public struct ExtensionSDUICalendarEventBannerPayload: Codable, Equatable, Sendable {
    public let weekday: String
    public let dayNumber: String
    public let badgeColor: String
    public let title: String
    public let timeText: String
    public let countdownText: String?
    public let accentColor: String
    public let actionIcon: String?
    public let actionId: String?
    public let actionURL: String?

    enum CodingKeys: String, CodingKey {
        case weekday
        case dayNumber = "day_number"
        case camelDayNumber = "dayNumber"
        case badgeColor = "badge_color"
        case camelBadgeColor = "badgeColor"
        case title
        case timeText = "time_text"
        case camelTimeText = "timeText"
        case countdownText = "countdown_text"
        case camelCountdownText = "countdownText"
        case accentColor = "accent_color"
        case camelAccentColor = "accentColor"
        case actionIcon = "action_icon"
        case camelActionIcon = "actionIcon"
        case actionId = "action_id"
        case camelActionId = "actionId"
        case actionURL = "action_url"
        case camelActionURL = "actionURL"
    }

    public init(
        weekday: String,
        dayNumber: String,
        badgeColor: String = "#E54858",
        title: String,
        timeText: String,
        countdownText: String? = nil,
        accentColor: String = "#FF4D6D",
        actionIcon: String? = nil,
        actionId: String? = nil,
        actionURL: String? = nil
    ) {
        self.weekday = weekday
        self.dayNumber = dayNumber
        self.badgeColor = badgeColor
        self.title = title
        self.timeText = timeText
        self.countdownText = countdownText
        self.accentColor = accentColor
        self.actionIcon = actionIcon
        self.actionId = actionId
        self.actionURL = actionURL
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.weekday = try c.decode(String.self, forKey: .weekday)
        self.dayNumber = try c.decodeIfPresent(String.self, forKey: .dayNumber)
            ?? c.decode(String.self, forKey: .camelDayNumber)
        self.badgeColor = try c.decodeIfPresent(String.self, forKey: .badgeColor)
            ?? c.decodeIfPresent(String.self, forKey: .camelBadgeColor)
            ?? "#E54858"
        self.title = try c.decode(String.self, forKey: .title)
        self.timeText = try c.decodeIfPresent(String.self, forKey: .timeText)
            ?? c.decodeIfPresent(String.self, forKey: .camelTimeText)
            ?? ""
        self.countdownText = try c.decodeIfPresent(String.self, forKey: .countdownText)
            ?? c.decodeIfPresent(String.self, forKey: .camelCountdownText)
        self.accentColor = try c.decodeIfPresent(String.self, forKey: .accentColor)
            ?? c.decodeIfPresent(String.self, forKey: .camelAccentColor)
            ?? "#FF4D6D"
        self.actionIcon = try c.decodeIfPresent(String.self, forKey: .actionIcon)
            ?? c.decodeIfPresent(String.self, forKey: .camelActionIcon)
        self.actionId = try c.decodeIfPresent(String.self, forKey: .actionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelActionId)
        self.actionURL = try c.decodeIfPresent(String.self, forKey: .actionURL)
            ?? c.decodeIfPresent(String.self, forKey: .camelActionURL)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(weekday, forKey: .weekday)
        try c.encode(dayNumber, forKey: .dayNumber)
        try c.encode(badgeColor, forKey: .badgeColor)
        try c.encode(title, forKey: .title)
        try c.encode(timeText, forKey: .timeText)
        try c.encodeIfPresent(countdownText, forKey: .countdownText)
        try c.encode(accentColor, forKey: .accentColor)
        try c.encodeIfPresent(actionIcon, forKey: .actionIcon)
        try c.encodeIfPresent(actionId, forKey: .actionId)
        try c.encodeIfPresent(actionURL, forKey: .actionURL)
    }
}

/// Interactive month grid + grouped agenda SDUI payload for vertical Dock Widget expansion.
public struct ExtensionSDUICalendarMonthAgendaPayload: Codable, Equatable, Sendable {
    public let displayedYear: Int
    public let displayedMonth: Int
    public let permissionGranted: Bool
    public let sources: [ExtensionCalendarSource]
    public let events: [ExtensionCalendarEvent]
    public let enabledCalendarIds: [String]
    public let timelineWindowHours: Int
    public let onAddEventActionId: String?
    public let onJoinEventActionId: String?
    public let onRequestPermissionActionId: String?
    public let onChangeMonthActionId: String?

    enum CodingKeys: String, CodingKey {
        case displayedYear = "displayed_year"
        case camelDisplayedYear = "displayedYear"
        case displayedMonth = "displayed_month"
        case camelDisplayedMonth = "displayedMonth"
        case permissionGranted = "permission_granted"
        case camelPermissionGranted = "permissionGranted"
        case sources
        case events
        case enabledCalendarIds = "enabled_calendar_ids"
        case camelEnabledCalendarIds = "enabledCalendarIds"
        case timelineWindowHours = "timeline_window_hours"
        case camelTimelineWindowHours = "timelineWindowHours"
        case onAddEventActionId = "on_add_event_action_id"
        case camelOnAddEventActionId = "onAddEventActionId"
        case onJoinEventActionId = "on_join_event_action_id"
        case camelOnJoinEventActionId = "onJoinEventActionId"
        case onRequestPermissionActionId = "on_request_permission_action_id"
        case camelOnRequestPermissionActionId = "onRequestPermissionActionId"
        case onChangeMonthActionId = "on_change_month_action_id"
        case camelOnChangeMonthActionId = "onChangeMonthActionId"
    }

    public init(
        displayedYear: Int,
        displayedMonth: Int,
        permissionGranted: Bool,
        sources: [ExtensionCalendarSource],
        events: [ExtensionCalendarEvent],
        enabledCalendarIds: [String] = [],
        timelineWindowHours: Int = 12,
        onAddEventActionId: String? = nil,
        onJoinEventActionId: String? = nil,
        onRequestPermissionActionId: String? = nil,
        onChangeMonthActionId: String? = nil
    ) {
        self.displayedYear = displayedYear
        self.displayedMonth = displayedMonth
        self.permissionGranted = permissionGranted
        self.sources = sources
        self.events = events
        self.enabledCalendarIds = enabledCalendarIds
        self.timelineWindowHours = (timelineWindowHours == 24) ? 24 : 12
        self.onAddEventActionId = onAddEventActionId
        self.onJoinEventActionId = onJoinEventActionId
        self.onRequestPermissionActionId = onRequestPermissionActionId
        self.onChangeMonthActionId = onChangeMonthActionId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        self.displayedYear = try c.decodeIfPresent(Int.self, forKey: .displayedYear)
            ?? c.decodeIfPresent(Int.self, forKey: .camelDisplayedYear)
            ?? (now.year ?? 2026)
        self.displayedMonth = try c.decodeIfPresent(Int.self, forKey: .displayedMonth)
            ?? c.decodeIfPresent(Int.self, forKey: .camelDisplayedMonth)
            ?? (now.month ?? 1)
        self.permissionGranted = try c.decodeIfPresent(Bool.self, forKey: .permissionGranted)
            ?? c.decodeIfPresent(Bool.self, forKey: .camelPermissionGranted)
            ?? false
        self.sources = try c.decodeIfPresent([ExtensionCalendarSource].self, forKey: .sources) ?? []
        self.events = try c.decodeIfPresent([ExtensionCalendarEvent].self, forKey: .events) ?? []
        self.enabledCalendarIds = try c.decodeIfPresent([String].self, forKey: .enabledCalendarIds)
            ?? c.decodeIfPresent([String].self, forKey: .camelEnabledCalendarIds)
            ?? []
        let decodedWindow = try c.decodeIfPresent(Int.self, forKey: .timelineWindowHours)
            ?? c.decodeIfPresent(Int.self, forKey: .camelTimelineWindowHours)
            ?? 12
        self.timelineWindowHours = (decodedWindow == 24) ? 24 : 12
        self.onAddEventActionId = try c.decodeIfPresent(String.self, forKey: .onAddEventActionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelOnAddEventActionId)
        self.onJoinEventActionId = try c.decodeIfPresent(String.self, forKey: .onJoinEventActionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelOnJoinEventActionId)
        self.onRequestPermissionActionId = try c.decodeIfPresent(String.self, forKey: .onRequestPermissionActionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelOnRequestPermissionActionId)
        self.onChangeMonthActionId = try c.decodeIfPresent(String.self, forKey: .onChangeMonthActionId)
            ?? c.decodeIfPresent(String.self, forKey: .camelOnChangeMonthActionId)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(displayedYear, forKey: .displayedYear)
        try c.encode(displayedMonth, forKey: .displayedMonth)
        try c.encode(permissionGranted, forKey: .permissionGranted)
        try c.encode(sources, forKey: .sources)
        try c.encode(events, forKey: .events)
        try c.encode(enabledCalendarIds, forKey: .enabledCalendarIds)
        try c.encode(timelineWindowHours, forKey: .timelineWindowHours)
        try c.encodeIfPresent(onAddEventActionId, forKey: .onAddEventActionId)
        try c.encodeIfPresent(onJoinEventActionId, forKey: .onJoinEventActionId)
        try c.encodeIfPresent(onRequestPermissionActionId, forKey: .onRequestPermissionActionId)
        try c.encodeIfPresent(onChangeMonthActionId, forKey: .onChangeMonthActionId)
    }
}
