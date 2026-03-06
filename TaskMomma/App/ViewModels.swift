import Foundation
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class AuthViewModel: ObservableObject {
    @Published var user: UserProfile?
    @Published var isInitialized: Bool = false

    init() {
        AuthService.shared.configure()
        AuthService.shared.observeAuthChanges { [weak self] profile in
            DispatchQueue.main.async {
                self?.user = profile
                self?.isInitialized = true
            }
        }
    }

    func signOut() {
        do {
            try AuthService.shared.signOut()
        } catch {
            print("Sign out failed: \(error)")
        }
    }
}

@MainActor
final class TaskRepository: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var wins: [Win] = []

    #if canImport(FirebaseFirestore)
    private var tasksListener: ListenerRegistration?
    private var winsListener: ListenerRegistration?
    #endif

    func startListening(uid: String) async {
        stopListening()

        #if canImport(FirebaseFirestore)
        tasksListener = FirestoreService.shared.listenTasks(uid: uid) { [weak self] items in
            Task { @MainActor in
                self?.tasks = items
            }
        }
        winsListener = FirestoreService.shared.listenWins(uid: uid) { [weak self] items in
            Task { @MainActor in
                self?.wins = items
            }
        }
        #endif

        await loadInitialData(for: uid)
    }

    func stopListening() {
        #if canImport(FirebaseFirestore)
        tasksListener?.remove()
        winsListener?.remove()
        tasksListener = nil
        winsListener = nil
        #endif

        tasks = []
        wins = []
    }

    func loadInitialData(for uid: String) async {
        do {
            let fetchedTasks = try await FirestoreService.shared.fetchTasks(uid: uid)
            let fetchedWins = try await FirestoreService.shared.fetchWins(uid: uid)
            tasks = fetchedTasks
            wins = fetchedWins
        } catch {
            print("Failed to load data: \(error)")
        }
    }

    func activeTasks(for durationMinutes: Int) -> [TaskItem] {
        tasks.filter { !$0.isArchived && $0.durationMinutes == durationMinutes }
    }

    func recordWin(for task: TaskItem, actualSeconds: Int?, uid: String) async -> Int {
        let win = Win(id: UUID().uuidString, taskId: task.id, taskTitle: task.title, completedAt: Date(), durationActual: actualSeconds)
        let predictedCount = wins.count + 1
        do {
            try await FirestoreService.shared.logWin(win, uid: uid)
            // Listener will refresh; append locally for instant UI feedback.
            self.wins.insert(win, at: 0)
        } catch {
            print("Failed to log win: \(error)")
        }
        return predictedCount
    }
}

