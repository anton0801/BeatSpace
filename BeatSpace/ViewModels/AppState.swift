import SwiftUI
import Combine

final class AppState: ObservableObject {
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    func completeOnboarding() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            hasCompletedOnboarding = true
        }
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
