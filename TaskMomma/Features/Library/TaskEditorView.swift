import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    let existingTask: TaskItem?

    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var durationMinutes: Int = 5
    @State private var isArchived: Bool = false

    @State private var errorMessage: String?

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
        guard let uid = authViewModel.user?.id else {
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

