import Foundation
import Combine

enum BeatEvent {
    case bootInitiated
    case attributionCaptured([String: String])
    case deeplinksCaptured([String: String])
    case organicProcessingMarked
    case validationPassed
    case validationDenied(String)
    case endpointResolved(url: String)
    case endpointDenied
    case sequenceFinalized(url: String, mode: String)
    case approvalRequested
    case approvalGranted(at: Date)
    case approvalRejected(at: Date)
    case approvalDeferred(at: Date)
    case timeoutTriggered
    case networkLost
    case networkRestored
}

struct BeatState {
    var conversionData: [String: String]
    var deeplinksData: [String: String]
    var endpointURL: String?
    var operatingMode: String?
    var fresh: Bool
    var locked: Bool
    var organicMarked: Bool
    
    var approvalGranted: Bool
    var approvalRejected: Bool
    var approvalLastTime: Date?
    
    var sequenceTerminated: Bool
    var lastError: String?
    var offline: Bool
    
    static let initial = BeatState(
        conversionData: [:],
        deeplinksData: [:],
        endpointURL: nil,
        operatingMode: nil,
        fresh: true,
        locked: false,
        organicMarked: false,
        approvalGranted: false,
        approvalRejected: false,
        approvalLastTime: nil,
        sequenceTerminated: false,
        lastError: nil,
        offline: false
    )
    
    var hasConversion: Bool { !conversionData.isEmpty }
    var organicSource: Bool { conversionData["af_status"] == "Organic" }
    
    var canSolicitApproval: Bool {
        guard !approvalGranted && !approvalRejected else { return false }
        
        if let date = approvalLastTime {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
}

struct BeatProjection {
    let conversionData: [String: String]
    let deeplinksData: [String: String]
    let endpointURL: String?
    let operatingMode: String?
    let fresh: Bool
    let approvalGranted: Bool
    let approvalRejected: Bool
    let approvalLastTime: Date?
}

enum BeatError: Error {
    case noConversion
    case verificationFailed
    case backendDenied
    case payloadCorrupt
    case linkBroken
    case quotaExceeded
    case clockExpired
}

enum BeatOutcome {
    case continueIdle
    case askApproval
    case showWeb
    case showMain
}


protocol VerificationProvider {
    func verifyPublisher() -> AnyPublisher<Bool, BeatError>
}

protocol AttributionRefresher {
    func refresh(deviceID: String) async -> Result<[String: Any], BeatError>
}

protocol EndpointDiscoverer {
    func discover(payload: [String: Any]) async -> Result<String, BeatError>
}

protocol ApprovalCoordinator {
    var statusSubject: CurrentValueSubject<ApprovalStatus, Never> { get }
    func solicit()
    func register()
}

enum ApprovalStatus {
    case pending
    case granted
    case rejected
    case error
}
