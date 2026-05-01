import Foundation
import AppsFlyerLib
import Combine

final class BeatStore {
    
    private(set) var currentState: BeatState = .initial
    
    private var eventLog: [BeatEvent] = []
    private let eventLock = NSLock()
    
    private let stateSubject = PassthroughSubject<BeatState, Never>()
    var statePublisher: AnyPublisher<BeatState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    private let outcomeSubject = PassthroughSubject<BeatOutcome, Never>()
    var outcomePublisher: AnyPublisher<BeatOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    
    private let pantry: PantryProtocol
    private let verifier: VerificationProvider
    private let refresher: AttributionRefresher
    private let discoverer: EndpointDiscoverer
    private let approver: ApprovalCoordinator
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        pantry: PantryProtocol,
        verifier: VerificationProvider,
        refresher: AttributionRefresher,
        discoverer: EndpointDiscoverer,
        approver: ApprovalCoordinator
    ) {
        self.pantry = pantry
        self.verifier = verifier
        self.refresher = refresher
        self.discoverer = discoverer
        self.approver = approver
    }

    private func dispatch(_ event: BeatEvent) {
        eventLock.lock()
        eventLog.append(event)
        let newState = BeatReducer.apply(event, to: currentState)
        currentState = newState
        eventLock.unlock()
        
        projectToPantry(event: event)
        
        stateSubject.send(newState)
    }
    
    private func projectToPantry(event: BeatEvent) {
        switch event {
        case .attributionCaptured(let data):
            pantry.projectAttribution(data)
            
        case .deeplinksCaptured(let data):
            pantry.projectDeeplinks(data)
            
        case .sequenceFinalized(let url, let mode):
            pantry.projectEndpoint(url: url, mode: mode)
            pantry.markBooted()
            
        case .approvalGranted(let at):
            pantry.projectApproval(granted: true, rejected: false, lastTime: at)
            
        case .approvalRejected(let at):
            pantry.projectApproval(granted: false, rejected: true, lastTime: at)
            
        case .approvalDeferred(let at):
            pantry.projectApproval(
                granted: currentState.approvalGranted,
                rejected: currentState.approvalRejected,
                lastTime: at
            )
            
        default:
            break
        }
    }
    
    func warmUp() {
        let projection = pantry.loadProjection()
        currentState = BeatReducer.hydrate(from: projection)
        dispatch(.bootInitiated)
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        let mapped = data.mapValues { "\($0)" }
        dispatch(.attributionCaptured(mapped))
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        let mapped = data.mapValues { "\($0)" }
        dispatch(.deeplinksCaptured(mapped))
    }
    
    func notifyNetwork(connected: Bool) {
        dispatch(connected ? .networkRestored : .networkLost)
    }
    
    func runSequence() async {
        guard !sequenceCompleted else { return }
        
        if let tempURL = UserDefaults.standard.string(forKey: PantryKey.pushURL),
           !tempURL.isEmpty {
            finalizeSequence(url: tempURL)
            return
        }
        
        guard currentState.hasConversion else {
            return
        }
        
        let verificationOK = await verifyViaCombine()
        
        if !verificationOK {
            dispatch(.validationDenied("verification check failed"))
            sequenceCompleted = true
            outcomeSubject.send(.showMain)
            return
        }
        
        dispatch(.validationPassed)
        
        if currentState.organicSource && currentState.fresh && !currentState.organicMarked {
            dispatch(.organicProcessingMarked)
            await performOrganicRefetch()
        }
        
        let payloadDict = currentState.conversionData.mapValues { $0 as Any }
        let discoveryResult = await discoverer.discover(payload: payloadDict)
        
        switch discoveryResult {
        case .success(let url):
            finalizeSequence(url: url)
            
        case .failure(let error):
            dispatch(.endpointDenied)
            sequenceCompleted = true
            outcomeSubject.send(.showMain)
        }
    }
    
    func acceptApproval() async {
        let priorGranted = currentState.approvalGranted
        let priorRejected = currentState.approvalRejected
        
        let status = await withCheckedContinuation { (continuation: CheckedContinuation<ApprovalStatus, Never>) in
            var subscription: AnyCancellable?
            
            subscription = approver.statusSubject
                .first { status in
                    status == .granted || status == .rejected || status == .error
                }
                .sink { status in
                    subscription?.cancel()
                    continuation.resume(returning: status)
                }
            
            approver.solicit()
        }
        
        let now = Date()
        
        switch status {
        case .granted:
            dispatch(.approvalGranted(at: now))
            approver.register()
        case .rejected, .error:
            dispatch(.approvalRejected(at: now))
        case .pending:
            _ = priorGranted
            _ = priorRejected
            dispatch(.approvalDeferred(at: now))
        }
        
        outcomeSubject.send(.showWeb)
    }
    
    func deferApproval() {
        dispatch(.approvalDeferred(at: Date()))
        outcomeSubject.send(.showWeb)
    }
    
    func notifyTimeout() {
        guard !sequenceCompleted else {
            return
        }
        
        sequenceCompleted = true
        dispatch(.timeoutTriggered)
        outcomeSubject.send(.showMain)
    }
    
    private func verifyViaCombine() async -> Bool {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            var cancellable: AnyCancellable?
            
            cancellable = verifier.verifyPublisher()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure = completion {
                            cancellable?.cancel()
                            continuation.resume(returning: false)
                        }
                    },
                    receiveValue: { value in
                        cancellable?.cancel()
                        continuation.resume(returning: value)
                    }
                )
        }
    }
    
    private func performOrganicRefetch() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !currentState.locked else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        let result = await refresher.refresh(deviceID: deviceID)
        
        guard case .success(var fetched) = result else {
            return
        }
        
        for (k, v) in currentState.deeplinksData {
            if fetched[k] == nil {
                fetched[k] = v
            }
        }
        
        let mapped = fetched.mapValues { "\($0)" }
        dispatch(.attributionCaptured(mapped))
    }
    
    private func finalizeSequence(url: String) {
        let needsApproval = currentState.canSolicitApproval
        
        dispatch(.endpointResolved(url: url))
        dispatch(.sequenceFinalized(url: url, mode: "Active"))
        
        UserDefaults.standard.removeObject(forKey: PantryKey.pushURL)
        
        sequenceCompleted = true
        
        if needsApproval {
            dispatch(.approvalRequested)
            outcomeSubject.send(.askApproval)
        } else {
            outcomeSubject.send(.showWeb)
        }
    }
    
    func recentEvents(limit: Int = 50) -> [BeatEvent] {
        eventLock.lock()
        defer { eventLock.unlock() }
        let count = eventLog.count
        let start = max(0, count - limit)
        return Array(eventLog[start..<count])
    }
}
