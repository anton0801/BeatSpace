import AppsFlyerLib
import Combine
import Foundation


final class AppsFlyerAttributionRefresh: AttributionRefresher {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    func refresh(deviceID: String) async -> Result<[String: Any], BeatError> {
        var components = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(BeatConstants.appReference)")
        components?.queryItems = [
            URLQueryItem(name: "devkey", value: BeatConstants.trackingDevKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = components?.url else {
            return .failure(.payloadCorrupt)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return .failure(.linkBroken)
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(.payloadCorrupt)
            }
            
            return .success(json)
        } catch {
            return .failure(.linkBroken)
        }
    }
}
