import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var displayNameDraft: String = ""
    @State private var isSavingName: Bool = false
    @State private var errorMessage: String?

    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                TextField("Display name", text: $displayNameDraft)
                Button("Save name") {
                    Task { await saveDisplayName() }
                }
                .disabled(isSavingName || displayNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section(header: Text("Notifications")) {
                Toggle("Daily reminder", isOn: $dailyReminderEnabled)
                    .onChange(of: dailyReminderEnabled) { _, newValue in
                        if newValue {
                            requestAndScheduleReminder()
                        } else {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_task_momma_reminder"])
                        }
                    }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button(role: .destructive) {
                    authViewModel.signOut()
                } label: {
                    Text("Sign Out")
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            displayNameDraft = authViewModel.user?.displayName ?? ""
        }
    }

    private func saveDisplayName() async {
        errorMessage = nil
        let name = displayNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        if authViewModel.isDemoUser {
            authViewModel.updateDisplayNameForDemo(name)
            return
        }

        guard let uid = authViewModel.user?.id else { return }
        isSavingName = true
        defer { isSavingName = false }

        do {
            try await FirestoreService.shared.updateDisplayName(uid: uid, displayName: name)
        } catch {
            errorMessage = "Couldn’t save name. Add Firebase config and try again."
            print("Save display name error: \(error)")
        }
    }

    private func requestAndScheduleReminder() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Tiny time, tiny win"
            content.body = "You probably have a spare 5 minutes. Open Task-Momma to grab a quick task."

            var dateComponents = DateComponents()
            dateComponents.hour = 17

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "daily_task_momma_reminder",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}
#Preview {
    SettingsView()
}

