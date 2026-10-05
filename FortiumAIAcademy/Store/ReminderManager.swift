import SwiftUI
import UserNotifications

/// Daily "protect your streak" reminders.
///
/// Rather than one repeating notification, we schedule the next 7 days individually and
/// reschedule whenever the learner is active. That lets each reminder be smart:
/// - no reminder today if they've already learned today
/// - "your streak ends tonight" when today is the last chance to keep it
/// - gentle, varied nudges otherwise, mentioning their next lesson
@MainActor
@Observable
final class ReminderManager {
    static let identifierPrefix = "daily-reminder-"
    static let daysAhead = 7

    private(set) var isEnabled: Bool
    private(set) var hour: Int
    private(set) var minute: Int
    private(set) var authorization: UNAuthorizationStatus = .notDetermined

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private var lastContext: Context?

    struct Context {
        var lastActiveDay: Date?
        var streak: Int
        var nextLessonTitle: String?
    }

    init() {
        isEnabled = defaults.bool(forKey: SettingsKey.remindersEnabled)
        hour = defaults.object(forKey: SettingsKey.reminderHour) as? Int ?? 19
        minute = defaults.object(forKey: SettingsKey.reminderMinute) as? Int ?? 0
    }

    /// The reminder time as a Date today, for use with DatePicker.
    var time: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    var timeLabel: String {
        time.formatted(date: .omitted, time: .shortened)
    }

    var isBlockedInSettings: Bool { authorization == .denied }

    // MARK: User actions

    /// Asks for permission if needed. Returns whether reminders ended up on.
    @discardableResult
    func enable() async -> Bool {
        await refreshAuthorization()
        if authorization == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            await refreshAuthorization()
            if !granted { setEnabled(false); return false }
        }
        guard authorization == .authorized || authorization == .provisional || authorization == .ephemeral else {
            setEnabled(false)
            return false
        }
        setEnabled(true)
        await reschedule()
        return true
    }

    func disable() {
        setEnabled(false)
        center.removePendingNotificationRequests(withIdentifiers: Self.allIdentifiers)
    }

    func setTime(_ date: Date) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        hour = parts.hour ?? 19
        minute = parts.minute ?? 0
        defaults.set(hour, forKey: SettingsKey.reminderHour)
        defaults.set(minute, forKey: SettingsKey.reminderMinute)
        Task { await reschedule() }
    }

    func refreshAuthorization() async {
        authorization = await center.notificationSettings().authorizationStatus
    }

    // MARK: Scheduling

    /// Call whenever progress changes or the app becomes active.
    func update(context: Context) {
        lastContext = context
        Task { await reschedule() }
    }

    private func reschedule() async {
        center.removePendingNotificationRequests(withIdentifiers: Self.allIdentifiers)
        guard isEnabled else { return }
        await refreshAuthorization()
        guard authorization != .denied else { return }

        let context = lastContext ?? Context(lastActiveDay: nil, streak: 0, nextLessonTitle: nil)
        for item in Self.plan(context: context, hour: hour, minute: minute, now: Date()) {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: item.dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: Self.identifierPrefix + "\(item.dayOffset)",
                                                content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func setEnabled(_ value: Bool) {
        isEnabled = value
        defaults.set(value, forKey: SettingsKey.remindersEnabled)
    }

    private static var allIdentifiers: [String] {
        (0..<daysAhead).map { identifierPrefix + "\($0)" }
    }

    // MARK: Message planning (pure, so it's easy to reason about)

    struct PlannedReminder {
        let dayOffset: Int
        let dateComponents: DateComponents
        let title: String
        let body: String
    }

    static func plan(context: Context, hour: Int, minute: Int, now: Date,
                     calendar: Calendar = .current) -> [PlannedReminder] {
        let learnedToday = context.lastActiveDay.map { calendar.isDate($0, inSameDayAs: now) } ?? false
        let nextUp = context.nextLessonTitle.map { "Next up: \($0)." } ?? "Try the Prompt Builder for your next email or plan."

        var reminders: [PlannedReminder] = []
        for offset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fireDate > now else { continue }
            if offset == 0 && learnedToday { continue } // already done today, no nagging

            let title: String
            let body: String
            if offset == 0 && context.streak > 0 {
                // Learned yesterday but not yet today: tonight is the last chance.
                title = "Your \(context.streak)-day streak ends tonight 🔥"
                body = "A quick 5-minute lesson keeps it going. \(nextUp)"
            } else if offset == 1 && learnedToday && context.streak > 0 {
                title = "Keep your \(context.streak)-day streak going 🔥"
                body = "Just one short lesson today. \(nextUp)"
            } else {
                let options = gentleNudges(nextUp: nextUp)
                let pick = options[(calendar.ordinality(of: .day, in: .era, for: fireDate) ?? offset) % options.count]
                title = pick.0
                body = pick.1
            }

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            reminders.append(PlannedReminder(dayOffset: offset, dateComponents: components, title: title, body: body))
        }
        return reminders
    }

    private static func gentleNudges(nextUp: String) -> [(String, String)] {
        [
            ("Time for a quick lesson ✨", "5 minutes today makes Claude more useful tomorrow. \(nextUp)"),
            ("Your AI Academy is waiting", "Pick up where you left off. \(nextUp)"),
            ("Learn one new Claude skill today", "Short, simple, no tech skills needed. \(nextUp)"),
            ("A small step for today 🌱", "Little and often is the best way to learn. \(nextUp)"),
        ]
    }
}
