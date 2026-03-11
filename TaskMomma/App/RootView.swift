import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

    var body: some View {
        Group {
            if !authViewModel.isInitialized {
                SplashView()
            } else if authViewModel.user == nil {
                AuthFlowView()
            } else if !hasOnboarded {
                OnboardingView()
            } else {
                MainContainerView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isInitialized)
        .animation(.easeInOut, value: authViewModel.user != nil)
        .animation(.easeInOut, value: hasOnboarded)
    }
}
#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}

