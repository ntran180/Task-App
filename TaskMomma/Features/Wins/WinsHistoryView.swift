import SwiftUI

struct WinsHistoryView: View {
    @EnvironmentObject private var taskRepository: TaskRepository

    var body: some View {
        List {
            if taskRepository.wins.isEmpty {
                Section {
                    Text("No wins yet. Complete a tiny task to see your history here.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Section(header: Text("Stats")) {
                    Text("Total wins: \(taskRepository.wins.count)")
                    Text("This week: \(winsThisWeek.count)")
                    Text("Total time reclaimed: \(formattedMinutes(totalMinutes))")
                    Text("This week’s time reclaimed: \(formattedMinutes(weekMinutes))")
                }

                ForEach(groupedByDay.keys.sorted(by: >), id: \.self) { day in
                    Section(header: Text(day.formatted(date: .abbreviated, time: .omitted))) {
                        ForEach(groupedByDay[day] ?? []) { win in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(win.taskTitle)
                                    .font(.body)
                                Text(win.completedAt, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Wins")
    }

    private var groupedByDay: [Date: [Win]] {
        Dictionary(grouping: taskRepository.wins) { win in
            Calendar.current.startOfDay(for: win.completedAt)
        }
    }

    private var winsThisWeek: [Win] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return []
        }
        return taskRepository.wins.filter { $0.completedAt >= weekAgo }
    }
    
    private var totalMinutes: Int {
        taskRepository.wins.reduce(0) { sum, win in
            sum + (win.durationActual ?? 0)
        }
    }

    private var weekMinutes: Int {
        winsThisWeek.reduce(0) { sum, win in
            sum + (win.durationActual ?? 0)
        }
    }
    
    private func formattedMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}
#Preview {
    WinsHistoryView()
        .environmentObject(TaskRepository())
}
