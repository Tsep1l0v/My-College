//
//  AdManager.swift
//  test111
//
//  Created by Assistant on 16.10.2025.
//

import Foundation

final class AdManager {
    static let shared = AdManager()
    private init() {}

    func shouldShowAds() -> Bool {
        return RemoteConfigService.shared.isAdsEnabled
    }
}







