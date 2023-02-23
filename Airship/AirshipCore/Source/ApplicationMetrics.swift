/* Copyright Airship and Contributors */

import Foundation

/// The ApplicationMetrics class keeps track of application-related metrics.
@objc(UAApplicationMetrics)
public class ApplicationMetrics: NSObject {
    private static let lastOpenDataKey = "UAApplicationMetricLastOpenDate"
    private static let lastAppVersionKey = "UAApplicationMetricsLastAppVersion"

    private let dataStore: PreferenceDataStore
    private let date: AirshipDate
    private let privacyManager: AirshipPrivacyManager

    private var _isAppVersionUpdated = false

    /**
     * Determines whether the application's short version string has been updated.
     * Only tracked if Feature.inAppAutomation or Feature.analytics are enabled in the privacy manager.
     */
    @objc
    public var isAppVersionUpdated: Bool {
        return _isAppVersionUpdated
    }

    /**
     * The date of the last time the application was active.
     * Only tracked if Feature.inAppAutomation or Feature.analytics are enabled in the privacy manager.
     */
    @objc
    public var lastApplicationOpenDate: Date? {
        return dataStore.object(forKey: ApplicationMetrics.lastOpenDataKey)
            as? Date
    }

    /**
     * The application's current short version string.
     */
    @objc
    public var currentAppVersion: String? {
        return AirshipUtils.bundleShortVersionString()
    }

    @objc
    public init(
        dataStore: PreferenceDataStore,
        privacyManager: AirshipPrivacyManager,
        notificationCenter: NotificationCenter,
        date: AirshipDate
    ) {
        self.dataStore = dataStore
        self.privacyManager = privacyManager
        self.date = date

        super.init()

        updateData()

        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: AppStateTracker.didBecomeActiveNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(updateData),
            name: AirshipPrivacyManager.changeEvent,
            object: nil
        )
    }

    @objc
    public convenience init(
        dataStore: PreferenceDataStore,
        privacyManager: AirshipPrivacyManager
    ) {
        self.init(
            dataStore: dataStore,
            privacyManager: privacyManager,
            notificationCenter: NotificationCenter.default,
            date: AirshipDate()
        )
    }

    @objc
    func applicationDidBecomeActive() {
        if self.privacyManager.isEnabled(.inAppAutomation)
            || self.privacyManager.isEnabled(.analytics)
        {
            self.dataStore.setObject(
                date.now,
                forKey: ApplicationMetrics.lastOpenDataKey
            )
        }
    }

    @objc
    func updateData() {
        if self.privacyManager.isEnabled(.inAppAutomation)
            || self.privacyManager.isEnabled(.analytics)
        {

            guard let currentVersion = self.currentAppVersion else {
                return
            }

            let lastVersion = self.dataStore.string(
                forKey: ApplicationMetrics.lastAppVersionKey
            )

            if lastVersion != nil
                && AirshipUtils.compareVersion(lastVersion!, toVersion: currentVersion)
                    == .orderedAscending
            {
                self._isAppVersionUpdated = true
            }

            self.dataStore.setObject(
                currentVersion,
                forKey: ApplicationMetrics.lastAppVersionKey
            )
        } else {
            self.dataStore.removeObject(
                forKey: ApplicationMetrics.lastOpenDataKey
            )
            self.dataStore.removeObject(
                forKey: ApplicationMetrics.lastAppVersionKey
            )
        }
    }
}
