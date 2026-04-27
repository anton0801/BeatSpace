import Foundation
import SwiftUI

final class AuthViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    init() {
        if UserDefaults.standard.bool(forKey: StorageKeys.isAuthed),
           let u = Persistence.load(AppUser.self, key: StorageKeys.user) {
            self.user = u
            self.isAuthenticated = true
        }
    }

    func signUp(name: String, email: String, password: String) -> Bool {
        errorMessage = nil
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name"
            return false
        }
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email"
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        isLoading = true
        let newUser = AppUser(
            id: UUID(),
            name: name,
            email: email,
            xp: 0,
            joinedAt: Date(),
            isGuest: false,
            isDemo: false
        )
        persist(newUser)
        isLoading = false
        return true
    }

    func login(email: String, password: String) -> Bool {
        errorMessage = nil
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email"
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        isLoading = true
        let name = email.split(separator: "@").first.map(String.init)?.capitalized ?? "Listener"
        let u = AppUser(
            id: UUID(),
            name: name,
            email: email,
            xp: 120,
            joinedAt: Date().addingTimeInterval(-60 * 60 * 24 * 7),
            isGuest: false,
            isDemo: false
        )
        persist(u)
        isLoading = false
        return true
    }

    func loginSocial(provider: String) {
        let u = AppUser(
            id: UUID(),
            name: "\(provider) User",
            email: "user@\(provider.lowercased()).com",
            xp: 60,
            joinedAt: Date(),
            isGuest: false,
            isDemo: false
        )
        persist(u)
    }

    func loginDemo() {
        persist(.demo)
    }

    func continueAsGuest() {
        persist(.guest)
    }

    func logout() {
        user = nil
        isAuthenticated = false
        UserDefaults.standard.set(false, forKey: StorageKeys.isAuthed)
        Persistence.remove(key: StorageKeys.user)
    }

    func deleteAccount() {
        logout()
        // Clear app data
        [StorageKeys.favorites,
         StorageKeys.downloads,
         StorageKeys.playlists,
         StorageKeys.activity,
         StorageKeys.notifications,
         StorageKeys.listenedSeconds,
         StorageKeys.moodCounts].forEach { Persistence.remove(key: $0) }
    }

    func updateName(_ newName: String) {
        guard var u = user else { return }
        u.name = newName.trimmingCharacters(in: .whitespaces)
        persist(u)
    }

    func addXP(_ amount: Int) {
        guard var u = user else { return }
        u.xp += amount
        persist(u)
    }

    private func persist(_ u: AppUser) {
        user = u
        isAuthenticated = true
        Persistence.save(u, key: StorageKeys.user)
        UserDefaults.standard.set(true, forKey: StorageKeys.isAuthed)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
}
