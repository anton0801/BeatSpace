import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var showSplash: Bool = true
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            withAnimation(.easeInOut(duration: 0.6)) {
                self?.showSplash = false
            }
        }
    }

    func completeOnboarding() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            hasCompletedOnboarding = true
        }
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
