import SwiftUI
import Charts
import Backend
import DesignSystem

/// Bar chart: calendar day → accepted duel reps. Training reps are never included.
struct DailyDuelRepsChart: View {
    let data: [DailyDuelReps]

    var body: some View {
        if data.isEmpty {
            Text("Your daily duel reps will appear here.")
                .font(RCFont.body)
                .foregroundStyle(RCColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            Chart(data) { point in
                BarMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Reps", point.reps)
                )
                .foregroundStyle(RCColor.accent.gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .frame(height: 160)
        }
    }
}
