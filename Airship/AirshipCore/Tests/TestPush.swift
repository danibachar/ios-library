/* Copyright Airship and Contributors */

@testable
import AirshipCore

import Foundation
import Combine

final class TestPush: NSObject, InternalPushProtocol, PushProtocol, AirshipComponent, @unchecked Sendable {

    let notificationStatusSubject: PassthroughSubject<AirshipNotificationStatus, Never> = PassthroughSubject()

    var notificationStatusPublisher: AnyPublisher<AirshipNotificationStatus, Never> {
        notificationStatusSubject.removeDuplicates().eraseToAnyPublisher()
    }

    var notificationStatus: AirshipNotificationStatus = AirshipNotificationStatus(
        isUserNotificationsEnabled: false,
        areNotificationsAllowed: false,
        isPushPrivacyFeatureEnabled: false,
        isPushTokenRegistered: false
    )


    var isPushNotificationsOptedIn: Bool = false

    var backgroundPushNotificationsEnabled: Bool = false

    var userPushNotificationsEnabled: Bool = false

    var extendedPushNotificationPermissionEnabled: Bool = false

    var requestExplicitPermissionWhenEphemeral: Bool = false

    var notificationOptions: UANotificationOptions  = []

    var customCategories: Set<UNNotificationCategory> = Set()

    var accengageCategories: Set<UNNotificationCategory> = Set()

    var requireAuthorizationForDefaultCategories: Bool = false

    var pushNotificationDelegate: PushNotificationDelegate?

    var registrationDelegate: RegistrationDelegate?

    var launchNotificationResponse: UNNotificationResponse?

    var authorizedNotificationSettings: UAAuthorizedNotificationSettings = []

    var authorizationStatus: UAAuthorizationStatus = .notDetermined

    var userPromptedForNotifications: Bool = false

    var defaultPresentationOptions: UNNotificationPresentationOptions = []

    var badgeNumber: Int = 0

    var deviceToken: String?
    var updateAuthorizedNotificationTypesCalled = false
    var registrationError: Error?
    var didReceiveRemoteNotificationCallback:
        (
            (
                [AnyHashable: Any], Bool,
                @escaping (UIBackgroundFetchResult) -> Void
            ) ->
                Void
        )?
    var combinedCategories: Set<UNNotificationCategory> = Set()

    func dispatchUpdateAuthorizedNotificationTypes() {
        self.updateAuthorizedNotificationTypesCalled = true
    }

    func didRegisterForRemoteNotifications(_ deviceToken: Data) {
        self.deviceToken = String(data: deviceToken, encoding: .utf8)
    }

    func didFailToRegisterForRemoteNotifications(_ error: Error) {
        self.registrationError = error
    }

    func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any],
        isForeground: Bool,
        completionHandler: @escaping (Any) -> Void
    ) {
        self.didReceiveRemoteNotificationCallback!(
            userInfo,
            isForeground,
            completionHandler
        )
    }


    func presentationOptionsForNotification(_ notification: UNNotification, completionHandler: (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }


    func didReceiveNotificationResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        assertionFailure("Unable to create UNNotificationResponse in tests.")
    }
}
