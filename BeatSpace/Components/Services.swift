import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications
import Combine

final class SupabaseVerification: VerificationProvider {
    
    func verifyPublisher() -> AnyPublisher<Bool, BeatError> {
        return Future<Bool, BeatError> { [weak self] promise in
            promise(.success(true))
        }
        .eraseToAnyPublisher()
    }
}

final class HTTPEndpointDiscovery: EndpointDiscoverer {
    
    private let session: URLSession
    private let pauseSchedule: [Double] = [46.0, 92.0, 184.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func discover(payload: [String: Any]) async -> Result<String, BeatError> {
        guard let endpoint = URL(string: BeatConstants.backendURL) else {
            return .failure(.payloadCorrupt)
        }
        
        var body: [String: Any] = payload
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(BeatConstants.appReference)"
        body["push_token"] = UserDefaults.standard.string(forKey: PantryKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return .failure(.payloadCorrupt)
        }
        request.httpBody = bodyData
        
        var lastError: BeatError = .linkBroken
        
        for (idx, pause) in pauseSchedule.enumerated() {
            let result = await singleAttempt(request)
            
            switch result {
            case .success(let url):
                return .success(url)
            case .failure(let error):
                if case .backendDenied = error {
                    return .failure(.backendDenied)
                }
                
                lastError = error
                
                // Throttling — увеличенный бэкофф
                if case .quotaExceeded = error {
                    let waitTime = pause * Double(idx + 1)
                    try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                    continue
                }
                
                if idx < pauseSchedule.count - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            }
        }
        
        return .failure(lastError)
    }
    
    private func singleAttempt(_ request: URLRequest) async -> Result<String, BeatError> {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                return .failure(.linkBroken)
            }
            
            if http.statusCode == 404 {
                return .failure(.backendDenied)
            }
            
            if http.statusCode == 429 {
                return .failure(.quotaExceeded)
            }
            
            guard (200...299).contains(http.statusCode) else {
                return .failure(.linkBroken)
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(.payloadCorrupt)
            }
            
            guard let ok = json["ok"] as? Bool else {
                return .failure(.payloadCorrupt)
            }
            
            if !ok {
                return .failure(.backendDenied)
            }
            
            guard let url = json["url"] as? String else {
                return .failure(.payloadCorrupt)
            }
            
            return .success(url)
        } catch {
            return .failure(.linkBroken)
        }
    }
}

final class NotificationApprovalCoordinator: ApprovalCoordinator {
    
    let statusSubject = CurrentValueSubject<ApprovalStatus, Never>(.pending)
    
    func solicit() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.statusSubject.send(.error)
                } else if granted {
                    self?.statusSubject.send(.granted)
                } else {
                    self?.statusSubject.send(.rejected)
                }
            }
        }
    }
    
    func register() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
