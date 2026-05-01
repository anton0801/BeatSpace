import Foundation

final class BeatStoreBuilder {
    
    private var pantry: PantryProtocol?
    private var verifier: VerificationProvider?
    private var refresher: AttributionRefresher?
    private var discoverer: EndpointDiscoverer?
    private var approver: ApprovalCoordinator?
    
    @discardableResult
    func with(pantry: PantryProtocol) -> BeatStoreBuilder {
        self.pantry = pantry
        return self
    }
    
    @discardableResult
    func with(verifier: VerificationProvider) -> BeatStoreBuilder {
        self.verifier = verifier
        return self
    }
    
    @discardableResult
    func with(refresher: AttributionRefresher) -> BeatStoreBuilder {
        self.refresher = refresher
        return self
    }
    
    @discardableResult
    func with(discoverer: EndpointDiscoverer) -> BeatStoreBuilder {
        self.discoverer = discoverer
        return self
    }
    
    @discardableResult
    func with(approver: ApprovalCoordinator) -> BeatStoreBuilder {
        self.approver = approver
        return self
    }
    
    func build() -> BeatStore {
        return BeatStore(
            pantry: pantry ?? MaterializedPantry(),
            verifier: verifier ?? SupabaseVerification(),
            refresher: refresher ?? AppsFlyerAttributionRefresh(),
            discoverer: discoverer ?? HTTPEndpointDiscovery(),
            approver: approver ?? NotificationApprovalCoordinator()
        )
    }
    
    /// Default-конфигурация одной строкой
    static func defaultStore() -> BeatStore {
        return BeatStoreBuilder()
            .with(pantry: MaterializedPantry())
            .with(verifier: SupabaseVerification())
            .with(refresher: AppsFlyerAttributionRefresh())
            .with(discoverer: HTTPEndpointDiscovery())
            .with(approver: NotificationApprovalCoordinator())
            .build()
    }
}
