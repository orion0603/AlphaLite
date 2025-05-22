import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var memoryStore: MemoryStore
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Weekly Summary")) {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                        activityChart
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("Statistics")) {
                    StatRow(title: "Total Messages", value: "\(memoryStore.analytics.getWeeklySummary().messageCount)")
                    StatRow(title: "Total Memories", value: "\(memoryStore.analytics.getWeeklySummary().memoryCount)")
                    StatRow(title: "Total Reminders", value: "\(memoryStore.analytics.getWeeklySummary().reminderCount)")
                    StatRow(title: "Average Response Time", value: formatTime(memoryStore.analytics.getWeeklySummary().averageResponseTime))
                }
                
                Section(header: Text("Export Data")) {
                    Button(action: exportData) {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Weekly Assistant Summary")
                .font(.headline)
            
            Text("Most active on \(formatDate(memoryStore.analytics.getWeeklySummary().mostActiveDay))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var activityChart: some View {
        Chart {
            ForEach(getActivityData(), id: \.date) { data in
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Activity", data.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday())
            }
        }
    }
    
    private func getActivityData() -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        return calendar.generateDates(
            inside: DateInterval(start: weekAgo, end: today),
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        ).map { date in
            (date: date, count: memoryStore.analytics.getWeeklySummary().messageCount / 7)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? "0s"
    }
    
    private func exportData() {
        if let data = memoryStore.exportData() {
            // Handle data export
            // This would typically involve sharing the data or saving it to a file
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date <= interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(MemoryStore(gptService: GPTService()))
} 