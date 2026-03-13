import SwiftUI

struct TaskLibraryView: View {
    @EnvironmentObject private var taskRepository: TaskRepository
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var isPresentingEditor: Bool = false
    @State private var editingTask: TaskItem?
    @State private var errorMessage: String?
    @State private var selectedDuration: TaskDurationFilter = .all
    
    enum TaskDurationFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case twoMinutes = "2 min"
        case fiveMinutes = "5 min"
        case tenMinutes = "10 min"
        
        var id: Self { self }
    }

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                ForEach(TaskDurationFilter.allCases) { filter in
                    filterButton(for: filter)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)

            List {
                ForEach(filteredTasks) { task in
                    Button {
                        editingTask = task
                        isPresentingEditor = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.body)
                            Text("\(task.durationMinutes) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Task Library")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingTask = nil
                    isPresentingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            TaskEditorView(existingTask: editingTask)
        }
    }

    private var filteredTasks: [TaskItem] {
        taskRepository.tasks.filter { task in
            switch selectedDuration {
            case .all:
                return true
            case .twoMinutes:
                return task.durationMinutes == 2
            case .fiveMinutes:
                return task.durationMinutes == 5
            case .tenMinutes:
                return task.durationMinutes == 10
            }
        }
    }

    private func filterButton(for filter: TaskDurationFilter) -> some View {
        let isSelected = selectedDuration == filter
        
        let backgroundColor = isSelected ? Color.accentColor : Color(.systemGray6)
        let foregroundColor = isSelected ? Color.white : Color.primary

        return Button {
            selectedDuration = filter
        } label: {
            Text(filter.rawValue)
                .padding(.vertical, 8)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
#Preview {
    TaskLibraryView()
        .environmentObject(TaskRepository())
        .environmentObject(AuthViewModel())
}

