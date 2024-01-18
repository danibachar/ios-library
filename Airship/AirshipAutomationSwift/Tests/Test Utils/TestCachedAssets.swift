/* Copyright Airship and Contributors */

import Foundation
import Combine

@testable import AirshipAutomationSwift
@testable import AirshipCore

final class TestCachedAssets: AirshipCachedAssetsProtocol, @unchecked Sendable {

    var cached: [URL] = []

    func cachedURL(remoteURL: URL) -> URL? {
        return isCached(remoteURL: remoteURL) ? remoteURL : nil
    }
    
    func isCached(remoteURL: URL) -> Bool {
        return cached.contains(remoteURL)
    }
}

final actor TestAssetManager: AssetCacheManagerProtocol {
    var cleared: [String] = []
    var onCache: (@Sendable (String, [String]) async throws -> AirshipCachedAssetsProtocol)?

    func setOnCache(_ onCache: @escaping @Sendable (String, [String]) async throws -> AirshipCachedAssetsProtocol) {
        self.onCache = onCache
    }

    func cacheAssets(identifier: String, assets: [String]) async throws -> AirshipCachedAssetsProtocol {
        try await self.onCache!(identifier, assets)
    }
    
    func clearCache(identifier: String) async {
        cleared.append(identifier)
    }

}
