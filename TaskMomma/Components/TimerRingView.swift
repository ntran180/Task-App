import SwiftUI

struct TimerRingView: View {
    let progress: Double // 0.0 - 1.0
    let remainingText: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 16)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .blue, .purple]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            Text(remainingText)
                .font(.title2.monospacedDigit())
        }
        .padding(32)
    }
}

