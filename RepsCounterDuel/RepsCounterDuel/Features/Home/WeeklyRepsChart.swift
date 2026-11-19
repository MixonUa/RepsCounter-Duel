import SwiftUI
import Backend
import DesignSystem

/// FIGMA Home "This week" chart: seven columns Mon–Sun. Values sit in one row above the bars;
/// past days with reps are light-blue bars, today is accent, days without reps (and future days)
/// are small gray pills; today's pill is accent and shows "0" (first launch).
struct WeeklyRepsChart: View {
    let week: WeekSummary

    /// FIGMA: tallest bar 95 pt; with no reps at all the bar area collapses to the pills.
    private var barAreaHeight: CGFloat { maxReps > 0 ? 95 : 24 }
    private var maxReps: Int { week.days.map(\.reps).max() ?? 0 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(week.days) { day in
                column(day)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private func column(_ day: WeekDayReps) -> some View {
        VStack(spacing: RCSpacing.xs) {
            Text(day.reps > 0 || day.isToday ? "\(day.reps)" : " ")
                .font(.system(size: 12, weight: day.isToday ? .semibold : .medium))
                .monospacedDigit()
                .foregroundStyle(day.isToday ? RCColor.textPrimary : RCColor.textSecondary)
                .frame(height: 16)

            ZStack(alignment: .bottom) {
                Color.clear
                bar(day)
            }
            .frame(height: barAreaHeight)

            Text(Self.weekdayFormatter.string(from: day.date))
                .font(.system(size: 12, weight: day.isToday ? .semibold : .regular))
                .foregroundStyle(day.isToday ? RCColor.textPrimary : RCColor.textSecondary)
        }
    }

    @ViewBuilder
    private func bar(_ day: WeekDayReps) -> some View {
        if day.reps > 0, maxReps > 0 {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(day.isToday ? RCColor.accent : RCColor.chartPastBar)
                .frame(width: 21, height: max(20, barAreaHeight * CGFloat(day.reps) / CGFloat(maxReps)))
        } else {
            Capsule()
                .fill(day.isToday ? RCColor.accent : RCColor.chartEmptyPill)
                .frame(width: 20, height: 6)
        }
    }

    private var accessibilitySummary: String {
        week.days
            .filter { !$0.isFuture }
            .map { "\(Self.weekdayFormatter.string(from: $0.date)) \($0.reps)" }
            .joined(separator: ", ")
    }

    /// English-only app: fixed locale.
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter
    }()
}

/// FIGMA: "26 Aug - 1 Sep 2026".
enum WeekRangeFormatter {
    static func string(from start: Date, to end: Date) -> String {
        "\(dayMonth.string(from: start)) - \(dayMonthYear.string(from: end))"
    }

    private static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    private static let dayMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
}
