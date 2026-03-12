import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var taskRepository: TaskRepository

    @State private var selectedMinutes: Int = 5
    @State private var presentingTask: TaskItem?
    @State private var isShowingTaskCard: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hi, \(authViewModel.user?.displayName ?? "friend")")
                    .font(.title.bold())

                Text("How much time do you have?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)

            DurationPicker(selectedMinutes: $selectedMinutes)
                .padding(.horizontal)

            Spacer()
            LocationLabel()

            Button {
                chooseRandomTask()
            } label: {
                VStack(spacing: 8) {
                    Text("I have \(selectedMinutes) minutes")
                        .font(.headline)
                    Text("Give me a task")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(radius: 8, y: 4)
            }
            .padding(.horizontal)

            if taskRepository.wins.isEmpty {
                Text("No wins yet — your first one is just a tiny task away.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            } else {
                Text("Total wins: \(taskRepository.wins.count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .sheet(isPresented: $isShowingTaskCard) {
            if let task = presentingTask {
                TaskCardView(task: task)
            }
        }
        .navigationTitle("Task-Momma")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func chooseRandomTask() {
        let candidates = taskRepository.activeTasks(for: selectedMinutes)
        guard !candidates.isEmpty else {
            // In a real app, show a toast or alert instead of print.
            print("No tasks for selected duration")
            return
        }
        presentingTask = candidates.randomElement()
        isShowingTaskCard = true
    }
}
#Preview {
    HomeView()
        .environmentObject(TaskRepository())
        .environmentObject(AuthViewModel())
        .environmentObject(LocationManager())
}
