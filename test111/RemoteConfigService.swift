//
//  RemoteConfigService.swift
//  test111
//
//  Created by Assistant on 16.10.2025.
//

import Foundation

#if canImport(RSRemoteConfig)
import RSRemoteConfig
#endif

final class RemoteConfigService {
    static let shared = RemoteConfigService()
    private init() {}

    // UserDefaults keys
    private let tokenKeyDefaults = "schedule_api_token"
    private let adsEnabledDefaultsKey = "ads_enabled_cached"

    #if canImport(RSRemoteConfig)
    private var client: RemoteConfigClient?
    #endif

    // Public computed accessors for the rest of the app
    var isAdsEnabled: Bool {
        // Default to true if nothing fetched yet
        if UserDefaults.standard.object(forKey: adsEnabledDefaultsKey) == nil { return true }
        return UserDefaults.standard.bool(forKey: adsEnabledDefaultsKey)
    }

    func cachedToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKeyDefaults)
    }

    // MARK: - Startup / Fetch
    func start(appID: String) {
        #if canImport(RSRemoteConfig)
        let configuration = RemoteConfigConfiguration(
            updateBehaviour: .default(timeInterval: 900) // 15 minutes
        )
        let client = RemoteConfigClient(appID: appID, configuration: configuration)
        self.client = client

        // Значения подтянутся и будут обновляться в фоне согласно стратегии updateBehaviour
        #else
        // If RSRemoteConfig SDK is not yet available, do nothing. App will use defaults/cached values.
        #endif
    }

    // Принудительное обновление значений и возврат результата для UI
    func refreshNow(completion: @escaping (_ adsEnabled: Bool, _ tokenExists: Bool) -> Void) {
        #if canImport(RSRemoteConfig)
        guard let client = self.client else {
            let ads = self.isAdsEnabled
            let tokenExists = (self.cachedToken()?.isEmpty == false)
            completion(ads, tokenExists)
            return
        }
        #if compiler(>=5.5) && canImport(_Concurrency)
        if #available(iOS 13.0, *) {
            Task.detached(priority: .background) { [adsKey = self.adsEnabledDefaultsKey, tokenKey = self.tokenKeyDefaults] in
                let remoteConfig = await client.remoteConfig()
                let ads = remoteConfig.bool(forKey: "Advertisement") ?? true
                UserDefaults.standard.set(ads, forKey: adsKey)
                if let token = remoteConfig.string(forKey: "ScheduleServiceAccessToken"), !token.isEmpty {
                    UserDefaults.standard.set(token, forKey: tokenKey)
                }
                if let scheduleServer = remoteConfig.string(forKey: "ScheduleServer"), !scheduleServer.isEmpty {
                    UserDefaults.standard.set(scheduleServer, forKey: "schedule_server_url")
                }
                let tokenExists = (UserDefaults.standard.string(forKey: tokenKey)?.isEmpty == false)
                DispatchQueue.main.async {
                    completion(ads, tokenExists)
                }
            }
            return
        }
        #endif
        // Без Concurrency: возвращаем текущее закешированное состояние
        let ads = self.isAdsEnabled
        let tokenExists = (self.cachedToken()?.isEmpty == false)
        completion(ads, tokenExists)
        #else
        // SDK недоступен: возвращаем текущее состояние
        let ads = self.isAdsEnabled
        let tokenExists = (self.cachedToken()?.isEmpty == false)
        completion(ads, tokenExists)
        #endif
    }
}


