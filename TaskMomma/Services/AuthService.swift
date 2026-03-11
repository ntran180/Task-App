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

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if canImport(CryptoKit)
import CryptoKit
#endif

enum AuthServiceError: Error {
    case firebaseNotLinked
    case missingNonce
    case invalidAppleToken
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

    // MARK: - Sign In with Apple

    #if canImport(AuthenticationServices)
    private var currentNonce: String? {
        get { UserDefaults.standard.string(forKey: "taskmomma.apple.nonce") }
        set { UserDefaults.standard.setValue(newValue, forKey: "taskmomma.apple.nonce") }
    }

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func signInWithApple(result: Result<ASAuthorization, Error>) async throws {
        #if canImport(FirebaseAuth)
        switch result {
        case .failure(let error):
            throw error
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthServiceError.invalidAppleToken
            }
            try await signInWithAppleCredential(credential)
        }
        #else
        throw AuthServiceError.firebaseNotLinked
        #endif
    }

    private func signInWithAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async throws {
        #if canImport(FirebaseAuth)
        guard let nonce = currentNonce else { throw AuthServiceError.missingNonce }
        guard let tokenData = credential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            throw AuthServiceError.invalidAppleToken
        }

        let oauthCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
        _ = try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: oauthCredential) { result, error in
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
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                UInt8.random(in: 0...255)
            }
            randoms.forEach { random in
                if remaining == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        #if canImport(CryptoKit)
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
        #else
        return input
        #endif
    }
    #endif

    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw AuthServiceError.firebaseNotLinked
        #endif
    }
}

