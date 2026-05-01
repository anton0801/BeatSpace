import Foundation


struct PantryKey {
    static let conversion = "bsp_conv"
    static let deeplinks = "bsp_deep"
    static let endpoint = "bsp_endp"
    static let mode = "bsp_mode"
    static let booted = "bsp_booted"
    static let approvalYes = "bsp_apr_yes"
    static let approvalNo = "bsp_apr_no"
    static let approvalAt = "bsp_apr_at"
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}


protocol PantryProtocol {
    func projectAttribution(_ data: [String: String])
    func projectDeeplinks(_ data: [String: String])
    func projectEndpoint(url: String, mode: String)
    func projectApproval(granted: Bool, rejected: Bool, lastTime: Date?)
    func markBooted()
    func loadProjection() -> BeatProjection
}

final class MaterializedPantry: PantryProtocol {
    
    private let realmStore: UserDefaults
    private let standardStore: UserDefaults
    
    init() {
        self.realmStore = UserDefaults(suiteName: BeatConstants.realmSuite)!
        self.standardStore = UserDefaults.standard
    }
    
    // MARK: - Project (write current state)
    
    func projectAttribution(_ data: [String: String]) {
        guard let serialized = serialize(data) else { return }
        realmStore.set(serialized, forKey: PantryKey.conversion)
    }
    
    func projectDeeplinks(_ data: [String: String]) {
        guard let serialized = serialize(data) else { return }
        let veiled = veil(serialized)
        realmStore.set(veiled, forKey: PantryKey.deeplinks)
    }
    
    func projectEndpoint(url: String, mode: String) {
        realmStore.set(url, forKey: PantryKey.endpoint)
        standardStore.set(url, forKey: PantryKey.endpoint)
        realmStore.set(mode, forKey: PantryKey.mode)
    }
    
    func projectApproval(granted: Bool, rejected: Bool, lastTime: Date?) {
        realmStore.set(granted, forKey: PantryKey.approvalYes)
        realmStore.set(rejected, forKey: PantryKey.approvalNo)
        
        if let time = lastTime {
            let ms = time.timeIntervalSince1970 * 1000
            realmStore.set(ms, forKey: PantryKey.approvalAt)
        }
    }
    
    func markBooted() {
        realmStore.set(true, forKey: PantryKey.booted)
    }
    
    // MARK: - Load Projection
    
    func loadProjection() -> BeatProjection {
        let convStr = realmStore.string(forKey: PantryKey.conversion) ?? ""
        let conversion = deserialize(convStr) ?? [:]
        
        let deepVeiled = realmStore.string(forKey: PantryKey.deeplinks) ?? ""
        let deepStr = unveil(deepVeiled) ?? ""
        let deeplinks = deserialize(deepStr) ?? [:]
        
        let endpoint = realmStore.string(forKey: PantryKey.endpoint)
        let mode = realmStore.string(forKey: PantryKey.mode)
        let booted = realmStore.bool(forKey: PantryKey.booted)
        
        let approvalYes = realmStore.bool(forKey: PantryKey.approvalYes)
        let approvalNo = realmStore.bool(forKey: PantryKey.approvalNo)
        let approvalMs = realmStore.double(forKey: PantryKey.approvalAt)
        let approvalTime = approvalMs > 0
            ? Date(timeIntervalSince1970: approvalMs / 1000)
            : nil
        
        return BeatProjection(
            conversionData: conversion,
            deeplinksData: deeplinks,
            endpointURL: endpoint,
            operatingMode: mode,
            fresh: !booted,
            approvalGranted: approvalYes,
            approvalRejected: approvalNo,
            approvalLastTime: approvalTime
        )
    }
    
    // MARK: - Serialization
    
    private func serialize(_ dict: [String: String]) -> String? {
        let anyDict = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: anyDict),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func deserialize(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let anyDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return anyDict.mapValues { "\($0)" }
    }
    
    // MARK: - Veiling (обфускация deeplinks)
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "=", with: "#")
            .replacingOccurrences(of: "+", with: ",")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "#", with: "=")
            .replacingOccurrences(of: ",", with: "+")
        
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
}
