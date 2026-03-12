import SwiftUI

struct TaskLibraryView: View {
    @EnvironmentObject private var taskRepository: TaskRepository
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var showArchived: Bool = false
    @State private var isPresentingEditor: Bool = false
    @State private var editingTask: TaskItem?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Toggle(isOn: $showArchived) {
                Text(showArchived ? "Showing archived" : "Showing active")
            }
            .padding(.horizontal)
            .padding(.top)

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
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if showArchived {
                            Button("Restore") {
                                restore(task)
                            }.tint(.green)
                        } else {
                            Button("Archive") {
                                archive(task)
                            }.tint(.orange)
                        }
                    }
                }
//                .onDelete(perform: handleRowAction)
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
            showArchived ? task.isArchived : !task.isArchived
        }
    }

    private func archive(at offsets: IndexSet) {
        errorMessage = nil
        guard authViewModel.user != nil else { return }

        if authViewModel.isDemoUser {
            for index in offsets {
                let task = filteredTasks[index]
                taskRepository.archiveTaskLocally(taskId: task.id)
            }
            return
        }

        guard let uid = authViewModel.user?.id else { return }
        for index in offsets {
            let task = filteredTasks[index]
            Task {
                do {
                    try await FirestoreService.shared.archiveTask(taskId: task.id, uid: uid)
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to archive. Add Firebase config and try again."
                    }
                }
            }
        }
    }
    
    private func restore(at offsets: IndexSet) {
        errorMessage = nil
        guard authViewModel.user != nil else { return }
        if authViewModel.isDemoUser {
            for index in offsets {
                let task = filteredTasks[index]
                taskRepository.archiveTaskLocally(taskId: task.id)
            }
            return
        }
        
        guard let uid = authViewModel.user?.id else { return }
        for index in offsets {
            let task = filteredTasks[index]
            Task {
                do {
                    try await FirestoreService.shared.restoreTask(taskId: task.id, uid: uid)
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to restore. Add Firebase confic and try again."
                    }
                }
            }
        }
    }
    
    private func archive(_ task: TaskItem) {
        errorMessage = nil
        guard let uid = authViewModel.user?.id else { return }
    
        Task {
            await taskRepository.archiveTask(taskId: task.id, uid: uid)
        }
    }
    
    private func restore(_ task: TaskItem) {
        errorMessage = nil
        guard let uid = authViewModel.user?.id else { return }
        Task {
            await taskRepository.restoreTask(taskId: task.id, uid: uid)
        }
    }
    
//    private func handleRowAction(at offsets: IndexSet) {
//        if showArchived {
//            restore(at: offsets)
//        } else {
//            archive(at: offsets)
//        }
//    }
    
}
#Preview {
    TaskLibraryView()
        .environmentObject(TaskRepository())
        .environmentObject(AuthViewModel())
}

