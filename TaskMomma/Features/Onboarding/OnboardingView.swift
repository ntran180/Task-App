import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

    @State private var selection: Int = 0

    var body: some View {
        VStack {
            TabView(selection: $selection) {
                OnboardingPageView(
                    title: "Tiny tasks, big wins",
                    subtitle: "Fill spare minutes with small, meaningful actions.",
                    systemImage: "sparkles"
                )
                .tag(0)

                OnboardingPageView(
                    title: "Tell us your time",
                    subtitle: "Pick 2, 5, or 10 minutes and we'll suggest a task.",
                    systemImage: "timer"
                )
                .tag(1)

                OnboardingPageView(
                    title: "Celebrate the wins",
                    subtitle: "Track your streaks and see how the small stuff adds up.",
                    systemImage: "rosette"
                )
                .tag(2)
            }
            .tabViewStyle(.page)

            HStack {
                if selection < 2 {
                    Button("Skip") {
                        hasOnboarded = true
                    }
                }

                Spacer()

                Button(selection == 2 ? "Get Started" : "Next") {
                    if selection < 2 {
                        withAnimation {
                            selection += 1
                        }
                    } else {
                        hasOnboarded = true
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

private struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title.bold())

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }
}
#Preview {
    OnboardingView()
}

