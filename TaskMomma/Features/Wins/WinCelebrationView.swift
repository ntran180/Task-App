import SwiftUI

struct WinCelebrationView: View {
    let winNumber: Int
    let taskTitle: String
    var onBackToHome: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Win #\(winNumber)")
                .font(.largeTitle.bold())

            Text(taskTitle)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Nice work! Want another tiny win?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Back to Home") {
                dismiss()
                onBackToHome?()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .overlay(alignment: .top) {
            ConfettiView()
                .allowsHitTesting(false)
        }
    }
}

private struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<40, id: \.self) { index in
                Circle()
                    .fill(color(index))
                    .frame(width: 6, height: 6)
                    .position(x: CGFloat.random(in: 0...proxy.size.width),
                              y: animate ? proxy.size.height + 40 : -40)
                    .animation(
                        .interpolatingSpring(stiffness: 30, damping: 6)
                            .repeatForever()
                            .delay(Double(index) * 0.03),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
    }

    private func color(_ seed: Int) -> Color {
        let colors: [Color] = [.pink, .orange, .yellow, .green, .blue, .purple]
        return colors[seed % colors.count]
    }
}

#Preview {
    WinCelebrationView(
        winNumber: 1,
        taskTitle: "Study"
    )
}
