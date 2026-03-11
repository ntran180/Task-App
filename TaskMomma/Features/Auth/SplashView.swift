import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 134/255, green: 119/255, blue: 173/255), // #8677AD
                Color(red: 169/255, green: 161/255, blue: 181/255) // #A9A1B5
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
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

