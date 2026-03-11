import SwiftUI

struct MainContainerView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var taskRepository: TaskRepository

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                TaskLibraryView()
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(1)

            NavigationStack {
                WinsHistoryView()
            }
            .tabItem {
                Label("Wins", systemImage: "rosette")
            }
            .tag(2)

//            NavigationStack {
//                LeaderboardView()
//            }
//            .tabItem {
//                Label("Leaderboard", systemImage: "trophy.fill")
//            }
//            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(4)
        }
        .task {
            if let uid = authViewModel.user?.id {
                await taskRepository.startListening(uid: uid)
            }
        }
        .onChange(of: authViewModel.user?.id) { _, newUid in
            Task {
                if let newUid {
                    await taskRepository.startListening(uid: newUid)
                } else {
                    await MainActor.run { taskRepository.stopListening() }
                }
            }
        }
    }
}
#Preview {
    MainContainerView()
        .environmentObject(TaskRepository())
        .environmentObject(AuthViewModel())
        .environmentObject(LocationManager())
    
    
}
