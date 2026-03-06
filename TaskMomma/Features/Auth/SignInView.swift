import SwiftUI
import AuthenticationServices

private let testAccountEmail = "test@test.com"
private let testAccountPassword = "12345678"

struct SignInView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var email: String = testAccountEmail
    @State private var password: String = testAccountPassword
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Welcome to Task-Momma")
                    .font(.title.bold())

                Text("Turn spare minutes into tiny wins.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    AuthService.shared.prepareAppleRequest(request)
                } onCompletion: { result in
                    Task {
                        await signInWithApple(result)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)

                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.secondary.opacity(0.3))
                }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                Button {
                    Task {
                        await signInWithEmail()
                    }
                } label: {
                    Text("Sign in with Email")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func signInWithApple(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AuthService.shared.signInWithApple(result: result)
        } catch {
            errorMessage = "Sign in failed. Please try again."
            print("Apple sign-in error: \(error)")
        }
    }

    private func signInWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }

        // Test account: see full UI without Firebase
        if email == testAccountEmail && password == testAccountPassword {
            authViewModel.signInWithTestAccount()
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AuthService.shared.signInWithEmail(email: email, password: password)
        } catch {
            errorMessage = "Sign in failed. Check your email and password."
            print("Email sign-in error: \(error)")
        }
    }
}
#Preview {
    SignInView()
}

