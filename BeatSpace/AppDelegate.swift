import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Mediator — центральный координатор
    private lazy var mediator: AppMediator = {
        let mediator = AppMediator()
        mediator.attributionHook = { [weak self] data in
            self?.relayAttribution(data)
        }
        mediator.deeplinksHook = { [weak self] data in
            self?.relayDeeplinks(data)
        }
        return mediator
    }()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        mediator.bootstrap(messagingDelegate: self, notificationDelegate: self)
        mediator.attachAppsFlyer(delegate: self)
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            mediator.processPushPayload(remote)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        mediator.startTracking()
    }
    
    // MARK: - Broadcasting
    
    private func relayAttribution(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func relayDeeplinks(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

// MARK: - Messaging Delegate (forwards to mediator)

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        mediator.captureToken(messaging: messaging)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        mediator.processPushPayload(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        mediator.processPushPayload(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        mediator.processPushPayload(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        mediator.handleConversionSuccess(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        mediator.handleConversionFailure(error)
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        mediator.handleDeeplinkResolved(result)
    }
}

final class AppMediator: NSObject {
    
    var attributionHook: (([AnyHashable: Any]) -> Void)?
    var deeplinksHook: (([AnyHashable: Any]) -> Void)?
    
    private var attributionBuffer: [AnyHashable: Any] = [:]
    private var deeplinksBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func bootstrap(
        messagingDelegate: MessagingDelegate,
        notificationDelegate: UNUserNotificationCenterDelegate
    ) {
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = messagingDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func attachAppsFlyer(delegate: AppsFlyerLibDelegate & DeepLinkDelegate) {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = BeatConstants.trackingDevKey
        sdk.appleAppID = BeatConstants.appReference
        sdk.delegate = delegate
        sdk.deepLinkDelegate = delegate
        sdk.isDebug = false
    }
    
    func startTracking() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    // MARK: - Token Management
    
    func captureToken(messaging: Messaging) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            
            UserDefaults.standard.set(t, forKey: PantryKey.fcm)
            UserDefaults.standard.set(t, forKey: PantryKey.push)
            UserDefaults(suiteName: BeatConstants.realmSuite)?.set(t, forKey: "shared_fcm")
        }
    }
    
    // MARK: - AppsFlyer Events
    
    func handleConversionSuccess(_ data: [AnyHashable: Any]) {
        attributionBuffer = data
        scheduleFuse()
        
        if !deeplinksBuffer.isEmpty {
            performFuse()
        }
    }
    
    func handleConversionFailure(_ error: Error) {
        let errorData: [AnyHashable: Any] = [
            "error": true,
            "error_desc": error.localizedDescription
        ]
        attributionBuffer = errorData
        scheduleFuse()
        
        if !deeplinksBuffer.isEmpty {
            performFuse()
        }
    }
    
    func handleDeeplinkResolved(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else { return }
        
        guard !UserDefaults.standard.bool(forKey: PantryKey.booted) else { return }
        
        let data = link.clickEvent
        deeplinksBuffer = data
        deeplinksHook?(data)
        fuseTimer?.invalidate()
        
        if !attributionBuffer.isEmpty {
            performFuse()
        }
    }
    
    // MARK: - Push Processing
    
    func processPushPayload(_ payload: [AnyHashable: Any]) {
        guard let url = scanForURL(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: PantryKey.pushURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func scanForURL(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String {
            return direct
        }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String {
            return url
        }
        return nil
    }
    
    // MARK: - Fuse (merge attribution + deeplinks)
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(
            withTimeInterval: 2.5,
            repeats: false
        ) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var fused = attributionBuffer
        
        for (k, v) in deeplinksBuffer {
            let prefixed = "deep_\(k)"
            if fused[prefixed] == nil {
                fused[prefixed] = v
            }
        }
        
        attributionHook?(fused)
    }
}
