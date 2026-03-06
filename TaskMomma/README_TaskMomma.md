## Task-Momma (SwiftUI + Firebase)

This repo contains the SwiftUI source code for **Task-Momma**, a “tiny task randomizer” app backed by **Firebase Auth** + **Firestore**.

### Run on simulator (no Firebase yet)

1. Open **`TaskMomma.xcodeproj`** in Xcode (it’s in the repo root, next to the `TaskMomma/` source folder).
2. Choose an iPhone simulator (e.g. iPhone 16) and press **Run** (⌘R).
3. The app will build and launch. You’ll see Splash → Sign In (Firebase isn’t linked yet, so sign-in won’t complete until you add Firebase and `GoogleService-Info.plist`).

### What’s implemented

- **10 screens**: Splash/Auth Gate, Onboarding, Sign In, Home, Task Card (timer), Win Screen, Task Library, Add/Edit Task, Wins History, Settings.
- **Firestore service**: tasks + wins CRUD, win logging transaction (increments `totalWins`), snapshot listeners, seed default tasks.
- **Auth service**: Email/Password (sign-in or create), Sign In with Apple (Firebase Auth) + automatic user bootstrap.
- **Notifications**: local daily reminder toggle.

### Firebase setup (Xcode)

1. Use the existing **TaskMomma.xcodeproj** (or create a new iOS 17+ app and add the `TaskMomma/` folder to the target).
2. Add Firebase via Swift Package Manager:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseCore`
3. Add your `GoogleService-Info.plist` to the app target.
4. In Xcode “Signing & Capabilities”, add **Sign In with Apple**.
5. Run the app. On first sign-in, it will:
   - Create `/users/{uid}` if missing
   - Seed default tasks into `/users/{uid}/tasks`

### Firestore schema

- `/users/{uid}`
  - `displayName: String`
  - `totalWins: Int`
  - `onboardedAt: Timestamp`
- `/users/{uid}/tasks/{taskId}`
  - `title: String`
  - `description: String?`
  - `durationMinutes: Int` (2/5/10)
  - `categoryId: String?`
  - `createdAt: Timestamp`
  - `isArchived: Bool`
- `/users/{uid}/wins/{winId}`
  - `taskId: String`
  - `taskTitle: String`
  - `completedAt: Timestamp`
  - `durationActual: Int?` (seconds)

### HTTP/JSON requirement (optional)

Firestore uses HTTPS/JSON under the hood. If your course requires an explicit `URLSession` call, add a Cloud Function like `GET /suggest?uid=...&duration=5` and call it from a small service using `URLSession` + `Codable`.

