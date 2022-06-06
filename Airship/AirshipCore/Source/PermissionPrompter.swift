/* Copyright Airship and Contributors */

import Foundation

typealias PermissionResultReceiver = (Permission, PermissionStatus, PermissionStatus) -> Void

protocol PermissionPrompter {

    func prompt(permission: Permission,
                 enableAirshipUsage: Bool,
                 fallbackSystemSettings: Bool,
                 completionHandler: @escaping (PermissionStatus, PermissionStatus) -> Void)
}

struct AirshipPermissionPrompter: PermissionPrompter {

    private let permissionsManager: PermissionsManager
    private let notificationCenter: NotificationCenter

    init(permissionsManager: PermissionsManager,
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.permissionsManager = permissionsManager
        self.notificationCenter = notificationCenter
    }

    func prompt(permission: Permission,
                 enableAirshipUsage: Bool,
                 fallbackSystemSettings: Bool,
                 completionHandler: @escaping (PermissionStatus, PermissionStatus) -> Void) {


        self.permissionsManager.checkPermissionStatus(permission) { startResult in
            let fallback = permission == .postNotifications &&
            startResult == .denied &&
            fallbackSystemSettings

            if (fallback) {
                self.requestSystemSettingsChange(permission: permission) { endResult in
                    completionHandler(startResult, endResult)
                }
            } else {
                self.permissionsManager.requestPermission(permission,
                                                     enableAirshipUsageOnGrant: enableAirshipUsage) { endResult in
                    completionHandler(startResult, endResult)
                }
            }
        }
    }

    private func requestSystemSettingsChange(permission: Permission, completionHandler: @escaping (PermissionStatus) -> Void) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:]) { _ in

                var observer: Any? = nil
                observer = self.notificationCenter.addObserver(forName: AppStateTracker.didBecomeActiveNotification,
                                               object: nil,
                                               queue: .main) { _ in

                    if let observer = observer {
                        self.notificationCenter.removeObserver(observer)
                    }
                }
            }
        } else {
            AirshipLogger.error("Unable to navigate to system settings.")
            self.permissionsManager.checkPermissionStatus(permission, completionHandler: completionHandler)
        }
    }
}
