import SwiftUI

struct TaskCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var taskRepository: TaskRepository

    let task: TaskItem

    @State private var remainingSeconds: Int
    @State private var isRunning: Bool = true
    @State private var timer: Timer?

    @State private var isShowingWin: Bool = false
    @State private var winNumber: Int = 0

    init(task: TaskItem) {
        self.task = task
        _remainingSeconds = State(initialValue: task.durationMinutes * 60)
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            Text(task.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            TimerRingView(progress: progress, remainingText: remainingText)
                .frame(maxWidth: 320, maxHeight: 320)

            controls

            Spacer()
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
        .fullScreenCover(isPresented: $isShowingWin) {
            WinCelebrationView(winNumber: winNumber, taskTitle: task.title) {
                dismiss()
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .imageScale(.medium)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button(isRunning ? "Pause" : "Resume") {
                isRunning.toggle()
            }
            .buttonStyle(.bordered)

            Button("Done") {
                completeTask()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.bottom)
    }

    private var progress: Double {
        let total = max(task.durationMinutes * 60, 1)
        let elapsed = total - remainingSeconds
        return Double(elapsed) / Double(total)
    }

    private var remainingText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard isRunning else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func completeTask() {
        stopTimer()
        guard let uid = authViewModel.user?.id else {
            dismiss()
            return
        }

        let total = task.durationMinutes * 60
        let actualSeconds = max(0, total - remainingSeconds)

        Task {
            winNumber = await taskRepository.recordWin(for: task, actualSeconds: actualSeconds, uid: uid)
            await taskRepository.archiveTask(taskId: task.id, uid: uid)
            isShowingWin = true
        }
    }
}

#Preview {
    TaskCardView(
        task: TaskItem(
            id: UUID().uuidString,
            title: "Session",
            description: "Edit UI",
            durationMinutes: 5
        )
    )
    .environmentObject(AuthViewModel())
    .environmentObject(TaskRepository())
}



