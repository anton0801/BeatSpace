import Foundation
import Combine

@MainActor
final class BeatSpaceViewModel: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let store: BeatStore
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        self.store = BeatStoreBuilder.defaultStore()
        wireUpPublishers()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    private func wireUpPublishers() {
        store.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.applyOutcome(outcome)
            }
            .store(in: &cancellables)
        
        store.statePublisher
            .receive(on: DispatchQueue.main)
            .map { $0.offline }
            .removeDuplicates()
            .sink { [weak self] offline in
                self?.showOfflineView = offline
            }
            .store(in: &cancellables)
    }
    
    func boot() {
        Task {
            store.warmUp()
            armDeadline()
        }
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        Task {
            store.ingestAttribution(data)
            await store.runSequence()
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        Task {
            store.ingestDeeplinks(data)
        }
    }
    
    func acceptApproval() {
        Task {
            await store.acceptApproval()
            showPermissionPrompt = false
        }
    }
    
    func deferApproval() {
        store.deferApproval()
        showPermissionPrompt = false
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        store.notifyNetwork(connected: connected)
    }
    
    private func applyOutcome(_ outcome: BeatOutcome) {
        guard !uiLocked else {
            return
        }
        
        switch outcome {
        case .continueIdle:
            break
        case .askApproval:
            showPermissionPrompt = true
        case .showWeb:
            navigateToWeb = true
        case .showMain:
            navigateToMain = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            self.store.notifyTimeout()
        }
    }
}
