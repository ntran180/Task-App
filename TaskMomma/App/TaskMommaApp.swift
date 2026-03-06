import SwiftUI

@main
struct TaskMommaApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var taskRepository = TaskRepository()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(taskRepository)
        }
    }
}

