import SwiftUI

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [UserProfile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func load(currentUser: UserProfile?, isDemo: Bool) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if isDemo {
            entries = Self.demoEntries(currentUser: currentUser)
            return
        }

        do {
            var fetched = try await FirestoreService.shared.fetchLeaderboard(limit: 50)

            // Ensure the current user is always included in the leaderboard.
            if let currentUser {
                if let idx = fetched.firstIndex(where: { $0.id == currentUser.id }) {
                    // Prefer the freshest totalWins from the profile listener if it is higher.
                    if currentUser.totalWins > fetched[idx].totalWins {
                        fetched[idx].totalWins = currentUser.totalWins
                    }
                } else {
                    fetched.append(currentUser)
                }
            }

            entries = Self.sortEntries(fetched)
        } catch {
            errorMessage = "Couldn’t load leaderboard. Add Firebase config and try again."
            entries = []
            print("Leaderboard load error: \(error)")
        }
    }

    private static func demoEntries(currentUser: UserProfile?) -> [UserProfile] {
        let me = currentUser ?? UserProfile(id: "demo", displayName: "Test User", totalWins: 0)
        let base = max(me.totalWins, 3)

        let others: [UserProfile] = [
            UserProfile(id: "u1", displayName: "Alex", totalWins: base + 9),
            UserProfile(id: "u2", displayName: "Sam", totalWins: base + 6),
            UserProfile(id: "u3", displayName: "Jordan", totalWins: base + 4),
            UserProfile(id: "u4", displayName: "Taylor", totalWins: base + 2),
            UserProfile(id: "u5", displayName: "Riley", totalWins: max(0, base - 1)),
            UserProfile(id: me.id, displayName: me.displayName, totalWins: base),
        ]

        // Ensure sorted (and de-duped if currentUser overlaps)
        return sortEntries(others)
    }

    private static func sortEntries(_ entries: [UserProfile]) -> [UserProfile] {
        var unique: [String: UserProfile] = [:]
        for p in entries {
            unique[p.id] = p
        }
        return unique.values.sorted { lhs, rhs in
            if lhs.totalWins != rhs.totalWins { return lhs.totalWins > rhs.totalWins }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
}

struct LeaderboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        List {
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Section {
                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { idx, entry in
                    LeaderboardRow(
                        rank: idx + 1,
                        name: entry.displayName,
                        wins: entry.totalWins,
                        isMe: entry.id == authViewModel.user?.id
                    )
                }
            } header: {
                Text("All-time wins")
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.entries.isEmpty && viewModel.errorMessage == nil {
                ContentUnavailableView("No leaderboard yet", systemImage: "trophy", description: Text("Complete a task to start climbing."))
            }
        }
        .navigationTitle("Leaderboard")
        .task {
            await viewModel.load(currentUser: authViewModel.user, isDemo: authViewModel.isDemoUser)
        }
        .refreshable {
            await viewModel.load(currentUser: authViewModel.user, isDemo: authViewModel.isDemoUser)
        }
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let wins: Int
    let isMe: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline)
                .frame(width: 28, alignment: .leading)
                .foregroundStyle(rank <= 3 ? .primary : .secondary)

            Text(name)
                .font(.body.weight(isMe ? .semibold : .regular))

            Spacer()

            Text("\(wins)")
                .font(.headline)
                .monospacedDigit()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isMe ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12), in: Capsule())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rank). \(name). \(wins) wins.")
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
            .environmentObject(AuthViewModel())
    }
}

