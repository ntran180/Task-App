import Foundation
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

/// Demo user ID used when signing in with test@test.com (no Firebase).
fileprivate let demoUserID = "demo"

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

    /// Sign in with the test account (test@test.com / 12345678). Works without Firebase so you can see the full UI.
    func signInWithTestAccount() {
        user = UserProfile(id: demoUserID, displayName: "Test User", totalWins: 0)
        isInitialized = true
    }

    var isDemoUser: Bool { user?.id == demoUserID }

    /// Updates display name for the demo account only (no Firestore).
    func updateDisplayNameForDemo(_ name: String) {
        guard isDemoUser, var u = user else { return }
        u.displayName = name
        user = u
    }

    func signOut() {
        if user?.id == demoUserID {
            user = nil
            return
        }
        do {
            try AuthService.shared.signOut()
            user = nil
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

        if uid == demoUserID {
            await loadInitialData(for: uid)
            return
        }

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
        if uid == demoUserID {
            tasks = Self.demoTasks()
            wins = []
            return
        }
        do {
            let fetchedTasks = try await FirestoreService.shared.fetchTasks(uid: uid)
            let fetchedWins = try await FirestoreService.shared.fetchWins(uid: uid)
            tasks = fetchedTasks
            wins = fetchedWins
        } catch {
            print("Failed to load data: \(error)")
        }
    }

    /// Default tasks for the demo account (no backend).
    private static func demoTasks() -> [TaskItem] {
        [
            TaskItem(id: "d1", title: "Drink a glass of water", description: nil, durationMinutes: 2),
            TaskItem(id: "d2", title: "Tidy one surface", description: "Desk, counter, or nightstand.", durationMinutes: 2),
            TaskItem(id: "d3", title: "Stretch your shoulders", description: "Slow rolls + a deep breath.", durationMinutes: 2),
            TaskItem(id: "d4", title: "Walk for 5 minutes", description: "Inside or outside—just move.", durationMinutes: 5),
            TaskItem(id: "d5", title: "Clear 10 photos", description: "Delete screenshots and duplicates.", durationMinutes: 5),
            TaskItem(id: "d6", title: "Prep tomorrow's outfit", description: nil, durationMinutes: 5),
            TaskItem(id: "d7", title: "Do a quick room reset", description: "Put 10 items back where they belong.", durationMinutes: 10),
            TaskItem(id: "d8", title: "Plan your top 3 priorities", description: "Write them down somewhere visible.", durationMinutes: 10),
        ]
    }

    func activeTasks(for durationMinutes: Int) -> [TaskItem] {
        tasks.filter { !$0.isArchived && $0.durationMinutes == durationMinutes }
    }
    
    func allActiveTasks() -> [TaskItem] {
        tasks.filter { !$0.isArchived }
    }
    
    func allArchivedTasks() -> [TaskItem] {
        tasks.filter { $0.isArchived}
    }
    
    func archiveTask(taskId: String, uid: String) async {
        if let i = tasks.firstIndex(where: { $0.id == taskId}) {
            tasks[i].isArchived = true
        }
        if uid == demoUserID {
            return
        }
        do {
            try await FirestoreService.shared.archiveTask(taskId: taskId, uid: uid)
        } catch {
            print("Failed to archive task: \(error)")
        }
    }
    
    func restoreTask(taskId: String, uid: String) async {
        if let i = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[i].isArchived = false
        }
        if uid == demoUserID {
            return
        }
        do {
            try await FirestoreService.shared.restoreTask(taskId: taskId, uid: uid)
        } catch {
            print("Failed to restore task: \(error)")
        }
    }

    func recordWin(for task: TaskItem, actualSeconds: Int?, uid: String) async -> Int {
        let win = Win(id: UUID().uuidString, taskId: task.id, taskTitle: task.title, completedAt: Date(), durationActual: actualSeconds)
        let predictedCount = wins.count + 1
        if uid == demoUserID {
            wins.insert(win, at: 0)
            return predictedCount
        }
        do {
            try await FirestoreService.shared.logWin(win, uid: uid)
            self.wins.insert(win, at: 0)
        } catch {
            print("Failed to log win: \(error)")
        }
        return predictedCount
    }

    // MARK: - Demo-only local updates (no Firestore)

    func archiveTaskLocally(taskId: String) {
        if let i = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[i].isArchived = true
        }
    }

    func createOrUpdateTaskLocally(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[i] = task
        } else {
            tasks.append(task)
        }
    }
}

