/* Copyright Airship and Contributors */

import Combine
import Foundation
import SwiftUI

@available(iOS 13.0.0, tvOS 13.0, *)
public struct ImageLoader {
    private static let retryDelay = 10
    private static let retries = 10

    private let imageProvider: ImageProvider?

    public init(imageProvider: ImageProvider? = nil) {
        self.imageProvider = imageProvider
    }

    func load(url: String) -> AnyPublisher<AirshipImageData, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: AirshipErrors.error("failed to fetch message"))
                .eraseToAnyPublisher()
        }

        return Deferred { () -> AnyPublisher<AirshipImageData, Error> in
            guard let imageData = self.imageProvider?.get(url: url) else {
                return fetchImage(url: url)
            }
            return Just(imageData)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .subscribe(on: DispatchQueue.global(qos: .userInteractive))
        .eraseToAnyPublisher()
    }

    private func fetchImage(url: URL) -> AnyPublisher<AirshipImageData, Error> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { AirshipErrors.error("URL error \($0)") }
            .map { response -> AnyPublisher<AirshipImageData, Error> in
                guard let httpResponse = response.response as? HTTPURLResponse,
                    httpResponse.statusCode == 200
                else {
                    return Fail(
                        error: AirshipErrors.error("failed to fetch message")
                    )
                    .eraseToAnyPublisher()
                }

                do {
                    let imageData = try AirshipImageData(data: response.data)
                    return Just(imageData)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .catch { error in
                return Fail(
                    error: AirshipErrors.error("failed to fetch message")
                )
                .delay(
                    for: .seconds(ImageLoader.retryDelay),
                    scheduler: DispatchQueue.global()
                )
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .retry(ImageLoader.retries)
            .eraseToAnyPublisher()
    }
}
