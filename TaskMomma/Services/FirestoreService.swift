import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum FirestoreServiceError: Error {
    case firebaseNotLinked
    case missingUser
    case invalidData
}

/// Abstraction over Firestore.
final class FirestoreService {
    static let shared = FirestoreService()

    private init() {}

    #if canImport(FirebaseFirestore)
    private var db: FirebaseFirestore.Firestore { FirebaseFirestore.Firestore.firestore() }

    private func userDoc(uid: String) -> FirebaseFirestore.DocumentReference {
        db.collection("users").document(uid)
    }

    private func usersCollection() -> FirebaseFirestore.CollectionReference {
        db.collection("users")
    }

    private func tasksCollection(uid: String) -> FirebaseFirestore.CollectionReference {
        userDoc(uid: uid).collection("tasks")
    }

    private func winsCollection(uid: String) -> FirebaseFirestore.CollectionReference {
        userDoc(uid: uid).collection("wins")
    }
    #endif

    // MARK: - Tasks

    func fetchTasks(uid: String) async throws -> [TaskItem] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await tasksCollection(uid: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            TaskItem(id: doc.documentID, data: doc.data())
        }
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    func createTask(_ task: TaskItem, uid: String) async throws {
        #if canImport(FirebaseFirestore)
        try await tasksCollection(uid: uid).document(task.id).setData(task.firestoreData, merge: false)
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    func updateTask(_ task: TaskItem, uid: String) async throws {
        #if canImport(FirebaseFirestore)
        try await tasksCollection(uid: uid).document(task.id).setData(task.firestoreData, merge: true)
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    func archiveTask(taskId: String, uid: String) async throws {
        #if canImport(FirebaseFirestore)
        try await tasksCollection(uid: uid).document(taskId).updateData(["isArchived": true])
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }
    
    func restoreTask(taskId: String, uid: String) async throws {
        #if canImport(FirebaseFirestore)
        try await tasksCollection(uid: uid).document(taskId).updateData(["isArchived": false])
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    // MARK: - Wins

    func logWin(_ win: Win, uid: String) async throws {
        #if canImport(FirebaseFirestore)
        let winRef = winsCollection(uid: uid).document(win.id)
        try await winRef.setData(win.firestoreData, merge: false)

        let userRef = userDoc(uid: uid)
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(userRef)
                let current = snapshot.data()?["totalWins"] as? Int ?? 0
                transaction.updateData(["totalWins": current + 1], forDocument: userRef)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    func fetchWins(uid: String) async throws -> [Win] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await winsCollection(uid: uid)
            .order(by: "completedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            Win(id: doc.documentID, data: doc.data())
        }
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    // MARK: - Realtime listeners

    #if canImport(FirebaseFirestore)
    func listenTasks(uid: String, onChange: @escaping ([TaskItem]) -> Void) -> FirebaseFirestore.ListenerRegistration {
        tasksCollection(uid: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { doc in
                    TaskItem(id: doc.documentID, data: doc.data())
                } ?? []
                onChange(items)
            }
    }

    func listenWins(uid: String, onChange: @escaping ([Win]) -> Void) -> FirebaseFirestore.ListenerRegistration {
        winsCollection(uid: uid)
            .order(by: "completedAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { doc in
                    Win(id: doc.documentID, data: doc.data())
                } ?? []
                onChange(items)
            }
    }

    func listenUserProfile(uid: String, onChange: @escaping (UserProfile?) -> Void) -> FirebaseFirestore.ListenerRegistration {
        userDoc(uid: uid).addSnapshotListener { snapshot, _ in
            guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                onChange(nil)
                return
            }
            onChange(UserProfile(id: snapshot.documentID, data: data))
        }
    }
    #endif

    // MARK: - Bootstrap / seeding

    func ensureUserProfile(uid: String, displayName: String) async throws {
        #if canImport(FirebaseFirestore)
        let ref = userDoc(uid: uid)
        let snap = try await ref.getDocument()
        if snap.exists { return }
        let profile = UserProfile(id: uid, displayName: displayName, totalWins: 0, onboardedAt: Date())
        try await ref.setData(profile.firestoreData, merge: false)
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    func seedDefaultTasksIfNeeded(uid: String) async throws {
        #if canImport(FirebaseFirestore)
        // Only skip seeding if there is at least one ACTIVE (not archived) task.
        let existingActive = try await tasksCollection(uid: uid)
            .whereField("isArchived", isEqualTo: false)
            .limit(to: 1)
            .getDocuments()
        guard existingActive.documents.isEmpty else { return }

        let defaults: [TaskItem] = [
            TaskItem(id: UUID().uuidString, title: "Drink a glass of water", description: nil, durationMinutes: 2),
            TaskItem(id: UUID().uuidString, title: "Tidy one surface", description: "Desk, counter, or nightstand—just one.", durationMinutes: 2),
            TaskItem(id: UUID().uuidString, title: "Send one thoughtful text", description: "Quick check-in with someone you care about.", durationMinutes: 2),
            TaskItem(id: UUID().uuidString, title: "Stretch your shoulders", description: "Slow rolls + a deep breath.", durationMinutes: 2),

            TaskItem(id: UUID().uuidString, title: "Walk for 5 minutes", description: "Inside or outside—just move.", durationMinutes: 5),
            TaskItem(id: UUID().uuidString, title: "Clear 10 photos", description: "Delete screenshots and duplicates.", durationMinutes: 5),
            TaskItem(id: UUID().uuidString, title: "Prep tomorrow’s outfit", description: nil, durationMinutes: 5),

            TaskItem(id: UUID().uuidString, title: "Do a quick room reset", description: "Put 10 items back where they belong.", durationMinutes: 10),
            TaskItem(id: UUID().uuidString, title: "Plan your top 3 priorities", description: "Write them down somewhere visible.", durationMinutes: 10),
            TaskItem(id: UUID().uuidString, title: "Learn one tiny thing", description: "Read one article or watch a short tutorial.", durationMinutes: 10)
        ]

        let batch = db.batch()
        for task in defaults {
            batch.setData(task.firestoreData, forDocument: tasksCollection(uid: uid).document(task.id), merge: false)
        }
        try await batch.commit()
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    // MARK: - Profile updates

    func updateDisplayName(uid: String, displayName: String) async throws {
        #if canImport(FirebaseFirestore)
        try await userDoc(uid: uid).setData(["displayName": displayName], merge: true)
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }

    // MARK: - Leaderboard

    func fetchLeaderboard(limit: Int = 50) async throws -> [UserProfile] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await usersCollection()
            .order(by: "totalWins", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            UserProfile(id: doc.documentID, data: doc.data())
        }
        #else
        throw FirestoreServiceError.firebaseNotLinked
        #endif
    }
}

