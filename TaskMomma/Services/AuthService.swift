import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

enum AuthServiceError: Error {
    case firebaseNotLinked
    case missingNonce
    case invalidGoogleToken
}

/// Thin wrapper around FirebaseAuth.
final class AuthService {
    static let shared = AuthService()

    private init() {}

    #if canImport(FirebaseFirestore)
    private var profileListener: ListenerRegistration?
    #endif

    func configure() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }

    func observeAuthChanges(_ onChange: @escaping (UserProfile?) -> Void) {
        #if canImport(FirebaseAuth)
        _ = Auth.auth().addStateDidChangeListener { _, user in
            guard let user else {
                #if canImport(FirebaseFirestore)
                self.profileListener?.remove()
                self.profileListener = nil
                #endif
                onChange(nil)
                return
            }

            let displayName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? "Friend"
            Task {
                do {
                    try await FirestoreService.shared.ensureUserProfile(uid: user.uid, displayName: displayName)
                    try await FirestoreService.shared.seedDefaultTasksIfNeeded(uid: user.uid)

                    #if canImport(FirebaseFirestore)
                    self.profileListener?.remove()
                    self.profileListener = FirestoreService.shared.listenUserProfile(uid: user.uid) { profile in
                        onChange(profile ?? UserProfile(id: user.uid, displayName: displayName))
                    }
                    #else
                    onChange(UserProfile(id: user.uid, displayName: displayName))
                    #endif
                } catch {
                    print("Profile bootstrap failed: \(error)")
                    onChange(UserProfile(id: user.uid, displayName: displayName))
                }
            }
        }
        #else
        onChange(nil)
        #endif
    }

    // MARK: - Email

    func signInWithEmail(email: String, password: String) async throws {
        #if canImport(FirebaseAuth)
        do {
            _ = try await signIn(email: email, password: password)
        } catch {
            // If sign-in fails, try creating an account (class-project friendly).
            _ = try await createUser(email: email, password: password)
        }
        #else
        throw AuthServiceError.firebaseNotLinked
        #endif
    }

    #if canImport(FirebaseAuth)
    private func signIn(email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result!)
            }
        }
    }

    private func createUser(email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result!)
            }
        }
    }
    #endif

    // MARK: - Sign In with Google

    func signInWithGoogle(presenting viewController: AnyObject) async throws {
        #if canImport(GoogleSignIn)
        guard let presentingVC = viewController as? UIViewController else {
            throw AuthServiceError.invalidGoogleToken
        }

        #if canImport(FirebaseCore)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthServiceError.firebaseNotLinked
        }
        #else
        throw AuthServiceError.firebaseNotLinked
        #endif

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)

        guard
            let idToken = result.user.idToken?.tokenString
        else {
            throw AuthServiceError.invalidGoogleToken
        }

        let accessToken = result.user.accessToken.tokenString

        #if canImport(FirebaseAuth)
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result!)
            }
        }
        #else
        throw AuthServiceError.firebaseNotLinked
        #endif

        #else
        throw AuthServiceError.firebaseNotLinked
        #endif
    }

    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw AuthServiceError.firebaseNotLinked
        #endif
    }
}

