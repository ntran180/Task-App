import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var taskRepository: TaskRepository

    let existingTask: TaskItem?

    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var durationMinutes: Int = 5
    @State private var isArchived: Bool = false

    @State private var errorMessage: String?
    @State private var selectedLocation: LocationType = .home
    @State private var customLocationName: String = ""

    init(existingTask: TaskItem?) {
        self.existingTask = existingTask
        _title = State(initialValue: existingTask?.title ?? "")
        _descriptionText = State(initialValue: existingTask?.description ?? "")
        _durationMinutes = State(initialValue: existingTask?.durationMinutes ?? 5)
        _isArchived = State(initialValue: existingTask?.isArchived ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section(header: Text("Duration")) {
                    Picker("Duration", selection: $durationMinutes) {
                        ForEach([2, 5, 10], id: \.self) { minutes in
                            Text("\(minutes) minutes")
                                .tag(minutes)
                        }
                    }
                }
                /* hard coded locations for now
                 in the future we can have locations like
                 addresses in order to have more percise tracking */
                
                Section(header: Text("Location")) {
                    Picker("Location", selection: $selectedLocation) {
                        ForEach(LocationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as LocationType)
                        }
                    }
                    if selectedLocation == .custom {
                        TextField("Enter location", text: $customLocationName)
                    }
                }
                

                if existingTask != nil {
                    Section {
                        Toggle("Archived", isOn: $isArchived)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(existingTask == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() async {
        errorMessage = nil
        guard authViewModel.user != nil else {
            dismiss()
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var task = existingTask ?? TaskItem(
            id: UUID().uuidString,
            title: trimmedTitle,
            description: descriptionText.isEmpty ? nil : descriptionText,
            durationMinutes: durationMinutes
        )

        task.title = trimmedTitle
        task.description = descriptionText.isEmpty ? nil : descriptionText
        task.durationMinutes = durationMinutes
        task.isArchived = isArchived

        if authViewModel.isDemoUser {
            taskRepository.createOrUpdateTaskLocally(task)
            dismiss()
            return
        }

        guard let uid = authViewModel.user?.id else { return }
        do {
            if existingTask == nil {
                try await FirestoreService.shared.createTask(task, uid: uid)
            } else {
                try await FirestoreService.shared.updateTask(task, uid: uid)
            }
            dismiss()
        } catch {
            errorMessage = "Save failed. Add Firebase config and try again."
            print("Save task error: \(error)")
        }
    }
}

#Preview {
    TaskEditorView(existingTask: TaskItem(
        id: UUID().uuidString,
        title: "Study",
        description: "Review lecture notes",
        durationMinutes: 25
    ))
    .environmentObject(AuthViewModel())
    .environmentObject(TaskRepository())
}


