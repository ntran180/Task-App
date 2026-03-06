import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Task-Momma")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Tiny tasks. Big wins.")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))

                ProgressView()
                    .tint(.white)
                    .padding(.top, 8)
            }
            .padding()
        }
    }
}
#Preview {
    SplashView()
}

