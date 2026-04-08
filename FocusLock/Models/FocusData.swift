import SwiftData
import Foundation

/// A user's blocking schedule across all 7 days.
@Model
final class Schedule {
    var days: [DaySchedule]

    init(days: [DaySchedule]) {
        self.days = days
    }

    /// Creates a default weekday schedule (Mon–Fri, 9 AM–5 PM; weekends off).
    static func defaultWeekday() -> Schedule {
        let days = (1...7).map { weekday in
            DaySchedule(
                weekday: weekday,
                isEnabled: weekday <= 5,  // Mon=1 ... Fri=5 enabled; Sat=6, Sun=7 off
                startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
                endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!
            )
        }
        return Schedule(days: days)
    }
}

/// One day's blocking configuration within a Schedule.
@Model
final class DaySchedule {
    /// 1 = Monday, 7 = Sunday (matching ISO 8601 weekday convention used in the app).
    var weekday: Int
    var isEnabled: Bool
    var startTime: Date
    var endTime: Date

    init(weekday: Int, isEnabled: Bool, startTime: Date, endTime: Date) {
        self.weekday = weekday
        self.isEnabled = isEnabled
        self.startTime = startTime
        self.endTime = endTime
    }

    var weekdayName: String {
        let names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard weekday >= 1 && weekday <= 7 else { return "Unknown" }
        return names[weekday - 1]
    }
}

/// A log entry for one completed blocking session.
/// timeSaved = sessionDuration - totalUnlockMinutes
@Model
final class SessionLog {
    var date: Date
    /// Total minutes the session ran.
    var sessionDuration: Int
    /// Minutes spent unlocked during the session.
    var totalUnlockMinutes: Int

    var timeSaved: Int { sessionDuration - totalUnlockMinutes }

    init(date: Date, sessionDuration: Int, totalUnlockMinutes: Int) {
        self.date = date
        self.sessionDuration = sessionDuration
        self.totalUnlockMinutes = totalUnlockMinutes
    }
}
