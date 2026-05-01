import Foundation

struct BeatReducer {
    
    static func apply(_ event: BeatEvent, to state: BeatState) -> BeatState {
        var s = state
        
        switch event {
        case .bootInitiated:
            // Reset transient flags при старте
            break
            
        case .attributionCaptured(let data):
            s.conversionData = data
            
        case .deeplinksCaptured(let data):
            s.deeplinksData = data
            
        case .organicProcessingMarked:
            s.organicMarked = true
            
        case .validationPassed:
            s.lastError = nil
            
        case .validationDenied(let reason):
            s.lastError = reason
            s.sequenceTerminated = true
            
        case .endpointResolved(let url):
            s.endpointURL = url
            s.lastError = nil
            
        case .endpointDenied:
            s.lastError = "endpoint denied"
            s.sequenceTerminated = true
            
        case .sequenceFinalized(let url, let mode):
            s.endpointURL = url
            s.operatingMode = mode
            s.fresh = false
            s.locked = true
            s.sequenceTerminated = true
            
        case .approvalRequested:
            break
            
        case .approvalGranted(let at):
            s.approvalGranted = true
            s.approvalRejected = false
            s.approvalLastTime = at
            
        case .approvalRejected(let at):
            s.approvalGranted = false
            s.approvalRejected = true
            s.approvalLastTime = at
            
        case .approvalDeferred(let at):
            s.approvalLastTime = at
            
        case .timeoutTriggered:
            s.sequenceTerminated = true
            s.lastError = "timeout"
            
        case .networkLost:
            s.offline = true
            
        case .networkRestored:
            s.offline = false
        }
        
        return s
    }
    
    static func hydrate(from projection: BeatProjection) -> BeatState {
        var s = BeatState.initial
        
        s.conversionData = projection.conversionData
        s.deeplinksData = projection.deeplinksData
        s.endpointURL = projection.endpointURL
        s.operatingMode = projection.operatingMode
        s.fresh = projection.fresh
        s.approvalGranted = projection.approvalGranted
        s.approvalRejected = projection.approvalRejected
        s.approvalLastTime = projection.approvalLastTime
        
        return s
    }
}
