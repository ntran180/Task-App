import SwiftUI

struct FriendsView: View {
    @AppStorage("friends_list_v1") private var friendsStorage: String = "[]"
    @State private var friends: [String] = []
    @State private var newFriendName: String = ""

    var body: some View {
        List {
            Section(header: Text("Add friend")) {
                HStack {
                    TextField("Friend's name", text: $newFriendName)
                        .textInputAutocapitalization(.words)

                    Button("Add") {
                        addFriend()
                    }
                    .disabled(newFriendName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section(header: Text("Your friends")) {
                if friends.isEmpty {
                    Text("You haven't added any friends yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(friends, id: \.self) { name in
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color.accentColor)
                            Text(name)
                        }
                    }
                    .onDelete(perform: deleteFriends)
                }
            }
        }
        .navigationTitle("Friends")
        .onAppear(perform: loadFriends)
    }

    private func loadFriends() {
        guard let data = friendsStorage.data(using: .utf8) else {
            friends = []
            return
        }
        do {
            friends = try JSONDecoder().decode([String].self, from: data)
        } catch {
            friends = []
        }
    }

    private func persistFriends() {
        do {
            let data = try JSONEncoder().encode(friends)
            friendsStorage = String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            // Ignore encoding errors for this simple local feature.
        }
    }

    private func addFriend() {
        let trimmed = newFriendName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !friends.contains(trimmed) {
            friends.append(trimmed)
            persistFriends()
        }
        newFriendName = ""
    }

    private func deleteFriends(at offsets: IndexSet) {
        friends.remove(atOffsets: offsets)
        persistFriends()
    }
}

#Preview {
    NavigationStack {
        FriendsView()
    }
}

